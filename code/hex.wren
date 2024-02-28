import "xs_math" for Vec2
import "xs_ec"for Entity, Component
import "xs_components" for Transform
import "xs_math" for Bits, Math

class HexCoordinate {

    construct new(q, r) {
        _q = q
        _r = r
    }

    construct new(x, y, z) {
        _q = x
        _r = z
    }

    construct new(hex) {
        _q = hex.q
        _r = hex.r
    }

    construct fromOffset(col, row) {
        _q = col
        _r = row - (col - (col & 1)) / 2
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
}

class HexTileComponent is Component {

    construct new(tile, grid) {
        _tile = tile
        _grid = grid
        _direction = -1
        _grid.setTileAt(_tile, this)        
    }

    initialize() {        
        _transform = owner.getComponent(Transform)
        var position = _grid.getPosition(_tile)
        _transform.position = position
    }

    tile { _tile }
    
    direction { _direction }

    direction=(value) { _direction = value }

    rotate=(value) { _direction = (_direction + value) % 6 }

    move(direction) {
        var tile = _tile + HexCoordinate.direction(direction)
        return moveTo(tile)
    }

    moveTo(tile) {
        var temp = _grid.getTileAt(tile)
        _grid.setTileAt(_tile, null)
        _tile.q = tile.q
        _tile.r = tile.r
        _grid.setTileAt(_tile, this)
        return temp
    }

    update(dt) {
        var position = _grid.getPosition(_tile)
        _transform.position = Math.damp(_transform.position, position, dt, 20.1)
        if(Vec2.distance(_transform.position, position) < 0.1) {
            _transform.position = position
        }
    }

    canMove(direction) {
        var tile = _tile + HexCoordinate.direction(direction)
        return _grid.isValid(tile) && _grid.getTileAt(tile) == null 
    }

    canMove(direction, tag) {
        var hex = _tile + HexCoordinate.direction(direction)
        var tile = _grid.getTileAt(hex)        
        return  _grid.isValid(hex) &&
                (tile == null || Bits.checkBitFlagOverlap(tile.owner.tag, tag))
    }

    canMoveTo(hex) {
        return _grid.isValid(hex) && _grid.getTileAt(hex) == null 
    }

    canMoveTo(hex, tag) {
        var tile = _grid.getTileAt(hex)        
        return  _grid.isValid(hex) &&
                (tile == null || Bits.checkBitFlagOverlap(tile.owner.tag, tag))
    }
}

class HexGrid {

    construct new(hexSize, gridSize) {
        _hexSize = hexSize
        _gridSize = gridSize
        _origin = HexCoordinate.new(0, 0)
        _grid = Grid.new(gridSize * 2 + 1, gridSize * 2 + 1, null)
    }

    hexSize { _hexSize }

    gridSize { _gridSize }

    getPosition(tile) {
        return tile.getPosition(_hexSize)
    }

    getHex(position) {
        var q = position.x * 2.0 / 3.0 / _hexSize
	    var r = (-position.x / 3.0 + 3.sqrt / 3.0 * position.y) / _hexSize

	    var cx = q
	    var cz = r
	    var cy = -cx-cz

	    var rx = cx.round
	    var ry = cy.round
	    var rz = cz.round

	    var x_diff = (rx - cx).abs
	    var y_diff = (ry - cy).abs
	    var z_diff = (rz - cz).abs

	    if ((x_diff > y_diff) && (x_diff > z_diff)) {
		    rx = -ry - rz
        } else if (y_diff > z_diff) {
		    ry = -rx - rz
        } else {
		    rz = -rx - ry
        }

	    return HexCoordinate.new(rx, ry)
    }

    getTileAt(hex) {
        return _grid[hex.x + _grid.width / 2, hex.y + _grid.height / 2]
    }

    setTileAt(hex, tile) {
        _grid[hex.x + _grid.width / 2, hex.y + _grid.height / 2] =  tile
    }

    getRandomHex(random) {
        while (true) {
            var sz = _gridSize + 1
            var x = random.int(-sz, sz)
            var y = random.int(-sz, sz)
            var hex = HexCoordinate.new(x, y)    
            if(HexCoordinate.distance(hex, _origin) >= _gridSize) {
                continue
            }
            if(getTileAt(hex) != null) {
                continue
            }
            return hex
        }
    }

    isValid(hex) {
        return HexCoordinate.distance(_origin, hex) < _gridSize
    }

    getHexesInRange(hex, range) {
        var hexes = []
        for(x in -range..range) {
            for(y in -range..range) {
                for(z in -range..range) {
                    var h = HexCoordinate.new(x, y, z) + hex
                    if(HexCoordinate.distance(hex, h) <= range && isValid(h)) {
                        hexes.add(h)
                    }
                }
            }
        }
        return hexes
    }

    getFreeHexesInRange(hex, range) {
        var hexes = []
        for(x in -range..range) {
            for(y in -range..range) {
                for(z in -range..range) {
                    var h = HexCoordinate.new(x, y, z) + hex
                    if(HexCoordinate.distance(hex, h) <= range && isValid(h) && getTileAt(h) == null) {
                        hexes.add(h)
                    }
                }
            }
        }
        return hexes
    }

    getNeighbors(hex) {
        var neighbors = []
        for(direction in 0..5) {
            var neighbor = hex + HexCoordinate.direction(direction)
            if(isValid(neighbor)) {
                neighbors.add(neighbor)
            }
        }
        return neighbors
    }

    cleanUp() {
        for(x in 0..._grid.width) {
            for(y in 0..._grid.height) {
                var tile = _grid[x, y]        
                if(tile != null) {
                    if(tile.owner.deleted) {
                        _grid[x, y] = null
                    }
                }
            }
        }
    }
    

    /*
    getHexAt(position) {
        var tile = getHex(position)
        return _grid.get(tile.x + _size, tile.y + _size)
    }

    setTileAt(position, tile) {
        var tile = getHex(position)
        _grid.set(tile.x + _size, tile.y + _size, tile)
    }
    */
}

import "code/data" for Grid
