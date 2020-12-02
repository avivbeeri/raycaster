import "math" for Vec, M
import "./map" for TileMap, Tile
var VEC = Vec.new()

class World {
  construct new() {}
  player { _player }
  player=(v) { _player = v }

  doors { _doors }
  doors=(v) { _doors = v }

  entities { _entities }
  entities=(v) { _entities = v }

  map { _map }
  map=(v) { _map = v }

  textures { _textures }
  textures=(v) { _textures = v }

  floorTexture { _floorTexture }
  floorTexture=(v) { _floorTexture = v }
  ceilingTexture { _ceilTexture }
  ceilingTexture=(v) { _ceilTexture = v }

  update() {
    player.update(this)
    entities.each {|sprite| sprite.update(this) }
    World.filterSprites(entities)
    World.sortSprites(entities, player.pos)
    doors.each {|door| door.update(this) }
  }

  isSpaceOccupied(pos) {
    var solid = false
    for (entity in entities) {
      var diffX = entity.pos.x - pos.x
      var diffY = entity.pos.y - pos.y
      if ((diffX * diffX + diffY*diffY).sqrt <= (0.5 + 0.5)) {
        solid = solid || entity.solid
      }
      if (solid) {
        break
      }
    }
    return solid
  }

  getTileAt(position) {
    return map.get(position)
  }

  getDoorAt(position) {
    VEC.x = position.x.floor
    VEC.y = position.y.floor
    var mapPos = VEC
    for (door in doors) {
      if (door.pos == mapPos) {
        return door
      }
    }
    return null
  }

  isTileHit(pos) {
    VEC.x = pos.x.floor
    VEC.y = pos.y.floor
    var mapPos = VEC
    //var mapPos = Vec.new(pos.x.round, pos.y.round)
    var tile = getTileAt(mapPos)
    var hit = false
    if (tile["door"] == true) {
      hit = getDoorAt(mapPos).state > 0.5
    } else {
      hit = tile["solid"] == true
    }
    return hit
  }

  castRay(result, rayPosition, rayDirection, ignoreDoors) {
    var position = player.pos
    var direction = player.dir

    var sideDistanceX = (1.0 + rayDirection.y.pow(2) / rayDirection.x.pow(2)).sqrt
    var sideDistanceY = (1.0 + rayDirection.x.pow(2) / rayDirection.y.pow(2)).sqrt

    var nextSideDistanceX
    var nextSideDistanceY
    var mapPos = Vec.new(rayPosition.x.floor, rayPosition.y.floor)
    var stepDirection = Vec.new()
    if (rayDirection.x < 0) {
      stepDirection.x = -1
      nextSideDistanceX = (rayPosition.x - mapPos.x) * sideDistanceX
    } else {
      stepDirection.x = 1
      nextSideDistanceX = (mapPos.x + 1.0 - rayPosition.x) * sideDistanceX
    }
    if (rayDirection.y < 0) {
      stepDirection.y = -1
      nextSideDistanceY = (rayPosition.y - mapPos.y) * sideDistanceY
    } else {
      stepDirection.y = 1
      nextSideDistanceY = (mapPos.y + 1.0 - rayPosition.y) * sideDistanceY
    }

    var hit = false
    var side = 0
    while (!hit) {
      if (nextSideDistanceX < nextSideDistanceY) {
        nextSideDistanceX = nextSideDistanceX + sideDistanceX
        mapPos.x = (mapPos.x + stepDirection.x)
        side = 0
      } else {
        nextSideDistanceY = nextSideDistanceY + sideDistanceY
        mapPos.y = (mapPos.y + stepDirection.y)
        side = 1
      }

      var tile = getTileAt(mapPos)
      var doorState = 1
      if (tile["door"]) {
        // Figure out the door position
        doorState = ignoreDoors ? 1 : getDoorAt(mapPos).state
      }
      if (tile["thin"]) {
        var adj
        var ray_mult
        // Adjustment
        if (side == 0) {
          adj = mapPos.x - position.x + 1
          if (position.x < mapPos.x) {
            adj = adj - 1
          }
          ray_mult = adj / rayDirection.x
        } else {
          adj = mapPos.y - position.y
          if (position.y > mapPos.y) {
            adj = adj + 1
          }
          ray_mult = adj / rayDirection.y
        }

        var rye2 = rayPosition.y + rayDirection.y * ray_mult
        var rxe2 = rayPosition.x + rayDirection.x * ray_mult

        var trueDeltaX = sideDistanceX
        var trueDeltaY = sideDistanceY
        if (rayDirection.y.abs < 0.01) {
          trueDeltaY = 100
        }
        if (rayDirection.x.abs < 0.01) {
          trueDeltaX = 100
        }

        var offsetX = 0
        var offsetY = 0

        if (tile["thin"]) {
          offsetX = 0.5 + M.mid(-0.5, (tile["thin"] || -0.5) * stepDirection.x.sign, 0.5)
          offsetY = 0.5 + M.mid(-0.5, (tile["thin"] || -0.5) * stepDirection.y.sign, 0.5)
        }

        if (side == 0) {
          // var halfY = mapPos.y + sideDistanceY * 0.5
          var true_y_step = (trueDeltaX * trueDeltaX - 1).sqrt
          var half_step_in_y = rye2 + (stepDirection.y * true_y_step) * offsetX
          hit = (half_step_in_y.floor == mapPos.y) && (1 - 2*(half_step_in_y - mapPos.y)).abs >= 1 - doorState
        } else {
          var true_x_step = (trueDeltaY * trueDeltaY - 1).sqrt
          var half_step_in_x = rxe2 + (stepDirection.x * true_x_step) * offsetY
          hit = (half_step_in_x.floor == mapPos.x) && (1 - 2*(half_step_in_x - mapPos.x)).abs >= 1 - doorState
        }
      } else {
        hit = tile["solid"] == true
      }
    }
    result[0] = mapPos
    result[1] = side
    result[2] = stepDirection
    return result
  }

  static filterSprites(list) {
    var i = 0
    var last = list.count - 1
    while (i < list.count) {
      if (!list[i].alive) {
        list[i] = list[last]
        list.removeAt(last)
        last = last - 1
      }
      i = i + 1
    }
  }

  static sortSprites(list, position) {
    var i = 1
    while (i < list.count) {
      var x = list[i]
      var j = i - 1
      while (j >= 0 && (list[j].pos - position).length < (x.pos - position).length) {
        list[j + 1] = list[j]
        j = j - 1
      }
      list[j + 1] = x
      i = i + 1
    }
  }

  destroySprite(sprite) {
    sprite.alive = false
  }

  getSpriteTransform(pos, dir, sprite) {
    var cam = VEC
    cam.x = dir.y
    cam.y = -dir.x
    var invDet = 1.0 / (-cam.x * dir.y + dir.x * cam.y)

    var spriteX = sprite.pos.x - pos.x
    var spriteY = sprite.pos.y - pos.y

    var transformX = invDet * (dir.y * spriteX - dir.x * spriteY)
    //this is actually the depth inside the screen, that what Z is in 3D
    var transformY = invDet * (cam.y * spriteX - cam.x * spriteY)
    VEC.x = transformX
    VEC.y = transformY
    return VEC // copy for the answer
  }

  getTargetSprite(pos, dir, zDist) {
    var target = null
    for (sprite in entities) {
      var transform = getSpriteTransform(pos, dir, sprite)
      if (0 < transform.y && transform.y < zDist && transform.x.abs <= 0.5 * sprite.width) {
        target = sprite
      }
    }
    return target
  }
}
