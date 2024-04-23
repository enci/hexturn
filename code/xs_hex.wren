import "xs_math" for Vec2
import "xs_ec"for Entity, Component
import "xs_components" for Transform
import "xs_math" for Bits, Math

class HexCoordinate {

    static flatTop { 0 }
    static pointyTop { 1 }

    static orientation { __orientation ? __orientation : flatTop }
    static orientation=(value) { __orientation = value }

    construct new(q, r) {
        _q = q
        _r = r
    }

    construct new(x, y, z) {
        _q = x
        _r = z        
    }

    construct copy(hex) {
        _q = hex.q
        _r = hex.r
    }

    setOffset(col, row) {
        if(HexCoordinate.orientation == HexCoordinate.flatTop) {
            _q = col
            _r = row - (col + (col & 1)) / 2
        } else {
            _q = col - (row + (row & 1)) / 2
            _r = row
        }
    }

    q=(value) { _q = value }
    q { _q }
    r=(value) { _r = value }
    r { _r }
    s { -q-r }

    x=(value) { _q = value }
    x { _q }
    z=(value) { _r = value }
    z { _r }
    y { -x-z }

    +(other) { HexCoordinate.new(x + other.x, y + other.y, z + other.z) }
    -(other) { HexCoordinate.new(x - other.x, y - other.y, z - other.z) }

    ==(other) { (other != null && q == other.q && r == other.r) }

    static distance(a, b) {
        return ((a.q - b.q).abs  + (a.q + a.r - b.q - b.r).abs + (a.r - b.r).abs) / 2.0
    }

    /*
    static direction(direction) {
        if(__directions == null) {
            __directions = [
            HexCoordinate.new(1, 0, -1),
            HexCoordinate.new(1, -1, 0),
            HexCoordinate.new(0, -1, 1),
            HexCoordinate.new(-1, 0, 1),
            HexCoordinate.new(-1, 1, 0),
            HexCoordinate.new(0, 1, -1)]
        }
        return __directions[direction % 6]
    }

    rotateClockwise() {        
        var x = -z
        var y = -x-z
        var z = -y
        return HexCoordinate.new(x, y, z)
    }

    getNeighbors() {
        var neighbors = []
        for(direction in 0..5) {
            neighbors.add(this + HexCoordinate.direction(direction))
        }
        return neighbors
    }

    getNeighbor(direction) {
        return this + HexCoordinate.direction(direction)
    }

    hash { q + r * 100000 }

    toString { "[" + q.toString + ", " + r.toString + "]" }

    getPosition(hexSize) {
        var v = Vec2.new(0, 0)
        v.x = hexSize * (3.0 / 2.0 * _q)
        v.y = hexSize * (3.sqrt * (_r + _q / 2.0))
        return v
    }
    */

    toPoint(hexSize) {
        var v = Vec2.new(0, 0)
        if(HexCoordinate.orientation == HexCoordinate.flatTop) {            
            v.x = hexSize * (3.0 / 2.0 * _q)
            v.y = hexSize * (3.sqrt * (_r + _q / 2.0))        
        } else {
            v.x = hexSize * (3.sqrt * (_q + _r / 2.0))
            v.y = hexSize * (3.0 / 2.0 * _r)
        }
        return v        
    }
}