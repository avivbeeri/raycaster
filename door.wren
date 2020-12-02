import "math" for M
import "./sprite" for Entity

class Door is Entity {
  construct new(position) {
    super(position)
    _locked = false
    _state = 1
    _mode = 0
  }

  speed { 0.1 }
  locked { _locked }
  state { _state }
  state=(v) { _state = M.mid(0, v, 1) }
  mode { _mode }

  update(context) {
    var player = context.player
    if ((pos - player.pos).length >= 2.75) {
      close()
    }

    state = state + _mode * speed
    if (state == 0 || state == 1) {
      _mode = 0
    }
  }

  open() {
    if (!_locked) {
      _mode = -1
    }
  }

  close() {
    if (!_locked) {
      _mode = 1
    }
  }
}

class SecretDoor is Door {
  construct new(position) {
    super(position)
    _offset = 0
    _mode = 0
  }

  speed { 0.05 }

  update(context) {
    var tile = context.getTileAt(pos)
    if (mode == -1) {
      _offset = _offset + 0.005
      if (_offset >= 0.25) {
        super.update(context)
      }
    } else {
      super.update(context)
      if (state == 1) {
        _offset = _offset - 0.005
      }
    }
    _offset = M.mid(0, _offset, 0.25)
    tile["thin"] = _offset - 0.5
  }
}
