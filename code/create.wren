import "xs" for Input, Render, Data, File, Audio
import "xs_ec"for Entity, Component
import "xs_math"for Math, Bits, Vec2
import "xs_components" for Transform, Body, Renderable, Sprite, GridSprite, AnimatedSprite, Relation, Label
import "xs_tools" for Tools
import "random" for Random

// This is a factory
class Create {

    static init() {
        __random = Random.new()

        /*
        __levels = [
            [ { EnemyType.basic : 4 }, { EnemyType.range : 2 } ],
            [ { EnemyType.basic : 5 }, { EnemyType.range : 3 } ]]
            */
    }

    static obstacles() {
        var grid = Gameplay.grid                
        var hexes = grid.getFreeHexesInRange(HexCoordinate.new(0, 0), 2)
        var randHex = null
        while (randHex == null) {
            var randIndex = __random.int(0, hexes.count)
            var hex = hexes[randIndex]
            if (hex.q != 0 && hex.r != 0 && grid.getTileAt(hex) == null) {
                randHex = hex
            }            
        }        
        
        var obstacles = []
        obstacles.add(Create.obstacle(randHex))
        obstacles.add(Create.obstacle(HexCoordinate.new(randHex.q, randHex.s)))
        obstacles.add(Create.obstacle(HexCoordinate.new(-randHex.q, -randHex.r)))
        obstacles.add(Create.obstacle(HexCoordinate.new(-randHex.q, -randHex.s)))        
        return obstacles
    }

    static obstacle(hex) {
        var grid = Gameplay.grid
        var e = Entity.new()
        var t = Transform.new(grid.getPosition(hex))
        var h = HexTileComponent.new(hex, grid)
        var s = Sprite.new("[game]/assets/images/generated/filled_hexagon.png")
        s.layer = 1
        s.flags = Render.spriteCenter
        s.mul = Data.getColor("Color Obstacle")
        e.addComponent(t)
        e.addComponent(h)
        e.addComponent(s)
        e.tag = Tag.obstacle
        return e
    }

    static findEmptyHex() {
        var grid = Gameplay.grid
        var hex = grid.getRandomHex(__random)
        while(grid.getTileAt(hex) != null) {
            hex = grid.getRandomHex(__random)
        }
        return hex
    }

    static player() {        
        var e = Entity.new()
        var t = Transform.new(Vec2.new(0, 0))
        var gs = Gameplay.grid.gridSize
        var h = HexTileComponent.new(HexCoordinate.new(0, gs-1), Gameplay.grid)
        var p = Player.new()
        var s = AnimatedSprite.new("[game]/assets/images/generated/player.png", 60, 1, 60)
        var anim = Tools.rangeToList(0..59) + Tools.rangeToList(59..0)
        s.addAnimation("idle", anim)
        s.playAnimation("idle")
        s.layer = 1
        s.flags = Render.spriteCenter
        s.mul = Data.getColor("Color Player")
        e.addComponent(t)
        e.addComponent(h)
        e.addComponent(p)
        e.addComponent(s)
        e.tag = Tag.player
        return e
    }

