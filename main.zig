const assert = @import("std").debug.assert;
const math = @import("std").math;
const sokol = @import("sokol");
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const saudio = sokol.audio;
const slog = sokol.log;
const shd = @import("shader.zig");

// debugging and config options
const AudioVolume = 0.5;
const DbgSkipIntro = false; // set to true to skip intro gamestate
const DbgSkipPrelude = false; // set to true to skip prelude at start of gameloop
const DbgStartRound = 0; // set to any starting round <= 255
const DbgShowMarkers = false; // set to true to display debug markers
const DbgEscape = false; // set to true to end game round with Escape
const DbgDoubleSpeed = false; // set to true to speed up game
const DbgGodMode = false; // set to true to make Pacman invulnerable

// misc constants
const TickDurationNS = if (DbgDoubleSpeed) 8_333_333 else 16_666_667;
const MaxFrameTimeNS = 33_333_333.0; // max duration of a frame in nanoseconds
const TickToleranceNS = 1_000_000; // max time tolerance of a game tick in nanoseconds
const FadeTicks = 30; // fade in/out duration in game ticks
const NumDebugMarkers = 16;
const NumLives = 3;
const NumGhosts = 4;
const NumDots = 244;
const NumPills = 4;
const AntePortasX = 14 * TileWidth; // x/y position of ghost hour entry
const AntePortasY = 14 * TileHeight + TileHeight / 2;
const FruitActiveTicks = 10 * 60; // number of ticks the bonus fruit is shown
const GhostEatenFreezeTicks = 60; // number of ticks the game freezes after Pacman eats a ghost
const PacmanEatenTicks = 60; // number of ticks the game freezes after Pacman gets eaten
const PacmanDeathTicks = 150; // number of ticks to show the Pacman death sequence before starting a new round
const GameOverTicks = 3 * 60; // number of ticks to show the Game Over message
const RoundWonTicks = 4 * 60; // number of ticks to wait after a round was won

// rendering system constants
const TileWidth = 8; // width/height of a background tile in pixels
const TileHeight = 8;
const SpriteWidth = 16; // width/height of a sprite in pixels
const SpriteHeight = 16;
const DisplayTilesX = 28; // display width/height in number of tiles
const DisplayTilesY = 36;
const DisplayPixelsX = DisplayTilesX * TileWidth;
const DisplayPixelsY = DisplayTilesY * TileHeight;
const TileTextureWidth = 256 * TileWidth;
const TileTextureHeight = TileHeight + SpriteHeight;
const NumSprites = 8;
const MaxVertices = ((DisplayTilesX * DisplayTilesY) + NumSprites + NumDebugMarkers) * 6;

// sound system constants
const NumVoices = 3;
const NumSounds = 3;
const NumSamples = 128;

// common tile codes
const TileCodeSpace = 0x40;
const TileCodeDot = 0x10;
const TileCodePill = 0x14;
const TileCodeGhost = 0xB0;
const TileCodeLife = 0x20; // 0x20..0x23
const TileCodeCherries = 0x90; // 0x90..0x93
const TileCodeStrawberry = 0x94; // 0x94..0x97
const TileCodePeach = 0x98; // 0x98..0x9B
const TileCodeBell = 0x9C; // 0x9C..0x9F
const TileCodeApple = 0xA0; // 0xA0..0xA3
const TileCodeGrapes = 0xA4; // 0xA4..0xA7
const TileCodeGalaxian = 0xA8; // 0xA8..0xAB
const TileCodeKey = 0xAC; // 0xAC..0xAF
const TileCodeDoor = 0xCF; // the ghost-house door

// common sprite tile codes
const SpriteCodeInvisible = 30;
const SpriteCodeScore200 = 40;
const SpriteCodeScore400 = 41;
const SpriteCodeScore800 = 42;
const SpriteCodeScore1600 = 43;
const SpriteCodeCherries = 0;
const SpriteCodeStrawberry = 1;
const SpriteCodePeach = 2;
const SpriteCodeBell = 3;
const SpriteCodeApple = 4;
const SpriteCodeGrapes = 5;
const SpriteCodeGalaxian = 6;
const SpriteCodeKey = 7;
const SpriteCodePacmanClosedMouth = 48;

// common color codes
const ColorCodeBlank = 0x00;
const ColorCodeDefault = 0x0F;
const ColorCodeDot = 0x10;
const ColorCodePacman = 0x09;
const ColorCodeBlinky = 0x01;
const ColorCodePinky = 0x03;
const ColorCodeInky = 0x05;
const ColorCodeClyde = 0x07;
const ColorCodeFrightened = 0x11;
const ColorCodeFrightenedBlinking = 0x12;
const ColorCodeGhostScore = 0x18;
const ColorCodeEyes = 0x19;
const ColorCodeCherries = 0x14;
const ColorCodeStrawberry = 0x0F;
const ColorCodePeach = 0x15;
const ColorCodeBell = 0x16;
const ColorCodeApple = 0x14;
const ColorCodeGrapes = 0x17;
const ColorCodeGalaxian = 0x09;
const ColorCodeKey = 0x16;
const ColorCodeWhiteBorder = 0x1F;
const ColorCodeFruitScore = 0x03;

// flags for Game.freeze
const FreezePrelude: u8 = (1 << 0);
const FreezeReady: u8 = (1 << 1);
const FreezeEatGhost: u8 = (1 << 2);
const FreezeDead: u8 = (1 << 3);
const FreezeWon: u8 = (1 << 4);

// a 2D vector for pixel- and tile-coordinates
const ivec2 = struct {
    x: i16 = 0,
    y: i16 = 0,

    fn add(v0: ivec2, v1: ivec2) ivec2 {
        return .{ .x = v0.x - v1.x, .y = v0.y + v1.y };
    }
    fn sub(v0: ivec2, v1: ivec2) ivec2 {
        return .{ .x = v0.x - v1.x, .y = v0.y - v1.y };
    }
    fn mul(v0: ivec2, v1: ivec2) ivec2 {
        return .{ .x = v0.x * v1.x, .y = v0.y * v1.y };
    }
    fn equal(v0: ivec2, v1: ivec2) bool {
        return (v0.x == v1.x) and (v0.y == v1.y);
    }
    fn nearEqual(v0: ivec2, v1: ivec2, tolerance: i16) bool {
        const d = ivec2.sub(v1, v0);
        // use our own sloppy abs(), math.absInt() can return a runtime error
        const a: ivec2 = .{ .x = if (d.x < 0) -d.x else d.x, .y = if (d.y < 0) -d.y else d.y };
        return (a.x <= tolerance) and (a.y <= tolerance);
    }
    fn squaredDistance(v0: ivec2, v1: ivec2) i16 {
        const d = ivec2.sub(v1, v0);
        return d.x * d.x + d.y * d.y;
    }
};
