# Game show buzzers

Use ESP-NOW to communicate with each other.

There will be 4 ESP32 devices: 1 is the receiver, the 3 others are the buzzers.

The receiver has 2 responsibilities:

- receive buzzer signal
- present itself as a BLE keyboard, and emit a keypress ('a', 'b' or 'c') depending on the sender.

Hardware preparation:

- flash one esp32 with receiver sketch. 
- flash remaining esp32s with the buzzer sketch. Make sure to change the 'playerId' variable for each esp32 (0, 1, 2, ...)

Turn on all devices, and on the host laptop, connect to the 'ESP32 Keyboard' bluetooth device.
Open a text editor on the host laptop and start smashing buttons. Each button should produce a unique keypress (a,b,c,...)

