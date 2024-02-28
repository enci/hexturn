import "xs" for Input, Render, Data
import "xs_math" for Vec2, Color, Math, Bits
import "xs_ec"for Entity, Component
import "xs_components" for Renderable, Transform, GridSprite
import "random" for Random

class State {
    static none     { -1 }
    static player   { 0 }
    static enemy    { 1 }
    static outro    { 2 }
    static wait     { 3 }
}

class Gameplay {

    static init() {             
        System.print("Gameplay init")
        __level = 10
        __timer = 0.0
        __score = 0
        __hexSize = 66
        __gridSize = 4
        __state = State.none      
        __nextState = State.none  
        Player.initialize()
    }

    static reset() {
        System.print("Gameplay reset")
        if(__state == State.none) {
            System.print("Gameplay not started")
            return
        }        
        __player.delete()
        for(enemy in __enemies) {
            enemy.delete()
        }        
        for(obstacle in __obstacles) {
            obstacle.delete()
        }        
        UI.shutdown()
    }

    static start() {
        System.print("Gameplay start")
        if(__level >= Data.getNumber("Level Enlarge Grid")) {
            __gridSize = 5
        }
        __gameGrid = HexGrid.new(__hexSize, __gridSize)
        __distGrid = HexGrid.new(__hexSize, __gridSize)
        __triangle = GridSprite.new("[game]/assets/images/triangle.png", 6, 1)
        __player = Create.player() 
        System.print("Player created" + __player.toString)       
        __obstacles = Create.obstacles()
        __enemies = Create.enemies(__level + 4)
        __state = State.player
        UI.init()
    }

    static nextLevel() {
        __level = __level + 1
        __score = __score + 1
        reset()
        start()
    }

    static updateDist() {
        // Fresh grid
        __distGrid = HexGrid.new(__gameGrid.hexSize, __gameGrid.gridSize)

        if(__player.deleted) {
            return
        }

        // Flood fill from player's position
        var playerHexComponent = __player.getComponent(HexTileComponent)
        var playerHex = playerHexComponent.tile
        var open = Queue.new()
        open.push(playerHex)
        __distGrid.setTileAt(playerHex, 0)
        
        while (!open.empty()) {
            var current = open.pop()            
            var neighbors = current.getNeighbors()            
            var distance = __distGrid.getTileAt(current) + 1
            for (neighbor in  neighbors) {
                if(!__distGrid.isValid(neighbor)) {
                    continue
                }
                var tile = __distGrid.getTileAt(neighbor)
                var gameTile = __gameGrid.getTileAt(neighbor)
                if (tile == null && (gameTile == null || !Bits.checkBitFlagOverlap(gameTile.owner.tag, Tag.obstacle|Tag.powerUp))) { //|
                    open.push(neighbor)
                    __distGrid.setTileAt(neighbor, distance)
                }
            }
        }

    }

    static update(dt) {

        var player = __player.getComponent(Player)
        if(__state == State.wait) {
            __timer = __timer - dt
            if(__timer <= 0.0) {
                __state = __nextState
                __timer = 0.5
            }
        } else if (__state == State.player) {
            if (player.turn()) {                                
                setDelayedState(State.enemy, 0.3)
                for (enemy in __enemies) {
                    var enemyComponent = enemy.getComponent(Enemy)
                    enemyComponent.resetRange()
                }
            }
        } else if (__state == State.enemy) {
            var done = true
            for (enemy in __enemies) {                
                if(enemy.deleted) {
                    continue
                }
                var enemyComponent = enemy.getComponent(Enemy)
                if(!enemyComponent.turn(dt)) {
                    done = false
                }
                updateDist()
            }                   
            if(done) {
                __state = State.player
                player.resetRange()
            }                 
        } else if (__state == State.outro) {
            __timer = __timer + dt
            if(__timer > 1.0) {
                Game.setState(GameState.score)
            }
        }

        updateDist()
        
        // Check if player is deleted
        if(__player.deleted) {
            __state = State.outro
        }

        // Check if all enemies are deleted
        var allDeleted = true
        for (enemy in __enemies) {
            if(!enemy.deleted) {
                allDeleted = false
                break
            }
        }

        if(allDeleted && !__player.deleted) {
            Game.setState(GameState.great)            
        }

        __gameGrid.cleanUp()

        UI.update(dt)
    }

