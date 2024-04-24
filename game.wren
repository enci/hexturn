import "xs" for Input, Render, Data
import "xs_math" for Vec2, Math
import "xs_ec"for Entity, Component
import "xs_components" for Renderable
import "xs_shapes" for Shapes, Shape, ShapeRenderer, Font, FontRenderer
import "random" for Random

class Game {

    static init() {    
        Entity.init()
        Gameplay.init()

        var w = 1920 / 2
        var h = 1080 / 2        
        __shape = Shapes.quad(
            Vec2.new(-w, -h),
            Vec2.new(w, -h),
            Vec2.new(w, h),
            Vec2.new(-w, h),            
            0x2F2F2FFF)

        HexCoordinate.orientation = HexCoordinate.pointyTop

        __hexSize = 72
        var hexPoints = Shapes.polygon(Vec2.new(0,0), __hexSize * 0.96, 6, 10, 2)
        __hexOutline = Shapes.stroke(hexPoints, 1, 0xFFFFFFFF)

        __font = Font.load("[game]/assets/fonts/Miracode.txt")


        __player = Create.player()
    }

    static config() { }
    
    static update(dt) {
        Entity.update(dt)        
    }

    static render() {
        __shape.render(Vec2.new(0, 0), 1.0, 0.0)                        

        var rot = 30.0 * Math.pi / 180.0
        var origin = HexCoordinate.new(0, 0)
        var hex = HexCoordinate.new(0, 0)
        var range = 4
        for(q in -range..range) {
            for(r in Math.max(-range, -q-range)..Math.min(range, -q+range)) {
                hex.q = q
                hex.r = r
                var pos = hex.getPosition(__hexSize)
                __hexOutline.render(pos, 1.0, rot, 0x000000FF, 0x00000000)
            }
        }

        //Shapes.renderText("Hello World", __font, Vec2.new(0, 0), 1.0, 0.0, 0xFFFFFFFF, 0x00000000)

        var player = __player.getComponent(Player)
        


        Shapes.renderText("Hello World asdf asd flkjahsdfkljh lkajhsdlkfjhasldkj asdlfkjhasdlkjh ", __font, Vec2.new(100, 100), 20.0)

        Shapes.render()
        
        /*
        for (x in -9..9) {
            for(y in -5..5) {
                hex.setOffset(x, y)
                var pos = hex.toPoint(__hexSize)
                /*
                if(HexCoordinate.distance(hex, origin) < 5) {
                    //__hexOutline.render(pos, 1.0, rot, 0x00000000, 0xFF0000FF)
                } else {
                    // __hexOutline.render(pos, 1.0, rot, 0x00000000, 0xFF0000FF)
                }
                */
            }            
        } 
        */       
    }

    font { __font }
}

/*

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

        {   // White backdrop
            var w = 1920 / 2
            var h = 1080 / 2
            __backdrop = Shapes.rectangle(Vec2.new(-w, -h), Vec2.new(w, h), 0xFFFFFFFF)            
        }

        {
            var hexPoints = Shapes.polygon(Vec2.new(0,0), 50, 6, 14, 8)
            __hexOutline = Shapes.stroke(hexPoints, 1.5, 0x000000FF)
        }

        {
            var hexPoints = Shapes.polygon(Vec2.new(0,0), 50, 6, 14, 8)
            __hexFilled = Shapes.fill(hexPoints, Data.getColor("Color Inactive Tile")) 
        }

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

        /*
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
        } else
        Renderable.render()
        */

        // Render backdrop        
        {
            var bgColor = Data.getColor("Color Background")
            __backdrop.render(Vec2.new(0, 0), 1.0, 0.0, 0x000000FF, bgColor)
        }

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
                     __hexOutline.render(pos, 1.0, 0.0, 0x000000FF, activeColor)
                } else {
                    var dist = HexCoordinate.distance(tile, origin)
                    var size = Math.remap(Gameplay.gridSize, 9.0, 1.0, 0.2, dist) * beatSize
                    __hexFilled.render(pos, size, 0.0)
                    //Render.sprite(__filledSprite, pos.x, pos.y, 0.0, size, 0.0, inactiveColor, 0x0, Render.spriteCenter)
                }
            }
        }

        Shapes.render()

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
*/

import "code/gameplay" for Gameplay
import "code/create" for Create
import "code/data" for Grid
import "code/xs_hex" for HexCoordinate /*, HexGrid, HexTileComponent*/
