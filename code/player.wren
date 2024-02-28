import "xs" for Input, Render, Data
import "xs_math" for Vec2, Color, Math, Bits
import "xs_ec"for Entity, Component
import "xs_components" for Renderable, Transform, GridSprite

class Player is Component {
    static initialize() {
        __passivePowerUp = PowerUps.none
    }

    construct new() {
        _canMove = false       
        resetRange()
        _moveDir = Vec2.new(0.0, 0.0)
        _moveHex = null
        _deadzone = 0.4
        _multiplier = 1        
    }

    initialize() {
        _transform = owner.getComponent(Transform)
        _hexTile = owner.getComponent(HexTileComponent)

        var rangeImg = Render.loadImage("[game]/assets/images/generated/small_hexagon.png")
        _rangeSprite = Render.createSprite(rangeImg, 0, 0, 1, 1)

        var thickImg = Render.loadImage("[game]/assets/images/generated/thick_small_hexagon.png")
        _thickSprite = Render.createSprite(thickImg, 0, 0, 1, 1)

        var directionImg = Render.loadImage("[game]/assets/images/generated/direction_indicator.png")
        _directionSprite = GridSprite.new(directionImg, 7, 1)   

        if(Gameplay.level >= Data.getNumber("Level Extra Range")) {
            __passivePowerUp = PowerUps.range
        }
        resetRange()

        System.print("Player initialized with transform " + _transform.toString + " and hexTile " + _hexTile.toString)
    }

    update(dt) { }

    turn() {
        if(!initialized_) {
            return false
        }

        if(_range == 0) {
            return true
        }

        _moveDir = Vec2.new(Input.getAxis(0), Input.getAxis(1))
        _moveHex = null

        // Mouse input
        var tag = Tag.enemy | Tag.powerUp // | 
        if(Input.getMouse()) {
            var x = Input.getMouseX().round
            var y = -Input.getMouseY().round
            var mouse = Vec2.new(x, y)
            var pos = _transform.position
            var hex = Gameplay.grid.getHex(mouse)
            
            if(Gameplay.grid.isValid(hex) && HexCoordinate.distance(hex, _hexTile.tile) == 1) {
                if(_hexTile.canMoveTo(hex, tag)) {
                    _moveHex = hex
                }
                if(Input.getMouseButtonOnce(0) && _hexTile.canMoveTo(hex, tag)) {
                    var tile = _hexTile.moveTo(hex)
                    tileStep(tile)
                }
            }            
        }        

        // Controller input
        if(_canMove && _moveDir.magnitude > _deadzone && _range > 0) {
            var angle = -_moveDir.atan2 + Num.pi / 6.0
            var angleHex = (angle) / (Num.pi * 2.0) * 6.0
            angleHex = angleHex.round
            
            if(_moveDir.magnitude > 0.85 && _hexTile.canMove(angleHex, tag)) {
                var tile = _hexTile.move(angleHex)                
                tileStep(tile)
            }            
        } else {
            if(_moveDir.magnitude < _deadzone * 0.5) {
                _canMove = true
            }
        }

        return _range == 0
    }

    tileStep(tile) {
        if(tile != null) {
            if(tile.owner.tag == Tag.enemy) {
                Gameplay.score = Gameplay.score + _multiplier                
                _multiplier = _multiplier + 1
                Create.explosion(_hexTile.tile, Data.getColor("Color Enemy"))                        
            } else if(tile.owner.tag == Tag.powerUp) {
                __passivePowerUp = PowerUps.range
            }
            tile.owner.getComponent(Enemy).destroy()
            Gameplay.updateDist()
        }
        _canMove = false
        _range = _range - 1
    }

    resetRange() {
        System.print("Reset range") 
        if(__passivePowerUp == PowerUps.range) {
            _range = 3        
        } else {
            _range = 2
        }        
        _multiplier = 1
    }

    range { _range }
    multiplier { _multiplier }

    render() {
    
        var inRange = Gameplay.grid.getHexesInRange(_hexTile.tile, _range)
        
        /*
        for(hex in inRange) {
            var pos = Gameplay.grid.getPosition(hex)
            var dist = Gameplay.distGrid.getTileAt(hex)
            var tile = Gameplay.grid.getTileAt(hex)
            if(dist != null) {                
                if(dist == 1 && range > 0) {
                    var color = Data.getColor("Color Player")
                    Render.sprite(_rangeSprite, pos.x, pos.y, 0.0, 1.0, 0.0, color, 0x0, Render.spriteCenter)
                } else if(dist == 2 && _range > 1) {
                    var color = Data.getColor("Color Player Far")
                    Render.sprite(_rangeSprite, pos.x, pos.y, 0.0, 1.0, 0.0, color, 0x0, Render.spriteCenter)
                } else if(dist == 3 && _range > 2) {
                    var color = Data.getColor("Color Player Farther")
                    Render.sprite(_rangeSprite, pos.x, pos.y, 0.0, 1.0, 0.0, color, 0x0, Render.spriteCenter)
                }                 
            } else if(tile != null && tile.owner.tag == Tag.enemy) {
                Render.sprite(_rangeSprite, pos.x, pos.y, 0.0, 1.0, 0.0, color, 0x0, Render.spriteCenter)
            }
        }
        */

        var color = Data.getColor("Color Player")
        if(_canMove && _moveDir.magnitude > _deadzone && _range > 0) {
            var angle = -_moveDir.atan2 + Num.pi / 6.0
            var angleHex = (angle) / (Num.pi * 2.0) * 6.0
            angleHex = angleHex.round
            if(_hexTile.canMove(angleHex, Tag.enemy)) {
                var pos = Gameplay.grid.getPosition(_hexTile.tile.getNeighbor(angleHex))
                var prog = (_moveDir.magnitude *  7.0).round
                var sprite = _directionSprite[prog]
                Render.sprite(sprite, pos.x, pos.y, 1.1, 1.0, 0.0, color, 0x0, Render.spriteCenter)
                Render.sprite(_thickSprite, pos.x, pos.y, 1.0, 1.0, 0.0, color, 0x0, Render.spriteCenter)                                
            }
        }

        if(_moveHex != null) {
            var pos = Gameplay.grid.getPosition(_moveHex)
            Render.sprite(_thickSprite, pos.x, pos.y, 0.0, 1.0, 0.0, color, 0x0, Render.spriteCenter)
            var sprite = _directionSprite[6]
                Render.sprite(sprite, pos.x, pos.y, 1.1, 1.0, 0.0, color, 0x0, Render.spriteCenter)
        }
    }
}

import "game" for Game, GameState
import "code/tags" for Tag, PowerUps
import "code/data" for Grid, Queue
import "code/hex" for HexCoordinate, HexGrid, HexTileComponent
import "code/create" for Create
import "code/ui" for UI
import "code/gameplay" for Gameplay
import "code/enemy" for Enemy
