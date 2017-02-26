
let Slots = {

  init() {
    Slots.attachEvents()
  },

  attachEvents() {
    let othersEl = document.getElementById("others")
    othersEl.onclick = Slots.others
  }

}

export default Slots
