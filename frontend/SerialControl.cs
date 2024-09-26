using Godot;
using System;
using System.IO;
using System.IO.Ports;
using System.Text;
using System.Threading;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Text.Json;

public partial class SerialControl : Node
{
	private SerialPort port;
	private ConcurrentQueue<string> messageQueue = new ConcurrentQueue<string>();
	private volatile bool isRunning = false;
	private Thread readThread;
	private Int64 nextPortConnectionAttempt = 0;
	private Int64 receivedCount = 0;
	private Int64 errorCount = 0;
	private String deviceId = "4F21AFA545C91";

	[Signal]
	public delegate void SerialReceivedEventHandler(string line);

	public override void _Ready() { StartSerialConnection(); }
	private bool IsJson(string input)
	{
		input = input.Trim();
		return (input.StartsWith("{") && input.EndsWith("}")) || (input.StartsWith("[") && input.EndsWith("]"));
	}
	public override void _Process(double delta)
	{
		while (messageQueue.TryDequeue(out string message)) {
			EmitSignal(SignalName.SerialReceived, message);
		}

		if (port == null || !port.IsOpen) {
			Int64 now = DateTimeOffset.Now.ToUnixTimeMilliseconds();
			if (now > nextPortConnectionAttempt) {
				StartSerialConnection();
			}
		}
	}

	private void StartSerialConnection()
	{
		if (isRunning) {
			StopSerialConnection();
		}

		port = TryToOpenSerialPort();
		if (port != null) {
			isRunning = true;
			readThread = new Thread(ReadSerialData);
			readThread.Start();
			GD.Print("Serial connection started");
		} else {
			GD.Print("Could not open serial port. Next connection attempt in 3 seconds");
			nextPortConnectionAttempt = DateTimeOffset.Now.ToUnixTimeMilliseconds() + 3000;
		}
	}

	private void StopSerialConnection()
	{
		isRunning = false;
		if (readThread != null && readThread.IsAlive) {
			readThread.Join(1000); // Wait up to 1 second for the thread to finish
		}
		if (port != null && port.IsOpen) {
			port.Close();
		}
		port = null;
		GD.Print("Serial connection stopped");
	}

	private void ReadSerialData()
	{
		StringBuilder messageBuilder = new StringBuilder();

		while (isRunning && port != null && port.IsOpen) {
			try {
				int bytesToRead = port.BytesToRead;
				if (bytesToRead > 0) {
					byte[] buffer = new byte[bytesToRead];
					int bytesRead = port.Read(buffer, 0, bytesToRead);
					string data = Encoding.ASCII.GetString(buffer, 0, bytesRead);
					messageBuilder.Append(data);

					int newlineIndex;
					while ((newlineIndex = messageBuilder.ToString().IndexOf('\n')) != -1) {
						string line = messageBuilder.ToString(0, newlineIndex).Trim();
						messageBuilder.Remove(0, newlineIndex + 1);

						if (IsJson(line)) {
							messageQueue.Enqueue(line);
							receivedCount++;
						} else {
							GD.Print($"Controller LOG: \t {line}");
						}
					}
				} else {
					Thread.Sleep(10); // Short sleep to prevent busy-waiting
				}
			} catch (Exception ex) {
				GD.Print($"Error reading from serial port: {ex.Message}");
				errorCount++;
				Thread.Sleep(1000); // Wait a second before trying again
			}
		}
		GD.Print("ReadSerialData thread exiting");
	}

	public void SendLine(string json)
	{
		if (port != null && port.IsOpen) {
			try {
				port.WriteLine(json);
				GD.Print($"Sent json message to serial: {json}");
			} catch (Exception ex) {
				GD.Print($"Failed to send message: {ex.Message}");
				errorCount++;
			}
		} else {
			GD.Print($"SerialPort not connected, so not sending json message: {json}");
		}
	}

	public void SendEnableDisableMessage(int[] enable, int[] disable)
	{
		Dictionary<string, int[]> msg = new Dictionary<string, int[]> { { "enable", enable }, { "disable", disable } };
		string json = JsonSerializer.Serialize(msg);
		SendLine(json);
	}

	private SerialPort TryToOpenSerialPort()
	{
		string[] portNames = SerialPort.GetPortNames();
		foreach (string portName in portNames) {
			if (portName == $"/dev/cu.usbmodem{deviceId}") {
				try {
					GD.Print($"Selecting port {portName}");
					SerialPort newPort = new SerialPort(portName, 115200, Parity.None, 8, StopBits.One);
					newPort.ReadTimeout = 500;          // Set a timeout for reading
					newPort.WriteTimeout = 500;         // Set a timeout for writing
					newPort.Handshake = Handshake.None; // Disable handshaking
					newPort.DtrEnable = true;           // Data Terminal Ready
					newPort.RtsEnable = true;           // Request To Send
					newPort.Open();
					return newPort;
				} catch (Exception ex) {
					GD.Print($"Failed to open port {portName}: {ex.Message}");
				}
			}
		}
		return null;
	}

	public override void _ExitTree()
	{
		StopSerialConnection();
		base._ExitTree();
	}

	// These methods can be connected to buttons in the Godot editor
	private void OnFakeSerialEventPressed()
	{
		GD.Print("Emitting fake serial signal");
		messageQueue.Enqueue("{\"buzzer\": 1}");
	}

	private void OnButtonPressed()
	{
		GD.Print("Reconnecting serial");
		StartSerialConnection();
	}

	private void OnButton2Pressed() { SendEnableDisableMessage(new int[] { 0, 1 }, new int[] { 2, 3 }); }
}
