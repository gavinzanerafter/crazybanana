// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
import "phoenix_html"

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

// import socket from "./socket"

import Lobby from "./lobby.js"
import Game from "./game.js"
import Slots from "./slots.js"

let lobbyEl = document.getElementById('lobby')
if (lobbyEl) {
  Lobby.init()
}

let gameEl = document.getElementById('game')
if (gameEl) {
  Game.init()
}

let circlesEl = document.getElementById('circles')
if (circlesEl) {
  Slots.init()
}
