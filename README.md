# Jeopardy

This software will allow you to become the host of a jeopardy game.

- TODO: fix team names in scoreboard (they're not set correctly)
- TODO: add 'final' screen (show final winner)
- TODO: show answer on player screen
- TODO: show categories on host screen
- TODO: add more stuff to state? e.g. selected question, current team, categories revealed, ...
- TODO: clearer visual indication when buzzers are enabled
- TODO: improve host screen design: show question board as a standalone screen/popover

- TODO: implement 'double jeopardy' questions? (i.e. only current contestant can play, wagers some amount, double or nothing)

- TODO: prepare quiz questions
- TODO: do a dry run (family game questions)

- TBD: on draws, either detect who reached score first OR use tie breaker?
- TBD: should we show answer to players or just read it? (on TV they didn't show answers)
- TBD: should we even do buzzer lockout?

- WONTDO: final jeopardy (one question, everyone writes answer down beforehand)

## Preparation

Prepare your questions and team names in the file named `jeopardy.json`.
TODO: create a nice gui to edit these

## Running the game

Run the Godot 'intro' scene to get started.
Be aware that at this point, game state is not persisted, so if the game crashes or is terminated, scores will be reset.
