# Game show buzzers

Concept:

There is one 'buzzer' per team and one 'receiver' for the game show host

The buzzers send button pressed events to the receiver via ESP NOW. Each buzzer's firmware should be flashed with its own unique player id.

The receiver communicates with the game show host's laptop or pc by presenting it as a keyboard.
There are 2 options: BLE keyboard or USB keyboard. For USB keyboard your esp32 must be usb hid capable (e.g. an ESP32-S2 or ESP32-S3).