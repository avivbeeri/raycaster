import "graphics" for ImageData, Canvas, Color
import "math" for Vec, M

var alpha = 0.5
var VEC = Vec.new()
var NULL_COLOR = Color.pink
var DARK_NULL_COLOR = Color.rgb(NULL_COLOR.r * alpha, NULL_COLOR.g * alpha, NULL_COLOR.b * alpha)

class Renderer {
  construct init(world, width, height) {
    _world = world
    _w = width
    _h = height
    _halfW = _w / 2
    _halfH = _h / 2
    _canvas = ImageData.create("buffer", _w, _h)
    _targetSprite = null

    _camera = Vec.new(-1, 0)
    _rayBuffer = List.filled(_w, null).map { [0, 0, 0, 0, 0] }.toList
    _DIST_LOOKUP = []
    for (y in 0..._h) {
      _DIST_LOOKUP.add(_h / (2.0  * y - _h))
    }
    _dirty = true
    floors = _world.floorTexture
    ceilings = _world.ceilingTexture
  }
  targetSprite { _targetSprite }
  getTexture(n) {
    if (n - 1 < _world.textures.count) {
      return _world.textures[n - 1]
    }
  }

  width { _w }
  height { _h }
  floors=(v) {
    _drawFloor = v != null && !(v is Color)
    _floorTexture = v != null ? v : Color.darkgray
  }
  ceilings=(v) {
    _drawCeiling = v != null && !(v is Color)
    _ceilingTexture  = v != null ? v : Color.lightgray
  }

  update() {
    _targetSprite = null
    var position = _world.player.pos
    var direction = _world.player.dir
    _camera.x = -direction.y
    _camera.y = direction.x

    if (_dirty) {
      var rayPosition = position
      var castResult = [0, 0, 0]
      for (x in 0..._w) {
        var cameraX = 2 * (x / _w) - 1
        var rayDirection = direction + (_camera * cameraX)
        _world.castRay(castResult, rayPosition, rayDirection, false)
        var mapPos = castResult[0]
        var side = castResult[1]
        var stepDirection = castResult[2]
        var tile = _world.getTileAt(mapPos)

        var perpWallDistance
        /* if (tile["door"]) {
          // If it's a door, we need to shift the map position to draw it in the correct location
          if (side == 0) {
            mapPos.x = mapPos.x + stepDirection.x * 0.5
          } else {
            mapPos.y = mapPos.y + stepDirection.y * 0.5
          }
          } else */
        var offsetX = 0
        var offsetY = 0
        if (tile["door"]) {
          offsetX = 0.5
          offsetY = 0.5
        }
        if (tile["thin"]) {
          // If it's a door, we need to shift the map position to draw it in the correct location
          offsetX = 0.5 + M.mid(-0.5, tile["thin"] * stepDirection.x.sign, 0.5)
          offsetY = 0.5 + M.mid(-0.5, tile["thin"] * stepDirection.y.sign, 0.5)
        }
        if (tile["door"] || offsetX != 0 || offsetY != 0) {
          if (side == 0) {
            mapPos.x = mapPos.x + stepDirection.x * offsetX
          } else {
            mapPos.y = mapPos.y + stepDirection.y * offsetY
          }
        }
        if (side == 0) {
          perpWallDistance = M.abs((mapPos.x - position.x + (1 - stepDirection.x) / 2) / rayDirection.x)
        } else {
          perpWallDistance = M.abs((mapPos.y - position.y + (1 - stepDirection.y) / 2) / rayDirection.y)
        }
        //SET THE ZBUFFER FOR THE SPRITE CASTING
        var ray = _rayBuffer[x]
        ray[0] = perpWallDistance
        ray[1] = mapPos
        ray[2] = side
        ray[3] = rayDirection
        ray[4] = tile
      }
    }

  }


