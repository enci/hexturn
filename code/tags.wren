class Tag {
    static player           { 1 << 1 }
    static enemy            { 1 << 2 }
    static obstacle         { 1 << 3 }
    static powerUp          { 1 << 4 }
}

class Team {
    static Player { 1 }
    static Computer { 2 }
}

class PowerUps {
    static none     { -1 }
    static range    { 0 }
    static turn     { 1 }
    static jump     { 2 }
    static decoy    { 3 }
}