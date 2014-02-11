DIAMETER = 700
INNER_DIAMETER = 150
NOTES = 84
NOTE_RADIUS = 8
WEB_STROKE = 4
PLAY_NOTE_RADIUS = 14
PLAY_STROKE = 7 # the width of the line that connects concurrently played notes
PLAY_COLOR = "#FD405E"
GROUP_PLAY_COLOR = "#A94DF0"
MAIN_COLOR = "#9ea2b8"
DIM_COLOR = "#494E6B"
NOTE_TRANSITION_DELAY = 100 # animates a line between closely played notes, delays note
                          # ideal for using with controller, but not for watching
NOTE_DECAY = 200

class RadMusic

  constructor: (@diameter = DIAMETER, @innerDiameter = INNER_DIAMETER, @notes = NOTES) ->
    @midiRefs = {} # reference map for accessing the svg element via midi note number
    @groupkeys = [] # briefly stores keys press for a time to determine whether to group keys in animation
    @animator = new Animator(PLAY_COLOR)
    @groupanimator = new Animator(GROUP_PLAY_COLOR)

  render: (el) ->
    @svg = document.createElementNS "http://www.w3.org/2000/svg", "svg"
    @svg.setAttribute "width", @diameter
    @svg.setAttribute "height", @diameter
    
    @drawNotes()
    @drawNoteLabels()

    el.appendChild @svg

    @update()

  # key: C is 0, C# is 1, etc... 
  # scale: "WWHWWWH" is major
  drawKey: (key, scale) ->
    for k, ref of @midiRefs
      ref.setAttribute "fill", DIM_COLOR
    count = 0
    for l in scale
      count += 2 if l is "W"
      count += 1 if l is "H"
      for i in [-1..6]
        @midiRefs[24+parseInt(key)+12*i+count]?.setAttribute "fill", MAIN_COLOR

  drawNotes: ->
    circles = document.createElementNS "http://www.w3.org/2000/svg", "g"
    lines = document.createElementNS "http://www.w3.org/2000/svg", "g"
    xx = yy = null # reference for previous node to make a line to connect to current node

    for i in [0..@notes]
      o = -1 * (Math.PI/6 * (i%12) - Math.PI)
      r = (@innerDiameter+i*(@diameter-70-@innerDiameter)/@notes)/2
      x = @diameter/2 + r*Math.sin(o)
      y = @diameter/2 + r*Math.cos(o)
      circle = document.createElementNS "http://www.w3.org/2000/svg", "circle"
      circle.setAttribute "r", NOTE_RADIUS
      circle.setAttribute "fill", MAIN_COLOR
      circle.setAttribute "cx", x 
      circle.setAttribute "cy", y
      circles.appendChild circle

      @midiRefs[i+24] = circle

      if xx
        line = document.createElementNS "http://www.w3.org/2000/svg", "line"
        line.setAttribute "x1", xx
        line.setAttribute "y1", yy
        line.setAttribute "x2", x
        line.setAttribute "y2", y
        line.setAttribute "stroke-width", WEB_STROKE
        line.setAttribute "stroke", DIM_COLOR
        lines.appendChild line
      xx = x
      yy = y

    @svg.appendChild lines
    @svg.appendChild circles

  drawNoteLabels: ->
    labels = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    for i in [0..labels.length-1]
      text = document.createElementNS "http://www.w3.org/2000/svg", "text"
      o = -1 * (Math.PI/6 * (i%12) - Math.PI)
      text.setAttribute "x", (@diameter)/2 + Math.sin(o)*(@diameter-30)/2
      text.setAttribute "y", (@diameter)/2 + Math.cos(o)*(@diameter-30)/2
      text.setAttribute "text-anchor", "middle"
      text.setAttribute "fill", DIM_COLOR
      text.textContent = labels[i]
      @svg.appendChild text


  press: (key) ->
    circle = @midiRefs[key]
    keypress =       
      key: key      
      x: parseInt circle.getAttribute "cx"
      y: parseInt circle.getAttribute "cy"
      pressedAt: Date.now()

    @groupkeys.push keypress
    delay = ->
      if @groupkeys.length is 1
        @animator.addKeyPress @groupkeys[0]
      else if @groupkeys.length > 1
        for keypress in @groupkeys
          @groupanimator.addKeyPress keypress
      @groupkeys = []
    setTimeout delay.bind(@), 40


  unpress: (key) ->
    @animator.removeKeyPress(key)
    @groupanimator.removeKeyPress(key)

  update: ->
    @_clear()
    @animator.update()
    @groupanimator.update()
    requestAnimationFrame(@update.bind(@))

  _clear: ->
    @svg.removeChild @animations if @animations
    @animations.innerHTML = "" if @animations
    @animations = document.createElementNS "http://www.w3.org/2000/svg", "g"
    @svg.appendChild @animations
    @animator.setLayerElement @animations
    @groupanimator.setLayerElement @animations



