import "graphics" for Color, Canvas, ImageData
import "dome" for Window, Process
import "math" for Vec, M
import "input" for Keyboard, Mouse
import "./core/keys" for InputGroup

import "./core/entity" for Player, Door, SecretDoor
import "./core/context" for World
import "./core/map" for TileMap, Tile
import "./core/texture" for Texture
import "./core/renderer" for Renderer

import "./sprites" for Pillar, Person

var SPEED = 0.001
var Interact = InputGroup.new([ Mouse["left"], Keyboard["e"], Keyboard["space"] ], SPEED)
Interact.repeating = false
var Forward = InputGroup.new(Keyboard["w"], SPEED)
var Back = InputGroup.new(Keyboard["s"], -SPEED)
var LeftBtn = InputGroup.new(Keyboard["a"], -SPEED)
var RightBtn = InputGroup.new(Keyboard["d"], SPEED)
var StrafeLeftBtn = InputGroup.new(Keyboard["left"], -1)
var StrafeRightBtn = InputGroup.new(Keyboard["right"], 1)

var MAP_WIDTH = 30
var MAP_HEIGHT = 30
var MAP = [
    2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
    2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
    2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
    2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
    2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
    2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
    2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
    6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
    2,0,0,0,0,0,0,0,0,0,0,2,1,1,1,1,1,2,0,0,0,0,0,0,0,0,0,0,0,2,
    2,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,2,
    2,0,2,0,0,0,0,0,0,0,0,7,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,2,
    2,0,5,0,0,0,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,2,
    2,0,2,0,0,0,0,0,0,0,0,2,1,1,0,1,1,2,0,0,0,0,0,0,0,0,0,0,0,2,
    2,0,2,5,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
    2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
    2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
    2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
    2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
    2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
    2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
    2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
    2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
    2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
    2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
    2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
    2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
    2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
    2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
    2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
    2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
]



class Game {
  static init() {
    var SCALE = 3
    Canvas.resize(320, 200)
    Window.resize(SCALE*Canvas.width, SCALE*Canvas.height)

    Mouse.relative = true
    Mouse.hidden = true

    __player = Player.new(Vec.new(7, 11), 180)
    __sprites = [
      //Pillar.new(Vec.new(8, 13)),
      Pillar.new(Vec.new(9, 15)),
      Person.new(Vec.new(8, 13))
    ]
    __doors = []
    __map = TileMap.new(MAP_WIDTH, MAP_HEIGHT)
    for (y in 0...MAP_HEIGHT) {
      for (x in 0...MAP_WIDTH) {
        var type = MAP[y * MAP_WIDTH + x]
        if (type == 7) {
          __map.set(x, y, Tile.new(1, {
            "solid": true,
            "door": false,
            "thin": -0.25
          }))
        } else {
          var door
          if (type == 5) {
            door = Door.new(Vec.new(x, y))
            __doors.add(door)
          }
          __map.set(x, y, Tile.new(type, {
            "solid": type != 0,
            "door": door,
            "thin": null
          }))
        }
      }
    }
    __camera = __player.dir.perp
    __angle = 0

    __world = World.new()
    __world.entities = __sprites
    __world.doors = __doors
    __world.player = __player
    __world.map = __map
    __textures = []
    __world.textures = __textures
    __world.floorTexture = Texture.importImg("res/floor.png")
    // __world.ceilingTexture = Texture.importImg("res/ceil.png")
    __renderer = Renderer.init(__world, 320, 200)

    // Map data
    // - Map arrangement
    // - Textures for map

    // Prepare textures
    for (i in 1..4) {
      __textures.add(Texture.importImg("res/wall%(i).png"))
    }
    __textures.add(Texture.importImg("res/door.png"))
  }

  static update() {
    if (Keyboard.isKeyDown("escape")) {
      Process.exit()
    }

    var angle = __player.angle
    angle = angle + M.mid(-2, Mouse.x / 2, 2)
    if (StrafeLeftBtn.down) {
      angle = angle + StrafeLeftBtn.action
    }
    if (StrafeRightBtn.down) {
      angle = angle + StrafeRightBtn.action
    }
    __player.angle = angle

    __camera.x = -__player.dir.y
    __camera.y = __player.dir.x

    var vel = __player.vel
    vel.x = 0
    vel.y = 0

    if (RightBtn.down) {
      vel = vel + __camera
    }
    if (LeftBtn.down) {
      vel = vel - __camera
    }
    if (Forward.down) {
      vel = vel + __player.dir
    }
    if (Back.down) {
      vel = vel - __player.dir
    }
    __player.vel = vel

    __world.update()

    if (Interact.firing) {
      var targetPos = __player.getTarget(__world)
      var diff = targetPos - __player.pos
      var dist = diff.length
      var targetSprite = __world.getTargetSprite(__player.pos, __player.dir, dist)

      if (targetSprite) {
        // DESTROY IT
        __world.destroySprite(targetSprite)
      } else {
        var door = __world.getDoorAt(targetPos)
        if (door != null && dist < 2.75) {
          door.open()
        }
      }
    }

    __renderer.update()
  }

  static draw(alpha) {
    __renderer.draw(alpha)

    var centerX = Canvas.width / 2
    var centerY = Canvas.height / 2

    Canvas.line(centerX - 4, centerY, centerX + 4, centerY, Color.green, 1)
    Canvas.line(centerX, centerY - 4, centerX, centerY + 4, Color.green, 1)

    //ms = (end - start)
    //ms = ms / counter
    Canvas.print(__angle, 0, 0, Color.white)
  }
}
