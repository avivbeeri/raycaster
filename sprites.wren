import "core/texture" for Texture
import "core/entity" for Entity, Sprite, Player, DirectionalSprite

import "math" for M, Vec

class Person is DirectionalSprite {
  construct new(pos) {
    super(pos, (8..1).map {|n| Texture.importImg("res/DUMMY%(n).png")}.toList)
  }
  solid { true }
}
class Pillar is DirectionalSprite {
  construct new(pos) {
    super(pos, Texture.importImg("res/column.png"))
  }
  solid { true }
  vMove { 0 }
  vDiv { 1 }
  width { 0.5 }
}
