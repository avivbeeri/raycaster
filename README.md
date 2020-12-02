# Raycaster Example Engine

This code example provides everything you need to make a Wolfenstein 3D-style game using [DOME](https://domeengine.com).


## Getting started is easy:

1) Install DOME, following the [installation guide].
2) Clone this repository and navigate to the correct folder.
3) Run DOME, using the `main.wren` file as an entry point.

## Codebase Structure

Here is a rough expanation of the files in this example:

```
+ fps-example/
+-- main.wren - Game entry point, Sets up the World and passes input to the Player entity
+-- sprites.wren - Defines the visible Sprites in the world.
+-- core
    +-- context.wren    - This represents the World context and provides useful utilities to interrogate the world
    +-- door.wren       - Special entities representing doors on the map
    +-- entity.wren     - Code for core entities, the Player and base Sprites
    +-- keys.wren       - Input handling library
    +-- map.wren        - Tilemap library
    +-- renderer.wren   - Given a World context, this will render it using a Raycasted 3D view.
    +-- texture.wren    - A special ImageData handling library which loads textures into memory for faster access.
+-- res
    +-- All texture graphics
        You can put other resources for your game here (music and level data)
```

In general, it is not recommended to modify files in the `./core` folder unless you know what you are doing.
You can easily add game logic using the `main` game loop, individual `sprites` and finally adjustments to the World `context`.

