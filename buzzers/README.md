# Game show buzzers

Concept:

There is one 'buzzer' per team and one 'receiver' for the game show host

The buzzers send button pressed events to the receiver via ESP NOW. Each buzzer's firmware should be flashed with its own unique player id.

The receiver communicates with the game show host's laptop or pc by presenting it as a keyboard.

## Communication protocol:

### Communication between buzzers and receiver is done through JSON documents.

The buzzers send json identifying which button was pressed.
This message is broadcast over ESPNOW (although unicast is also an option)

```{"buzzer": n }```

The receiver sends json to enable/disable buttons (this can be used for enabling a led built into the buzzer).
This message is broadcast over ESPNOW

```{"enable": [1,2], "disable": [0] }```

### Communication between receiver and host laptop:

Communication between receiver and host laptop is done via Serial, and uses the same json structures that are sent between receiver and buzzers.

The receiver's main job is to forward JSON from Serial to ESPNOW and from ESPNOW to Serial.

## Buzzer Implementations

### jeopardy-buzzer

Buzzer implementation targeting an ESP32 dev board

## Receiver implementations

### jeopardy-receiver-keyboard-old

Early implementation which sends buzzer events as keyboard keypresses.
This was abandoned because we wanted to have communication in the other direction as well. (I suppose it's still possible, but I don't know anough about USB HID yet)

### jeopardy-receiver-serial

An arduino project intended for the (https://fri3dcamp.github.io/badge_2024/en/)[Fri3dcamp 2024 badge]

See [https://fri3dcamp.github.io/badge_2024/en/arduino/](here for more information)

### jeopardy-receiver-platformio

A platformio project intended for the (https://fri3dcamp.github.io/badge_2024/en/)[Fri3dcamp 2024 badge]
Features all the basics + feedback on a tft screen.

See [https://fri3dcamp.github.io/badge_2024/en/platformio](here for more information)

## Other implementations

Another implementation can be found [https://github.com/jellevictoor/game_buzzers](here).
This implementation is full featured, and performs auto-discovery. This means all buzzers can be flashed with the same firmware.  There is no need to recompile with a different team number - the number gets assigned automatically.
