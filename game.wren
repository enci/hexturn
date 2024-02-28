import "xs" for Input, Render, Data
import "xs_math" for Vec2, Math
import "xs_ec"for Entity, Component
import "xs_components" for Renderable
import "random" for Random

class GameState {
    static menu     { 0 }
    static game     { 1 }
    static great    { 2 }
    static score    { 3 }
}

class Game {

    static init() {
        Entity.init()
        Create.init()        
        Gameplay.init()            
        Create.background()        
        
        var image = Render.loadImage("[game]/assets/images/generated/hexagon.png")
        __sprite = Render.createSprite(image, 0, 0, 1, 1)

        image = Render.loadImage("[game]/assets/images/generated/filled_hexagon.png")
        __filledSprite = Render.createSprite(image, 0, 0, 1, 1)

        __time = 0.0
        __mainMenu = Create.mainMenu()
        setState(GameState.game)

        __random = Random.new()
        __shakeOffset = Vec2.new(0, 0)
        __shakeIntesity = 0

        __beat = 0.0
    }

    static config() { }
    
    static update(dt) {
        Entity.update(dt)

        if(__state == GameState.game) {
            Gameplay.update(dt)
        } else if(__state == GameState.menu) {
            //
        } else if(__state == GameState.score) {
            __time = __time + dt
            if(__time > 2.0) {
                __time = 0.0
                setState(GameState.game)
            }
        } else if(__state == GameState.great) {
            __time = __time + dt
            if (__greatScreen == null && __time > 0.5) {
                __greatScreen = Create.greatScreen()
            } else if(__time > 1.5) {
                __time = 0.0
                __greatScreen.delete()
                __greatScreen = null
                __state = GameState.game
                Gameplay.nextLevel()
            }
        }

        if(Data.getBool("Print entities", Data.debug)) {
            Data.setBool("Print entities", false, Data.debug)
            Entity.print()
        }

        __shakeOffset.x = __random.float(-1.0, 1.0)
        __shakeOffset.y = __random.float(-1.0, 1.0)
        __shakeIntesity = Math.damp(__shakeIntesity, 0, dt, 10)        
        if(__shakeIntesity < 0.1) {
            __shakeIntesity = 0
        }

        __beat = __beat + dt
        if(__beat > 1.0) __beat = 0.0
    }

    static render() {
        Render.setOffset(__shakeOffset.x * __shakeIntesity, __shakeOffset.y * __shakeIntesity)

        var activeColor = Data.getColor("Color Active Tile")
        var inactiveColor = Data.getColor("Color Inactive Tile")

        var beat = 1.0 - __beat
        beat = beat.pow(2.0)
        var beatSize = Math.remap(0.0, 1.0, 0.9, 1.2, beat)
        
        var origin = HexCoordinate.new(0, 0)
        for (x in -9..9) {
            for(y in -5..4) {
                var tile = HexCoordinate.fromOffset(x, y)
                var pos = tile.getPosition(Gameplay.hexSize)
                if(HexCoordinate.distance(tile, origin) < Gameplay.gridSize) {                    
                    Render.sprite(__sprite, pos.x, pos.y, 0.0, 1.0, 0.0, activeColor, 0x0, Render.spriteCenter)
                } else {
                    var dist = HexCoordinate.distance(tile, origin)
                    var size = Math.remap(Gameplay.gridSize, 9.0, 1.0, 0.2, dist) * beatSize
                    Render.sprite(__filledSprite, pos.x, pos.y, 0.0, size, 0.0, inactiveColor, 0x0, Render.spriteCenter)
                }
            }
        }
        

        if(__state == GameState.game) {
            Gameplay.render()
        } 

        Renderable.render()
    }

    static setState(state) {
        __state = state        
        if(state == GameState.menu) {
            Gameplay.reset()
        } else if(state == GameState.game) {
            System.print("setting game state")
            if(__scoreScreen != null) {
                __scoreScreen.delete()
                __scoreScreen = null
            }
            if(__mainMenu != null) {
                __mainMenu.delete()
                __mainMenu = null
            }
            Gameplay.reset()
            Gameplay.init()
            Gameplay.start()
        } else if(state == GameState.great) {
            System.print("Great!")
            //            Gameplay.reset()            
        } else if(state == GameState.score) {
            Gameplay.reset()
            __scoreScreen = Create.scoreScreen(Gameplay.score)
        }
     
    }

    static addShake(val) {
        __shakeIntesity = val
    }

    static version { "0.0.5" }
}

import "code/create" for Create
import "code/gameplay" for Gameplay
import "code/data" for Grid
import "code/hex" for HexCoordinate, HexGrid, HexTileComponent