class Animator

  constructor: (@color = PLAY_COLOR) ->
    @keyPresses = {}

  addKeyPress: (keyPress) ->
    unless @keyPresses[keyPress.key]
      @keyPresses[keyPress.key] = keyPress

  removeKeyPress: (key) ->
    @keyPresses[key]?.unpressedAt = Date.now()

  update: ->
    now = Date.now()

    # Empty out-of-date items
    for key, keyPress of @keyPresses 
      delete @keyPresses[key] if now-keyPress.unpressedAt > NOTE_DECAY

    count = Object.keys(@keyPresses).length
    return "idle" if count is 0

    if count is 1
      for key, keyPress of @keyPresses    
        life = now - keyPress.pressedAt

        if life < 500
          @_drawGlowerAt keyPress.x, keyPress.y, 8+4*life/500, 1-life/500
        @_drawNoteAt keyPress.x, keyPress.y

    else
      for pressedKey, press of @keyPresses    
        life = now - press.pressedAt

        # Draw lines to connect to other currently pressed keys
        for otherKey, other of @keyPresses
          unless otherKey is pressedKey
            
            if life < NOTE_TRANSITION_DELAY
              x = other.x - (other.x - press.x)*life/NOTE_TRANSITION_DELAY
              y = other.y - (other.y - press.y)*life/NOTE_TRANSITION_DELAY
              @_drawNoteAt x, y
              @_drawLine other.x, other.y, x, y
            else if now - other.pressedAt >= NOTE_TRANSITION_DELAY
              @_drawLine other.x, other.y, press.x, press.y


        if NOTE_TRANSITION_DELAY <= life < 700
          @_drawGlowerAt press.x, press.y, PLAY_NOTE_RADIUS+8*(life-50)/500, 1-(life-50)/500
          @_drawNoteAt press.x, press.y

        if life >= 700
          @_drawNoteAt press.x, press.y

  setLayerElement: (svg) -> @svg = svg

  _drawGlowerAt: (x, y, size, opacity) ->
    @_drawCircle(x, y, size, opacity, "#fff")

  _drawNoteAt: (x, y, size = PLAY_NOTE_RADIUS, opacity = 1) ->
    @_drawCircle(x, y, size, opacity, @color)

  _drawCircle: (x, y, size, opacity, fill) ->
    circle = document.createElementNS "http://www.w3.org/2000/svg", "circle"
    circle.setAttribute "r", size
    circle.setAttribute "fill", fill
    circle.setAttribute "cx", x 
    circle.setAttribute "cy", y
    circle.setAttribute "fill-opacity", opacity
    @svg.appendChild circle

  _drawLine: (x1, y1, x2, y2) ->
    line = document.createElementNS "http://www.w3.org/2000/svg", "line"
    line.setAttribute "x1", x1
    line.setAttribute "y1", y1
    line.setAttribute "x2", x2
    line.setAttribute "y2", y2
    line.setAttribute "stroke-width", PLAY_STROKE
    line.setAttribute "stroke", @color
    line.setAttribute "stroke-opacity", "0.4"
    @svg.appendChild line


# since it's not componentized
window.RadMusic = RadMusic