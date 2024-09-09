# Jeopardy

This software will allow you to become the host of a jeopardy game.

- TODO: fallback mode in case buzzers don't work?
- TODO: lock out teams that buzzed too early for .5 seconds
- TODO: clearer visual indication when buzzers are enabled
- TODO: suspenseful waiting music while buzzers are open

- TODO: implement 'double jeopardy' questions? (i.e. only current contestant can play, wagers some amount, double or nothing)

- TODO: prepare quiz questions
- TODO: do a dry run (family game questions)

- TBD: on draws, either detect who reached score first OR use tie breaker?

- WONTDO: final jeopardy (one question, everyone writes answer down beforehand)

## Preparation

Prepare your questions and team names in the file named `jeopardy.json`.
TODO: create a nice gui to edit these

## Running the game

Run the Godot 'intro' scene to get started.
Be aware that at this point, game state is not persisted, so if the game crashes or is terminated, scores will be reset.
