music = new RadMusic()
music.render(document.getElementById("music"))

midiBridge.init (midiAccess) ->
  input = midiAccess.getInput(midiAccess.enumerateInputs()[0])
  console.log "using #{input.deviceName}"
  input.addEventListener "midiMessage", (e) -> 
    if e.command is 144 # Note ON
      music.press(e.data1) # data1 = Key
    else if e.command is 128 # Note OFF
      music.unpress(e.data1)