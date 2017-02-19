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

  },

  playerJoin() {
    // Check to see if the player has already joined
    if (Game.current && Game.current.players && Game.current.players.indexOf(window.userId) > -1) {
      return
    }
    // They haven't joined so let's join them in
    Game.channel.push("player", {id: window.userId})
      .receive('ok', reply => {
        Game.current = reply.game
        Game.render()
      })
      .receive('error', reply => {
        console.log(`Sorry, you can't join because ${reply.reason}`)
      })

  },

  render() {
    console.log("Rendering", this.current)

    // Pretty basic render function, maps each game object in the games message
    let ul = document.getElementById('players')
    ul.innerHTML = `
      ${this.current.players.map(player => Game.renderPlayer(player)).join('')}
    `
   },

   renderPlayer(player) {
     if (player == window.userId) return ''
     return `<li>${player}</li>`
   },

   quit(e) {
     window.location.href = "/lobby?name=" + window.userId
   }

}


export default Game
