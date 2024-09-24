using Godot;
using System;
using System.IO;
using System.IO.Ports;
using System.Text.RegularExpressions;
using System.Collections.Generic;
using System.Text.Json;


public partial class SerialControl : Node2D
{
	// Use other usbmodem device when combining USB keyboard and serial...
	SerialPort port = null;
	Int64 nextPortConnectionAttempt = 0;
	Int64 receivedCount = 0;
	Int64 errorCount = 0;

	[Signal]
	public delegate void SerialReceivedEventHandler(string line);

	public override void _Ready()
	{
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
		if (port == null)
		{
			Int64 now = DateTimeOffset.Now.ToUnixTimeMilliseconds();
			if (now > nextPortConnectionAttempt) {
				port = tryToOpenSerialPort();
				if (port == null) {
					GD.Print("Could not open serial port. Next connection attempt in 3 seconds");
					nextPortConnectionAttempt = now + 3000;
				} else {
					GD.Print("Port opened");
					errorCount = 0;
					
					// TODO: observing port like this doesn't work well (wrong thread?)
					//port.DataReceived += SerialPort_DataReceived;
					port.ErrorReceived += SerialPort_ErrorReceived;
				}
				return;
			}
		} else {
			if (!port.IsOpen || errorCount > 0) {
				GD.Print("Clearing port, will reconnect automatically");
				port = null;
			} else {
				if (port.BytesToRead > 0) {
					readFromPort();
				}
			}
		}
	}
	
	private void readFromPort()
	{
		try
		{
			receivedCount += 1;
			string serData = port.ReadExisting();
			EmitSignal(SignalName.SerialReceived);
		} catch (IOException ex) {
			// TODO: should we try to close() the port?
			GD.Print("Could not read from serial port. Will attempt to reopen in 3 seconds");
			Int64 now = DateTimeOffset.Now.ToUnixTimeMilliseconds();
			nextPortConnectionAttempt = now + 3000;
			port = null;
		}
	}
	
	void sendLine(string json) {
		if (port != null) {
			GD.Print("Sending json message to serial " + json);
			port.WriteLine(json);			
		} else {
			GD.Print("SerialPort not connected, so not sending json message " + json);
		}
	}
	
	void _on_fake_serial_event_pressed() {
		GD.Print("emitting signal");
		EmitSignal(SignalName.SerialReceived, "{\"buzzer\": 1}");
	}
	
	void sendEnableDisableMessage(int[] enable, int[] disable) {
		Dictionary<String, int[]> msg = new Dictionary<string, int[]>
		{
			{ "enable", enable },
			{ "disable", disable }
		};
		String json = JsonSerializer.Serialize(msg);
		sendLine(json);
	}
	
	private void _on_button_pressed()
	{
		GD.Print("raising error count, this will reconnect serial");
		errorCount += 1;
	}

	private void _on_button2_pressed()
	{
		sendEnableDisableMessage(new int[] { 0, 1 }, new int[] { 2, 3 });
	}

	private void SerialPort_ErrorReceived(object sender, SerialErrorReceivedEventArgs e)
	{
		errorCount += 1;
	}
	
	public SerialPort tryToOpenSerialPort() {
		string[] portNames = SerialPort.GetPortNames();
		string usbPortNamePattern = @"^/dev/cu\.usbmodem.*$";

		foreach (string portName in portNames) {
			if (!Regex.IsMatch(portName, usbPortNamePattern)) {
				continue;
			}
			try {
				GD.Print("Selecting port " + portName);
				port = new SerialPort(portName, 115200, Parity.None, 8, StopBits.One);
				port.Open();
				return port;
			} catch (IOException ex) {
				// TODO: do we ever get IOException here?
				// That's ok, we'll just try the next one
				port = null;
			} catch (UnauthorizedAccessException ex) {
				// That's ok, we'll just try the next one
				port = null;
			}
		}
		return null;
	}
}
