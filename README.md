# Jeopardy

This software will allow you to become the host of a jeopardy game.

What you'll need: 

- a laptop or computer. Ideally with a second screen
- questions (some examples are provided, but that's mostly for documenting the file format)
- hardware buttons (This project does not use off the shelf buzzers, you will need to build them yourself, build and flash firmware to microcontrollers, etc.)

## Getting familiar with the GUI

- Run `./yaml2json jeopardy-example-questions.yaml > jeopardy.json`
- Run the `frontend` project using the [https://godotengine.org/download/macos/](Godot Engine - .NET edition))
- Play around with the GUI until you're comfortable with it. If you don't have the hardware buzzers at this time you can press 'a','b','c','d' on the keyboard to simulate them.

## Preparing

- Way beforehand:
  - Create the hardware buzzers
  - Create questions
- Last minute:
  - Create teams, set up the team names in jeopardy.json

## Ideas / poor man's issue tracker

- TODO: add photos of buzzers

- TODO: Send additional info about game state to receiver (selected team name, 'buzzers enabled')
- Bugfix: pressing multiple times too early extends your lockout period

- TODO: Improvement: when last team answered wrong, don't re-enable buzzers
- TODO: Allow managing and selecting quiz questions using GUI

- WONTDO: implement 'double jeopardy' questions. (i.e. only current contestant can play, wagers some amount, double or nothing)
- WONTDO: final jeopardy (one question, everyone writes answer down beforehand)

