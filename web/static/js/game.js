import {Socket} from "phoenix"

let Game = {
  socket: null,
  channel: null,
  current: null,

  init() {
    console.log("Init!")
    if (!window.userId || window.userId === "" ) {
      alert("You don't have a user!")
      window.location.href = "/"
      return
    }
    Game.connect()
    Game.attachEvents()
    window.CurrentGame = this
  },

  attachEvents() {
    let quitEl = document.getElementById("quit")
    quitEl.onclick = Game.quit
    let readyEl = document.getElementById("ready")
    readyEl.onclick = Game.ready
    let startEl = document.getElementById("start")
    startEl.onclick = Game.start
    let restartEl = document.getElementById("restart")
    restartEl.onclick = Game.restart
    let doneEl = document.getElementById("done")
    doneEl.onclick = Game.done
  },

  connect() {
    Game.socket = new Socket("/socket", {params: {id: window.userId}})
    Game.socket.connect()

    // Connect to our lobby channel and call the join method
    let channel = Game.socket.channel('game:' + window.gameId)

    // We'll want to save this for later
    Game.channel = channel

    // Join fulfills promises on completion
    channel.onError(e => console.log("Channel error", e))
    channel.onClose(e => console.log("Channel closed", e))
    channel.join()
      .receive('ok', game => {
        console.log("Connected", game)
        Game.current = game
        Game.render()
        Game.playerJoin()
      })
      .receive('error', reply => {
        console.log(`Sorry, you can't join because ${reply.reason}`)
      })

      channel.on('game', game => {
        console.log("GAME!", game)
        Game.current = game
        Game.render()
      })

      channel.on('tick', game => {
        console.log("TICK!", game)
        Game.current = game
        Game.render()
      })

      channel.on('shutdown', _message => {
        console.log("SHUTDOWN!")
        Game.quit()
      })
  },

  playerJoin() {
    // They haven't joined so let's join them in
    Game.channel.push("player", {id: window.userId})
      .receive('ok', reply => {
        console.log("Player joined")
      })
      .receive('error', reply => {
        console.log(`Sorry, you can't join because ${reply.reason}`)
      })

  },

  playerReady() {
    // They haven't joined so let's join them in
    Game.channel.push("ready", {id: window.userId})
      .receive('ok', reply => {
        console.log("Player ready")
      })
      .receive('error', reply => {
        console.log(`Error ${reply.reason}`)
      })
  },

  isState(state) {
    return Game.current && Game.current.state == state
  },

  isReady() {
    if (!Game.isState('waiting')) {
      return false
    }

    for (var player of Game.current.players) {
       if (player.state !== "ready") {
         return false
       }
    }
    return true
  },

  render() {
    if (!Game.current) return
    console.log("Rendering", Game.current)
    Game.renderButtons()
    Game.renderTitle()
    Game.renderTime()
    Game.renderScore()
    Game.renderPlayers()
    Game.renderBananas()
  },

  renderButtons() {
    let readyEl = document.getElementById("ready")
    readyEl.className = Game.isState("waiting") ? "" : "hidden"
    let startEl = document.getElementById("start")
    startEl.className = Game.isReady() ? "" : "hidden"
    let restartEl = document.getElementById("restart")
    restartEl.className = Game.isState("done") ? "" : "hidden"

    let doneEl = document.getElementById("done")
    if (Game.isState("done")) {
      doneEl.className = ""
    } else {
      doneEl.className = "hidden"
    }
  },

  renderTitle() {
    let titleEl = document.getElementById("title")
    if (!Game.current) {
      titleEl.innerHTML = "Loading..."
    } else if (Game.current.state === "waiting") {
      if (Game.isReady()) {
        titleEl.innerHTML = "Press start!"
      } else {
        titleEl.innerHTML = "Waiting<br>for<br>players"
      }
    } else if (Game.current.state === "playing") {
      titleEl.innerHTML = ""
    } else if (Game.current.state === "done") {
      titleEl.innerHTML = "Game over!"
    }
  },

  renderTime() {
    let timeEl = document.getElementById("time")
    var seconds = Game.current.seconds
    if (seconds < 0) seconds = 0
    timeEl.innerHTML = ""+seconds
  },

  renderScore() {
    let scoreEl = document.getElementsByClassName('score-value')[0]
    var value = 0
    let player = Game.findPlayer(window.userId)
    if (player) {
      value = player.score
    }
    scoreEl.innerHTML = ""+value
  },

  renderPlayers() {
    // Pretty basic render function, maps each game object in the games message
    let ul = document.getElementById('players')
    ul.innerHTML = Game.current.players.map(player => Game.renderPlayer(player)).join('')
  },

  renderPlayer(player) {
    // Don't show yourself
    if (player.id == window.userId) return ''
    return `<li class="${player.state}"><span class="name">${player.name}</span><span class="score">${player.score}</span><span class="state ${player.state}"></span></li>`
  },

  findPlayer(id) {
    return Game.current.players.find(player => player.id === id)
  },

  renderBananas() {
    let bananasEl = document.getElementById("bananas")
    bananasEl.innerHTML = ''
    if (!Game.isState("playing") || !Game.current.x || !Game.current.y) {
      return
    }
    var el = document.createElement('img')
    el.setAttribute('src', '/images/banana-dance.gif')
    el.className = 'banana'
    el.style.left = '' + Game.current.x + '%'
    el.style.top = '' + Game.current.y + '%'
    el.onclick = Game.clickBanana
    bananasEl.appendChild(el)
  },

  clickBanana() {
    if (!Game.isState('playing')) {
      console.log("Not playing")
      return
    }
    let player = Game.findPlayer(window.userId)
    player.score = player.score || 0
    player.score += 1
    Game.renderScore()
    Game.channel.push("score", {score: player.score})
    .receive('ok', reply => {})
    .receive('error', reply => { console.log(`Error ${reply.reason}`) })
  },

  ready(e) {
    Game.playerReady()
  },

  start(e) {
    if (!Game.isReady()) {
      console.log("Couldn't start!")
      return
    }
    Game.channel.push("start", {})
    .receive('ok', reply => {
      console.log("Game started")
    })
    .receive('error', reply => {
      console.log(`Error ${reply.reason}`)
    })
  },

  restart(e) {
    if (!Game.isState('done')) {
      console.log("Couldn't restart!")
      return
    }
    Game.channel.push("restart", {})
      .receive('ok', reply => {
        console.log("Game restarted")
      })
      .receive('error', reply => {
        console.log(`Error ${reply.reason}`)
      })
  },

  quit(e) {
    window.location.href = "/lobby?name=" + window.userId
  },

  done(e) {
    if (!Game.isState('done')) {
      console.log("The game is not done!")
      return
    }
    Game.channel.push("done", {})
      .receive('ok', reply => {
        console.log("Game done")
      })
      .receive('error', reply => {
        console.log(`Error ${reply.reason}`)
      })
  }
}

export default Game
