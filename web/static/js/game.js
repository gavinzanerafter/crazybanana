import {Socket} from "phoenix"

let Game = {
  socket: null,
  lobby: null,

  init() {
    Game.connect()
    Game.attachEvents()
    window.TheGame = this
  },

  quitGame() {
    Game.lobby.push("quit_game", {id: window.userId, name: window.userId + "'s game"})
      .receive('ok', reply => {
        // If we successfully joined, we should have received a current
        // list of games to display
        console.log(reply)
      })
      .receive('error', reply => {
        // It is not the best user experience to just log errors...
        console.log("AHHHHHHHHHHHHH", reply)
      })
  },

  attachEvents() {
    let startEl = document.getElementById("start")
    startEl.onclick = () => {
      Game.lobby.push("start_game", {id: window.userId, name: window.userId + "'s game"})
        .receive('ok', reply => {
          // If we successfully joined, we should have received a current
          // list of games to display
          console.log(reply)
          Game.renderGames(reply.games)
        })
        .receive('error', reply => {
          // It is not the best user experience to just log errors...
          console.log(`Sorry, you can't join because ${reply.reason}`)
        })
    }
  },

  connect() {
    Game.socket = new Socket("/socket", {params: {id: window.userId}})
    Game.socket.connect()
    console.log("connected!")

    // Connect to our lobby channel and call the join method
    let lobby = Game.socket.channel('lobby')

    // Join fulfills promises on completion
    lobby.join()
      .receive('ok', reply => {
        // If we successfully joined, we should have received a current
        // list of games to display
        console.log(reply)
        Game.renderGames(reply.games)
      })
      .receive('error', reply => {
        // It is not the best user experience to just log errors...
        console.log(`Sorry, you can't join because ${reply.reason}`)
      })

     // If we receive a push message with the key "games" we are getting
     // an update from the server about a change in the list of available
     // games and need to update the display
     lobby.on('games', message => {
       Game.renderGames(message.games)
     })

     // We'll want to save this for later
     Game.lobby = lobby
  },

  renderGames(games) {
    console.log(games)
     // Pretty basic render function, maps each game object in the games message
    //  let ul = document.getElementById('games')
    //  ul.innerHTML = `
    //    <ul>
    //      ${games.map(game => `<li><a href="/play?id=${game.id}" class="btn orange">Join ${game.id}</a></li>`)}
    //    </ul>
    //  `
   },

}


export default Game
