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