    static enemies(amount) {   
        System.print("Creating " + amount.toString + " enemies")    
        var playerHex = HexCoordinate.new(0, 3) 
        var half = (amount / 2).floor
        var count = 0        
        var enemyHexes = []

        if(amount % 2 == 1) {
            // Place in the middle
            var hex = HexCoordinate.new(0, __random.int(-3, 0))
            enemyHexes.add(hex)
        }
        while (count < half) {
            var q = __random.int(-Gameplay.gridSize + 1, 0)
            var s = __random.int(0, Gameplay.gridSize)
            var r = -q - s
            var hex = HexCoordinate.new(q, r)
            var duplicate = false
            for(ehx in enemyHexes) {
                if(ehx == hex) {
                    duplicate = true
                    continue
                }
            }
            if(Gameplay.grid.getTileAt(hex) == null && !duplicate) {
                enemyHexes.add(hex)
                enemyHexes.add(HexCoordinate.new(-q, -hex.s))
                count = count + 1
            }                   
        }

        var enemies = []
        count = 0
        var doubleOnes = amount - Data.getNumber("Level Advanced Enemies") - 2
        System.print("Double ones: " + doubleOnes.toString)
        for(hex in enemyHexes) {
            if(count < doubleOnes) {
                var types = [EnemyType.stealth, EnemyType.explode]
                if(Gameplay.level >= Data.getNumber("Level Extra Range")) {
                    types.add(EnemyType.range)
                }
                var type = types[__random.int(0, types.count)]
                var enemy = Create.enemy(hex, type)
                enemies.add(enemy)
            } else {
                var enemy = Create.enemy(hex, EnemyType.basic)
                enemies.add(enemy)
            }
            count = count + 1
        }

        return enemies
    }
    
    static enemy(hex, type) {
        var e = Entity.new()
        var t = Transform.new(Vec2.new(0, 0))
        var h = HexTileComponent.new(hex, Gameplay.grid)
        var en = Enemy.new(type)
        var range = en.range
        var s = null        
        var frames = 60
        var fps = 60        
        if(type == EnemyType.basic) {
            var anim = Tools.rangeToList(0...60)
            s = AnimatedSprite.new("[game]/assets/images/generated/basic.png", frames, 1, fps)
            s.addAnimation("idle", anim)
            s.playAnimation("idle")
            s.mul = Data.getColor("Color Enemy Basic")
        } else if(type == EnemyType.range) {
            var anim = Tools.rangeToList(0...60)
            s = AnimatedSprite.new("[game]/assets/images/generated/range.png", 60, 1, 60)
            s.addAnimation("idle", anim)
            s.playAnimation("idle")
            s.mul = Data.getColor("Color Enemy Range")
        } else if(type == EnemyType.stealth) {
            var anim = Tools.rangeToList(0...frames)
            s = AnimatedSprite.new("[game]/assets/images/generated/stealth.png", frames, 1, fps)
            s.addAnimation("idle", anim)
            s.playAnimation("idle")
            s.mul = Data.getColor("Color Enemy Stealth")
            var st = Stealth.new()
            e.addComponent(st)
        } else if(type == EnemyType.explode) {
            var anim = Tools.rangeToList(0...frames)
            s = AnimatedSprite.new("[game]/assets/images/generated/explode.png", frames, 1, fps)
            s.addAnimation("explode", anim)
            s.playAnimation("explode")
            s.mul = Data.getColor("Color Enemy Explode")            
        } else if(type == EnemyType.split) {
            var anim = Tools.rangeToList(0...frames)
            s = AnimatedSprite.new("[game]/assets/images/generated/basic.png", frames, 1, fps)
            s.mul = Data.getColor("Color Enemy Split")
        }

        s.flags = Render.spriteCenter
        e.addComponent(t)
        e.addComponent(h)        
        e.addComponent(en)        
        e.tag = Tag.enemy

        e.addComponent(s)

        return e
    }

    static explosion(hex, color) {
        var e = Entity.new()
        var t = Transform.new(Gameplay.grid.getPosition(hex))
        var s = AnimatedSprite.new("[game]/assets/images/generated/explosion.png", 16, 1, 60)
        s.addAnimation("explode", Tools.rangeToList(0..15))
        s.playAnimation("explode")
        s.layer = 1
        s.flags = Render.spriteCenter
        s.mul = color
        s.mode = AnimatedSprite.destroy
        e.addComponent(t)
        e.addComponent(s)
        Game.addShake(Data.getNumber("Shake Explosion"))
        return e
    }