    static getBestDirection(hex) {
        var neighbors = hex.getNeighbors()
        var best = -1
        var bestDistance = 9999
        for (i in 0...neighbors.count) {
            var neighbor = neighbors[i]
            if(!__distGrid.isValid(neighbor)) {
                continue
            }
            var dist = __distGrid.getTileAt(neighbor)
            if (dist != null && dist < bestDistance) {
                best = i
                bestDistance = dist
            }
        }
        return best
    }

    static render() {

        // Get all the dangerous tiles
        var enemies = Entity.withTagOverlap(Tag.enemy)
        var tiles = Map.new()
        for(e in enemies) {
            var htc = e.getComponent(HexTileComponent)
            var tile = htc.tile
            var ec = e.getComponent(Enemy)
            var neighbors = __gameGrid.getFreeHexesInRange(tile, ec.maxRange)
            for(n in neighbors) {
                tiles[n.hash] = n    
            }
        }

        var dangerColor = Data.getColor("Color Enemy")        
        var normalColor = Data.getColor("Color Active Tile")        
        var n = 6
        var origin = HexCoordinate.new(0, 0)
        for (x in -n..n) {
            for(y in -n..n) {                
                var hex = HexCoordinate.new(x, y)
                if(HexCoordinate.distance(hex, origin) < __gameGrid.gridSize) {
                    var pos = __gameGrid.getPosition(hex)
                    var distance = __distGrid.getTileAt(hex)

                    if(Data.getBool("Debug Distance")) {
                        Render.setColor(0xFFFFFFFF)
                        var text = distance.toString                    
                        Render.shapeText(text, pos.x, pos.y, 1.0)
                    }
                    
                    var best = Gameplay.getBestDirection(hex)
                    var dist = __distGrid.getTileAt(hex)
                    var tile = __gameGrid.getTileAt(hex)
                    if (best != -1 && dist != null && tile == null) {
                        var triangleSprite = __triangle[best]
                        if(tiles.containsKey(hex.hash)) {
                            Render.sprite(triangleSprite, pos.x, pos.y, 1.0, 1.0, 0.0, dangerColor, 0x0, Render.spriteCenter)
                        } else {
                            Render.sprite(triangleSprite, pos.x, pos.y, 1.0, 1.0, 0.0, normalColor, 0x0, Render.spriteCenter)
                        }
                    } else {
                        if(tile != null) {
                            var stealth = tile.owner.getComponent(Stealth)
                            if(stealth != null && stealth.alpha <= 0.0) {                                
                                    var rangeSprite = __triangle[0]
                                    Render.sprite(rangeSprite, pos.x, pos.y, 1.0, 1.0, 0.0, dangerColor, 0x0, Render.spriteCenter)
                            }
                        }
                    }                             
                }
            }
        }

        

        var player = __player.getComponent(Player)
        if(!__player.deleted && player.initialized_) {            
            player.render()
        }

        // Render.shapeText("State: " + __state.toString, -200, -150, 1.0)

    }

    static setDelayedState(state, time) {
        __state = State.wait
        __nextState = state
        __timer = time
    }

    static cleanUp() {
        __gameGrid.cleanUp()
    }

    static grid { __gameGrid }
    static distGrid {  __distGrid }
    static player { __player }
    static score { __score }
    static score=(value) { __score = value }
    static level { __level }
    static gridSize { __gridSize }
    static hexSize { __hexSize }
}

import "game" for Game, GameState
import "code/data" for Grid, Queue
import "code/hex" for HexCoordinate, HexGrid, HexTileComponent
import "code/tags" for Tag
import "code/create" for Create
import "code/ui" for UI
import "code/player" for Player
import "code/enemy" for Enemy, EnemyType, Stealth

