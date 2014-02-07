RADIUS = 750
INNER_RADIUS = 150
NOTES = 60

PLAY_NOTE_RADIUS = 14
PLAY_STROKE = 7
PLAY_COLOR = "#FD405E"
NOTE_RADIUS = 8
WEB_STROKE = 4

GLOW = 300
FADE = 200


class RadMusic

  constructor: (@radius = RADIUS, @innerRadius = INNER_RADIUS, @notes = NOTES) ->
    @midiRefs = {}
    @animator = new Animator()

  render: (el) ->
    @svg = document.createElementNS "http://www.w3.org/2000/svg", "svg"
    @svg.setAttribute "width", @radius
    @svg.setAttribute "height", @radius

    circles = document.createElementNS "http://www.w3.org/2000/svg", "g"
    lines = document.createElementNS "http://www.w3.org/2000/svg", "g"

    xx = yy = null

    for i in [0..@notes]
      o = -1 * (2*Math.PI/12 * (i%12) - Math.PI)
      r = (@innerRadius+i*(@radius-10-@innerRadius)/@notes)/2
      x = @radius/2 + r*Math.sin(o)
      y = @radius/2 + r*Math.cos(o)
      circle = document.createElementNS "http://www.w3.org/2000/svg", "circle"
      circle.setAttribute "r", NOTE_RADIUS
      circle.setAttribute "fill", "#9ea2b8"
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
        line.setAttribute "stroke", "#494E6B"
        lines.appendChild line
      xx = x
      yy = y

    @svg.appendChild lines
    @svg.appendChild circles
    
    el.appendChild @svg

    @update()

  # key: C is 0, C# is 1, etc... 
  # scale: "WWHWWWH" is major
  drawKey: (key, scale) ->
    for k, ref of @midiRefs
      ref.setAttribute "fill", "#494E6B"
    count = 0
    for l in scale
      count += 2 if l is "W"
      count += 1 if l is "H"
      for i in [-1..5]
        @midiRefs[24+key+12*i+count]?.setAttribute "fill", "#9ea2b8"

  press: (key) ->
    circle = @midiRefs[key]
    @animator.addKeyPress
      key: key      
      x: parseInt circle.getAttribute "cx"
      y: parseInt circle.getAttribute "cy"
      pressedAt: Date.now()

  unpress: (key) ->
    @animator.removeKeyPress(key)

  update: ->
    @_clear()
    @animator.update()
    requestAnimationFrame(@update.bind(@))

  _clear: ->
    @svg.removeChild @animations if @animations
    @animations.innerHTML = "" if @animations
    @animations = document.createElementNS "http://www.w3.org/2000/svg", "g"
    @svg.appendChild @animations
    @animator.setLayerElement @animations



class Animator

  constructor: (@svg) ->
    @keyPresses = {}

  addKeyPress: (keyPress) ->
    unless @keyPresses[keyPress.key]
      @keyPresses[keyPress.key] = keyPress

  removeKeyPress: (key) ->
    @keyPresses[key].unpressedAt = Date.now()

  update: ->
    now = Date.now()

    for key, keyPress of @keyPresses 
      delete @keyPresses[key] if now-keyPress.unpressedAt > 50

    count = Object.keys(@keyPresses).length
    return "idle" if count is 0

    if count is 1
      for key, keyPress of @keyPresses    
        life = now - keyPress.pressedAt

        if life < 500
          @_drawGlowerAt keyPress.x, keyPress.y, 8+4*life/500, 1-life/500
        @_drawNoteAt keyPress.x, keyPress.y

    else
      for key, press of @keyPresses    
        life = now - press.pressedAt
        for otherkey, other of @keyPresses
          unless other.key is press.key
            if life < 100
              x = other.x - (other.x - press.x)*life/100
              y = other.y - (other.y - press.y)*life/100
              @_drawNoteAt x, y
              @_drawLine other.x, other.y, x, y
            else if now - other.pressedAt >= 100
              @_drawLine other.x, other.y, press.x, press.y
        
        if 50 <= life < 700
          @_drawGlowerAt press.x, press.y, PLAY_NOTE_RADIUS+8*(life-50)/500, 1-(life-50)/500
          @_drawNoteAt press.x, press.y

        if life >= 700
          @_drawNoteAt press.x, press.y

    # else
    #   for keyPress of @keyPresses
    #     life = now - keyPress.pressedAt


  setLayerElement: (svg) -> @svg = svg

  killAll: ->
    for key, keyPress of @keyPresses 
      delete @keyPresses[key] if keyPress.unpressedAt

  _drawGlowerAt: (x, y, size, opacity) ->
    @_drawCircle(x, y, size, opacity, "#fff")

  _drawNoteAt: (x, y, size = PLAY_NOTE_RADIUS, opacity = 1) ->
    @_drawCircle(x, y, size, opacity, PLAY_COLOR)

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
    line.setAttribute "stroke", PLAY_COLOR
    line.setAttribute "stroke-opacity", "0.4"
    @svg.appendChild line


# requestAnimationFrame = ->
#   return  window.requestAnimationFrame       || 
#           window.webkitRequestAnimationFrame || 
#           window.mozRequestAnimationFrame    || 
#           window.oRequestAnimationFrame      || 
#           window.msRequestAnimationFrame     || 
#           (callback) ->
#             setTimeout(callback, 1000 / 60)


# until it's componentized
window.RadMusic = RadMusic