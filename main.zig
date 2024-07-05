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