    static scoreScreen(score) {
        var screen = null
        {
            var e = Entity.new()
            var t = Transform.new(Vec2.new(0, 0))
            var s = Sprite.new("[game]/assets/images/generated/big_bar.png")
            s.layer = 1
            s.flags = Render.spriteCenter
            s.mul = Data.getColor("Color UI")
            e.addComponent(t)
            e.addComponent(s)
            screen = e
        }

        {
            var e = Entity.new()
            var t = Transform.new(Vec2.new(0, 0))
            var l = Label.new("[game]/assets/fonts/cyberspace.ttf", "SCORE: " + score.toString, 32)
            var r = Relation.new(screen)
            l.layer = 1.1
            l.flags = Render.spriteCenter
            l.mul = Data.getColor("Color Player")
            e.addComponent(t)
            e.addComponent(l)
            e.addComponent(r)
        }
        return screen
    }

    static greatScreen() {
        var screen = null
        {
            var e = Entity.new()
            var t = Transform.new(Vec2.new(0, 0))
            var s = Sprite.new("[game]/assets/images/generated/big_bar.png")
            s.layer = 1
            s.flags = Render.spriteCenter
            s.mul = Data.getColor("Color UI")
            e.addComponent(t)
            e.addComponent(s)
            screen = e
        }

        {
            var e = Entity.new()
            var t = Transform.new(Vec2.new(0, 0))
            var l = Label.new("[game]/assets/fonts/cyberspace.ttf", "Level " + (Gameplay.level + 2).toString, 32)
            var r = Relation.new(screen)
            l.layer = 1.1
            l.flags = Render.spriteCenter
            l.mul = Data.getColor("Color Player")
            e.addComponent(t)
            e.addComponent(l)
            e.addComponent(r)
        }
        return screen
    }

    static background() {
        
        var w = Data.getNumber("Width", Data.system) / 2
        var h = Data.getNumber("Height", Data.system) / 2

        {   // Bottom label
            var e = Entity.new()
            var t = Transform.new(Vec2.new(700, -h + 16))
            var l = Label.new("[game]/assets/fonts/cyberspace.ttf", "hexturn v" + Game.version.toString, 16)
            l.layer = -1.0
            l.flags = Render.spriteCenter
            l.mul = Data.getColor("Color UI")
            e.addComponent(t)
            e.addComponent(l)
        }

        // Draw a stack of levels (25 in total)
        var y = -h + 280
        var x = w - 170
        for(i in 0..25) {
            var e = Entity.new()
            var t = Transform.new(Vec2.new(x, y))
            var s = Sprite.new("[game]/assets/images/generated/level.png")
            s.layer = 0.0
            s.flags = Render.spriteCenter
            if(i <= Gameplay.level) {
                s.mul = Data.getColor("Color Player")
            } else {
                s.mul = Data.getColor("Color UI")
            }
            e.addComponent(t)
            e.addComponent(s)
            y = y + 20
        } 
    }

    static mainMenu() {
        var mainMenu = Entity.new()
        { // Main menu
            var t = Transform.new(Vec2.new(0,0))
            var mm = MainMenu.new()
            var imgui = ImGui.new(null, 16)
            imgui.layer = 12.0
            mainMenu.name = "Main Menu"
            mainMenu.addComponent(t)
            mainMenu.addComponent(mm)
            mainMenu.addComponent(imgui)
        }
        return mainMenu        
    }

    static pingLabel(pos) {
        var e = Entity.new()
        var t = Transform.new(pos)
        var l = PingLabel.new("[game]/assets/fonts/cyberspace.ttf", " ", 40, 40, 0.2)
        l.layer = 2.1
        l.flags = Render.spriteCenter
        l.mul = Data.getColor("Color Player")
        e.addComponent(t)
        e.addComponent(l)
        return e
    }
}

import "game" for Game
import "code/tags" for Tag
import "code/hex" for HexCoordinate, HexTileComponent
import "code/ui" for ImGui, MainMenu, PingLabel
import "code/gameplay" for Gameplay
import "code/player" for Player
import "code/enemy" for Enemy, EnemyType, Stealth