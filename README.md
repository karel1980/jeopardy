# Jeopardy

This software will allow you to become the host of a jeopardy game.

- IMPROVEMENT: always disable buzzers / stop waiting music when navigating away from question
- IMPROVEMENT: when third team answered wrong, don't re-enable buzzers
- IMPROVEMENT: lock out teams that already answered from next buzzer
- TODO: more sound effects for buzzers (fixed sound per team or random collection)
- TODO: sound effect for correct and wrong answers
- TODO: lock out teams that buzzed too early for .5 seconds (+ sound effect?)

- TODO: fallback mode in case buzzers don't work?
- TODO: implement 'double jeopardy' questions? (i.e. only current contestant can play, wagers some amount, double or nothing)

- TODO: prepare quiz questions (in progress - see google drive)
- TODO: do a dry run (family game questions)

- TBD: on draws, either detect who reached score first OR use tie breaker?

- WONTDO: final jeopardy (one question, everyone writes answer down beforehand)

## Preparation

Prepare your questions and team names in the file named `jeopardy.json`.
TODO: create a nice gui to edit these

## Running the game

Run the Godot 'intro' scene to get started.
Be aware that at this point, game state is not persisted, so if the game crashes or is terminated, scores will be reset.
