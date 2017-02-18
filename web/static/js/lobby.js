import {Socket} from "phoenix"

let Lobby = {
  socket: null,
  channel: null,

  init() {
    Lobby.connect()
    Lobby.attachEvents()
  },

  // quitGame() {
  //   Game.lobby.push("quit_game", {id: window.userId, name: window.userId + "'s game"})
  //     .receive('ok', reply => {
  //       // If we successfully joined, we should have received a current
  //       // list of games to display
  //       console.log(reply)
  //     })
  //     .receive('error', reply => {
  //       // It is not the best user experience to just log errors...
  //       console.log("AHHHHHHHHHHHHH", reply)
  //     })
  // },

  attachEvents() {
    let startEl = document.getElementById("start")
    startEl.onclick = () => {
      Lobby.channel.push("start_game", {id: window.userId})
        .receive('ok', reply => {
          // If we successfully joined, we should have received a current
          // list of games to display
          console.log(reply)
          Lobby.renderGames(reply.games)
        })
        .receive('error', reply => {
          // It is not the best user experience to just log errors...
          console.log(`Sorry, you can't join because ${reply.reason}`)
        })
    }
  },

  connect() {
    Lobby.socket = new Socket("/socket", {params: {id: window.userId}})
    Lobby.socket.connect()
    console.log("connected!")

    // Connect to our lobby channel and call the join method
    let channel = Lobby.socket.channel('lobby')

    // Join fulfills promises on completion
    channel.join()
      .receive('ok', reply => {
        // If we successfully joined, we should have received a current
        // list of games to display
        console.log(reply)
        Lobby.renderGames(reply.games)
      })
      .receive('error', reply => {
        // It is not the best user experience to just log errors...
        console.log(`Sorry, you can't join because ${reply.reason}`)
      })

     // If we receive a push message with the key "games" we are getting
     // an update from the server about a change in the list of available
     // games and need to update the display
     channel.on('games', message => {
       Lobby.renderGames(message.games)
     })

     // We'll want to save this for later
     Lobby.channel = channel
  },

  renderGames(games) {
    console.log(games)
     // Pretty basic render function, maps each game object in the games message
     let ul = document.getElementById('games')
     ul.innerHTML = `
       <ul>
         ${games.map(game => `<li><a href="/game?name=${window.userId}&id=${game.id}" class="btn orange">Join ${game.id}'s game</a></li>`)}
       </ul>
     `
   },

}


export default Lobby