  draw(alpha) {
    if (!_dirty) {
      return
    }

    // Profiling variables
    var start
    start = System.clock
    var end
    var ms = 0
    var localStart
    var localEnd
    var counter = 0
    // ms = ms / counter * 1000

    cls()
    // Wall casting
    var rayPosition = _world.player.pos
    // rayDir for leftmost ray (x = 0) and rightmost ray (x = w)
    for (x in 0..._w) {
      counter = counter + 1
      var ray = _rayBuffer[x]
      var perpWallDistance = ray[0]
      var mapPos = ray[1]
      var side = ray[2]
      var rayDirection = ray[3]
      var tile = ray[4]

      var color = Color.black
      var texture = getTexture(tile.texture)

      // var lineHeight = M.abs(_h / perpWallDistance)
      var lineHeight = M.max(0, _h / perpWallDistance)
      var drawStart = (-lineHeight / 2) + (_halfH)
      var drawEnd = (lineHeight / 2) + (_halfH)
      // If we are too close to a block, the lineHeight is gigantic, resulting in slowness
      // So we clip the drawStart-End and _then_ calculate the texture position.
      drawStart = M.max(0, drawStart.round)
      drawEnd = M.min(_h, drawEnd.round)

      var wallX
      if (side == 0) {
        wallX = rayPosition.y + perpWallDistance * rayDirection.y
      } else {
        wallX = rayPosition.x + perpWallDistance * rayDirection.x
      }
      wallX = wallX - wallX.floor

      /*
      UNTEXTURED COLOR CHOOSER
      */
      if (texture == null) {
        // WORST CASE
        color = NULL_COLOR
        if (side == 1) {
          color = DARK_NULL_COLOR
        }
        for (y in drawStart...drawEnd) {
          _canvas.pset(x, y, color)
        }
      } else {

        var texWidth = texture.width
        var texX = wallX * texWidth
        if (tile["door"]) {
          if (wallX < 0.5) {
            texX = wallX - (tile["door"].state - 1) * 0.5
          } else {
            texX = wallX + (tile["door"].state + 1) * 0.5
          }
          texX = texX * texWidth
        }
        if (side == 0 && rayDirection.x < 0) {
          texX = texWidth - texX
        }
        if (side == 1 && rayDirection.y > 0) {
          texX = texWidth - texX
        }
        var texStep = texture.height / lineHeight
        var texPos = (drawStart - _halfH + lineHeight / 2) * texStep
        for (y in drawStart...drawEnd) {
          var texY = texPos
          if (side == 1) {
            color = texture.pgetDark(texX, texY)
          } else {
            color = texture.pget(texX, texY)
          }
          _canvas.pset(x, y, color)
          texPos = texPos + texStep
        }
      }
      if (_drawFloor || _drawCeiling) {
        var floorXWall
        var floorYWall
        if (side == 0 && rayDirection.x > 0) {
          floorXWall = mapPos.x
          floorYWall = mapPos.y + wallX
        } else if (side == 0 && rayDirection.x < 0) {
          floorXWall = mapPos.x + 1.0
          floorYWall = mapPos.y + wallX
        } else if (side == 1 && rayDirection.y > 0) {
          floorXWall = mapPos.x + wallX
          floorYWall = mapPos.y
        } else {
          floorXWall = mapPos.x + wallX
          floorYWall = mapPos.y + 1.0
        }
        var distWall = perpWallDistance
        var floorTex = _floorTexture
        var ceilTex = _ceilingTexture
        drawEnd = drawEnd.floor
        localStart = System.clock
        for (y in (drawEnd)..._h) {
          var currentDist = _DIST_LOOKUP[y.floor]
          var weight = currentDist / distWall
          var currentFloorX = weight * floorXWall + (1.0 - weight) * rayPosition.x
          var currentFloorY = weight * floorYWall + (1.0 - weight) * rayPosition.y
          var c
          var floorTexX
          var floorTexY
          var ceilTexX
          var ceilTexY
          if (_drawFloor && _drawCeiling) {
            floorTexX = ((currentFloorX * (floorTex.width)).floor % (floorTex.width))
            if (floorTex.width == ceilTex.width) {
              ceilTexX = floorTexX
            } else {
              ceilTexX = ((currentFloorX * (ceilTex.width)).floor % ceilTex.width)
            }
            floorTexY = ((currentFloorY * (floorTex.height)).floor % (floorTex.height))
            if (floorTex.height == ceilTex.height) {
              ceilTexY = floorTexY
            } else {
              ceilTexY = ((currentFloorY * (ceilTex.height)).floor % ceilTex.height)
            }
          } else if (_drawFloor) {
            floorTexX = ((currentFloorX * (floorTex.width)).floor % (floorTex.width))
            floorTexY = ((currentFloorY * (floorTex.height)).floor % (floorTex.height))
          } else if (_drawCeiling) {
            ceilTexX = ((currentFloorX * (ceilTex.width)).floor % ceilTex.width)
            ceilTexY = ((currentFloorY * (ceilTex.height)).floor % ceilTex.height)
          }
          if (_drawFloor) {
            c = floorTex.pget(floorTexX, floorTexY)
            _canvas.pset(x.floor, y.floor, c)
          }
          if (_drawCeiling) {
            c = ceilTex.pget(ceilTexX, ceilTexY)
            _canvas.pset(x.floor, (_h - y.floor - 1), c)
          }
        }
        localEnd = System.clock
        ms = ms + (localEnd - localStart)
      }
    }

    var dir = _world.player.dir
    for (sprite in _world.entities) {

      var uDiv = sprite.uDiv
      var vDiv = sprite.vDiv
      var vMove = sprite.vMove

      var transform = _world.getSpriteTransform(rayPosition, dir, sprite)
      var transformX = transform.x
      var transformY = transform.y
      if (transformY > 0) {

        var vMoveScreen = (vMove / transformY).floor

        var spriteScreenX = ((_halfW) * (1 + transformX / transformY)).floor
        // Prevent fisheye
        var spriteHeight = ((_h / transformY).abs / vDiv).floor
        var drawStartY = (((_h - spriteHeight) / 2) + vMoveScreen).floor
        if (drawStartY < 0) {
          drawStartY = 0
        }
        var drawEndY = (((_h + spriteHeight) / 2) + vMoveScreen).floor
        if (drawEndY >= _h) {
          drawEndY = _h - 1
        }

        // Optimisation note: this is actually half of spriteWidth, because we typically divide it by 2
        var spriteWidth = (((_h / transformY).abs / uDiv) / 2).floor
        var drawStartX = (spriteScreenX - spriteWidth).floor
        if (drawStartX < 0) {
          drawStartX = 0
        }
        var drawEndX = (spriteScreenX + spriteWidth).floor
        if (drawEndX >= _w) {
          drawEndX = _w - 1
        }

        var texture = sprite.currentTex
        var texWidth = texture.width
        var texHeight = texture.height
        for (stripe in drawStartX...drawEndX) {
          var texX = ((stripe - (-spriteWidth + spriteScreenX)) * texWidth / (spriteWidth * 2)).abs

          // Conditions for this if:
          //1) it's in front of camera plane so you don't see things behind you
          //2) it's on the screen (left)
          //3) it's on the screen (right)
          //4) ZBuffer, with perpendicular distance
          if (stripe > 0 && stripe < _w && transformY < _rayBuffer[stripe][0]) {
            for (y in drawStartY...drawEndY) {
              var texY = (((y - vMoveScreen) - (-spriteHeight / 2 + _h / 2)) * texHeight / spriteHeight).abs
              var color = texture.pget(texX, texY)
              if (color.a != 0) {
                _canvas.pset(stripe, y.floor, color)

                if (stripe == 1) {
                  _canvas.pset(0, y.floor, color)
                }
                if (stripe == _w - 1) {
                  _canvas.pset(_w - 1, y.floor, color)
                }
              }
            }
          }
        }
      }
    }
    flip()
    Canvas.print(ms * 1000, 0, _h - 8, Color.white)
  }

  cls() {
    if (!(_drawFloor && _drawCeiling)) {
      for (y in 0..._halfH) {
        for (x in 0..._w) {
          var c
          if (!_drawCeiling) {
            c = _ceilingTexture
            _canvas.pset(x, y, c)
          }
          if (!_drawFloor) {
            c = _floorTexture
            _canvas.pset(x, _h - y - 1, c)
          }
        }
      }
    }
  }

  flip() {
    Canvas.draw(_canvas, 0, 0)
  }
}
