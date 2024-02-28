import "xs" for Input, Render, Data, File, Device
import "xs_ec"for Entity, Component
import "xs_math"for Math, Bits, Vec2
import "xs_components" for Transform, Body, Renderable, Sprite, GridSprite, AnimatedSprite, Relation, Label

class PingLabel is Sprite {
    construct new(font, text, size0, size1, time) {
        super()
        _font = Render.loadFont("[game]/assets/fonts/cyberspace.ttf", size0)
        _text = text
        _time = time
        _timer = 0.0
        sprite_ = null
        // rotation = 0.0
        scale = 1.0
        mul = 0xFFFFFFFF        
        add = 0x0
        flags = Render.spriteOverlay

        // Create child bar under the label
        var bar = Render.loadImage("[game]/assets/images/generated/menu_bg_bar.png")
        _bg = Render.createSprite(bar, 0, 0, 1, 1)
    }

    update(dt) {
        _timer = _timer + dt        
    }

    render() {
        var t = owner.getComponent(Transform)
        Render.text(_font, _text, t.position.x, t.position.y, mul, add, flags)

        // Render the bar
        var color = Data.getColor("Color UI")
        if(_timer > 0.0 && _timer < _time) {
            var percent = _timer / _time            
            // Render.sprite(_bg, t.position.x - 5, t.position.y - 4, 0.0, percent, 0.0, color, add, flags)
            // color = Data.getColor("Color Player")
        }
        // Render.sprite(_bg, t.position.x + 15, t.position.y + 4, layer, 1.0, 0.0, color, add, flags)        
    }

    text=(t) {
        if(t != _text) {
            _text = t
            _timer = 0.0
        }        
    }

    text { _text }
}

class ImGuiRenderItem_ {
    construct new(text, x, y, selected) {
        _text = text
        _x = x
        _y = y
        _selected = selected
        var bar = Render.loadImage("[game]/assets/images/generated/menu_bg_bar.png")
        _bg = Render.createSprite(bar, 0, 0, 1, 1)
    }

    render(font) {
        var color = Data.getColor("Color UI")
        var pos = Vec2.new(_x, _y)
        if (_selected == true) {
            pos = pos + Vec2.new(4, 0)
            color = Data.getColor("Color UI Selected")
        }
        Render.sprite(_bg, pos.x - 5, pos.y - 4, 0.0, 1.0, 0.0, color, 0x0, 0)
        Render.text(font, _text, pos.x, pos.y, 0x000000FF, 0x0, 0)
    }
}

class ImGui is Renderable {
    construct new(font, size) {
        _x = 0.0
        _y = 0.0
        _dy = size * 2.9
        _active = 0
        _guard = 0
        _count = 0
        _font = Render.loadFont("[game]/assets/fonts/cyberspace.ttf", size)
    }

    begin() { 
        begin(0, 0)
    }

    begin(x, y) { 
        _x = x
        _y = y
        _sy = _y
        _guard = _guard + 1
        _count = 0
        _queue = []
    }

    end() {
        _guard = _guard - 1
    }

    reset() {
        _active = 0
    }

    text(text) {
        var mul = 0xFFFFFFFF
        var action = false
        if(_active == _count) {
            if (Input.getButtonOnce(0) == true || Input.getKeyOnce(Input.keySpace)) {
                action = true
            }

            if(Input.getMouseButtonOnce(0)) {
                var x = Input.getMouseX()
                var y = Input.getMouseY()
                if(x > _x && x < _x + 100 && y > _y && y < _y + _dy) {
                    action = true
                }
            }
        }

        var t = owner.getComponent(Transform)
        _queue.add(ImGuiRenderItem_.new(
            text,
            _x + t.position.x,
            _y + t.position.y,
            _active == _count))

        _count = _count + 1
        _y = _y - _dy
        return action
    }

    slider() {
    }

    update(dt) {

        for(i in 0..._count) {
            var mouseX = Input.getMouseX()
            var mouseY = Input.getMouseY()
            var x = _x
            var y = _sy
            //x = x + owner.getComponent(Transform).position.x
            //y = y + owner.getComponent(Transform).position.y
            x = x - 5
            y = y - i * _dy
            if(mouseX > x && mouseX < x + 100 && mouseY > y && mouseY < y + _dy) {
                _active = i
            }
        }

        if(Input.getButtonOnce(Input.gamepadDPadDown) == true || Input.getKeyOnce(Input.keyDown)) {
            _active = (_active + 1)
        } else if (Input.getButtonOnce(Input.gamepadDPadUp) == true || Input.getKeyOnce(Input.keyUp)) {
            _active = (_active - 1)
        }
    }

    render() {
        for(i in _queue) {
            i.render(_font)
        }
        _queue.clear()
    }
}

class MainMenu is Component {
    construct new() {
        super()
        _imgui = null
        _state = "main"
    }

    update(dt) {
        if(_imgui == null) {
            _imgui = owner.getComponent(ImGui)            
        }

        //_imgui.begin(-60.0, 30.0)
        _imgui.begin()

        if(_state == "main") {
            if(_imgui.text("Start")) {
                _imgui.reset()
                Game.setState(GameState.game)
            }
            if(_imgui.text("Options")) {
                _imgui.reset()
                _state = "options"
                System.print("Options")
            }
            if(_imgui.text("Credits")) {
                _imgui.reset()
                System.print("Credits")
            }
            if(_imgui.text("Quit")) {
                _imgui.reset()
                Device.requestClose()
            }
        } else if(_state == "options") {
            if(_imgui.text("Back")) {
                _imgui.reset()
                _state = "main"
            }
        } else if(_state == "credits") {
            if(_imgui.text("Back")) {
                _imgui.reset()
                _state = "main"
            }
        }
        _imgui.end()
    }
}

class UI {
    static init() {
        var x = -780.0
        var y = 400.0
        var dy = 45.0
        var score = Create.pingLabel(Vec2.new(x, y))
        __score = score.getComponent(PingLabel)
        y = y - dy
        var range = Create.pingLabel(Vec2.new(x, y))
        __range = range.getComponent(PingLabel)
        y = y - dy
        var level = Create.pingLabel(Vec2.new(x, y))
        __level = level.getComponent(PingLabel)
        y = y - dy
        var multiplier = Create.pingLabel(Vec2.new(x, y))
        __multiplier = multiplier.getComponent(PingLabel)
    }

    static shutdown() {
        __score.owner.delete()
        __range.owner.delete()
        __level.owner.delete()
        __multiplier.owner.delete()
    }

    static update(dt) {
        var player = Gameplay.player.getComponent(Player)
        var rangeBars = ""
        for(i in 0...player.range) {
            rangeBars = rangeBars + "|"
        }
        __score.text = "SCORE " + Gameplay.score.toString
        __multiplier.text = "MULT " + player.multiplier.toString
        __range.text = "RANGE " + rangeBars
        __level.text = "LEVEL " + (Gameplay.level + 1).toString
    }

    static render() {}
}

import "game" for Game, GameState
import "code/gameplay" for Gameplay, Player
import "code/create" for Create
