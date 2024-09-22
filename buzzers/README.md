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

The receiver's only job is to forward JSON from Serial to ESPNOW and from ESPNOW to Serial.

