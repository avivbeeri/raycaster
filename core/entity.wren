import "math" for M, Vec


var PI_RAD = Num.pi / 180
var VEC = Vec.new()
var CAST_RESULT = [0, 0, 0, 0]
var MOVE_SPEED = 2/ 60

class Entity {
  construct new(position) {
    _pos = position
    _alive = true
  }
  alive { _alive }
  alive=(v) { _alive = v }
  solid { false }
  pos { _pos }
  pos=(v) { _pos = v }

  update(context) {}
  draw() {}
}

class Player is Entity {
  construct new(position, angle) {
    super(position)
    _dir = Vec.new()
    _vel = Vec.new()
    this.angle = angle
  }

  angle { _angle }
  angle=(v) {
    _angle = v % 360
    if (_angle < 0) {
      _angle = _angle + 360
    }
    _dir.x = M.cos(_angle * PI_RAD)
    _dir.y = M.sin(_angle * PI_RAD)
  }

  update(context) {
    this.vel = this.vel.unit * MOVE_SPEED

    var solid
    var oldPosition = VEC
    oldPosition.x = this.pos.x
    oldPosition.y = this.pos.y

    this.pos.x = this.pos.x + this.vel.x
    solid = context.isTileHit(pos)
    if (!solid) {
      solid = context.isSpaceOccupied(pos)
    }
    if (solid) {
      this.pos.x = oldPosition.x
      this.pos.y = oldPosition.y
    }

    oldPosition.x = this.pos.x
    oldPosition.y = this.pos.y

    this.pos.y = this.pos.y + this.vel.y
    solid = context.isTileHit(this.pos)
    if (!solid) {
      solid = context.isSpaceOccupied(pos)
    }
    if (solid) {
      this.pos.x = oldPosition.x
      this.pos.y = oldPosition.y
    }
    oldPosition.x = this.pos.x
    oldPosition.y = this.pos.y
  }

  getTarget(context) {
    context.castRay(CAST_RESULT, pos, dir, true)
    return CAST_RESULT[0]
  }

  dir { _dir }
  vel { _vel }
  vel=(v) { _vel = v }

}

class Sprite is Entity {
  construct new(pos, textures) {
    super(pos)
    if (!(textures is List)) {
      textures = [ textures ]
    }
    _textures = textures
    _octant = 0
  }

  textures { _textures }
  octant { _octant }
  octant=(v) { _octant = v % _textures.count }
  currentTex { _textures[octant] }

  width { 1 }
  uDiv { 1 }
  vDiv { 1 }
  vMove { 0 }
}

class DirectionalSprite is Sprite {
  construct new(pos, textures) {
    super(pos, textures)
    _segmentSize = 360 / this.textures.count
  }

  update(context) {
    super(context)
    var playerPos = pos - context.player.pos
    var angle = (playerPos.y.atan(playerPos.x) / PI_RAD + 360 - _segmentSize / 2) % 360
    octant = (angle / _segmentSize).round
  }
}


// to prevent circular dependancy issues, this goes last
import "core/door" for Door, SecretDoor
