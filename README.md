# platesOfDoom (Work in Progress)

An SB Script + game, combined.

A rework of an old script builder script I made.

## Getting Started

You will need [Rokit](https://github.com/rojo-rbx/rokit) in order to install all the requires tools (or manually install them, check [rokit.toml](https://github.com/ewd3v/platesOfDoom/blob/main/rokit.toml)).

After installing Rokit, simply run to install all the required tools:

```bash
rokit install
```

## Building

Many of the scripts exists as VSCode tasks (check [.vscode/tasks.json](https://github.com/ewd3v/platesOfDoom/blob/main/.vscode/tasks.json)).

### Build

Builds the client and server scripts (what's required for the sb scripts).

### Build .rbxlx

Builds the place file with rojo (outputs to platesOfDoom.rbxlx).

### Build Game

Runs first the "Build" task then the "Build .rbxlx" task, should be ran when building the place file from scratch.

## Testing

Simply build the game file with the "Build Game" task, open in studio, then serve the place file with rojo:

```bash
rojo serve
```

Then the final step is simply to just connect in studio with the rojo plugin.

When you want to update and test new changes run the "Build" task.
