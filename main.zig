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
