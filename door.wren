import "math" for M
import "./sprite" for Entity

class Door is Entity {
  construct new(position) {
    super(position)
    _locked = false
    _state = 1
    _mode = 0
  }

  locked { _locked }
  state { _state }
  state=(v) { _state = M.mid(0, v, 1) }
  mode { _mode }

  update(context) {
    var player = context.player
    if ((pos - player.pos).length >= 2.75) {
      close()
    }

    state = state + _mode * 0.1
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
