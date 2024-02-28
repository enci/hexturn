import "xs" for Input, Render, Data
import "xs_math" for Vec2, Color, Math, Bits
import "xs_ec"for Entity, Component
import "xs_components" for Renderable, Transform, GridSprite

class EnemyType {
    static none     { -1 }
    static basic    { 0 }   // One move per turn
    static range    { 1 }   // Two moves per turn
    static stealth  { 2 }   // Invisible until close
    static powerUp  { 3 }   // Drops power ups
    static split    { 4 }   // Splits into two enemies when killed
    static boss     { 5 }   // Takes multiple hits to kill
    static resurect { 6 }   // Comes back to life after a few turns
    static explode  { 7 }   // Explodes when killed taking out nearby enemies
}

class Enemy is Component {
    construct new(type) {
        _type = type       
        _time = 1.0
        resetRange()
    }

    initialize() {
        _transform = owner.getComponent(Transform)
        _hexTile = owner.getComponent(HexTileComponent)
    }

    update(dt) {}

    turn(dt) {
        _time = _time + dt
        if(_range > 0 && _time > 0.5) {
            var best = Gameplay.getBestDirection(_hexTile.tile)        
            if(best != -1) {
                var tile = _hexTile.tile.getNeighbor(best)
                tile = Gameplay.grid.getTileAt(tile)
                if (tile == null) {
                    _hexTile.move(best)
                    Gameplay.updateDist()
                } else if(tile.owner.getComponent(Player) != null) {
                    _hexTile.move(best)
                    tile.owner.delete()
                    Create.explosion(tile.tile, Data.getColor("Color Player"))
                    System.print("Delete player")
                } else {                
                    System.print("Can't move to tile " + tile.owner.toString)
                }
            } else {
                System.print("No best direction")
            }
            _range = _range - 1 
            _time = 0.0
        }
        return _range == 0        
    } 

    destroy() {
        System.print("Destroy enemy")
        if(_type == EnemyType.split) {
            //Create.enemy(_hexTile.tile, EnemyType.basic)
            //Create.enemy(_hexTile.tile, EnemyType.basic)
        } else if(_type == EnemyType.explode) {
            var neighbors = _hexTile.tile.getNeighbors()
            for(neighbor in neighbors) {
                var tile = Gameplay.grid.getTileAt(neighbor)
                if(tile != null && !tile.owner.deleted && tile.owner.tag == Tag.enemy) {
                    tile.owner.delete()
                    tile.owner.getComponent(Enemy).destroy()
                }
            }
        } else if(_type == EnemyType.resurect) {
            // Create.enemy(_hexTile.tile, EnemyType.basic)
        }
        owner.delete()
        // Gameplay.cleanUp()
        Gameplay.updateDist()
        Create.explosion(_hexTile.tile, Data.getColor("Color Enemy"))
    }

    resetRange() {
        _range = maxRange
        _time = 1.0
    }

    range { _range }

    maxRange { (_type == EnemyType.range) ? 2 : 1 }

    enemyType { _type }
}

class Stealth is Component {
    construct new() {
        _alpha = 0.0
    }

    initialize() {
        _transform = owner.getComponent(Transform)
        _renderable = owner.getComponentSuper(Renderable)
        _hexTile = owner.getComponent(HexTileComponent)
        _color = Color.fromNum(_renderable.mul)        
        _alpha = 0.0
    }

    update(dt) {
        var playerHex = Gameplay.player.getComponent(HexTileComponent).tile
        var hexDist = HexCoordinate.distance(playerHex, _hexTile.tile)
        if(hexDist <= 2) {
            _alpha = Math.damp(_alpha, 1.0, 2.0, dt)
            
        } else {
            _alpha = Math.damp(_alpha, 0.0, 2.0, dt)
        }
        _color.a = _alpha * 255
        _renderable.mul = _color.toNum
    }

    alpha { _alpha }
}

import "code/hex" for HexCoordinate, HexGrid, HexTileComponent
import "code/tags" for Tag
import "code/create" for Create
import "code/gameplay" for Gameplay
import "code/player" for  Player

