RADIUS = 500
INNER_RADIUS = 100
NOTES = 60

class RadMusic

  constructor: (@radius = RADIUS, @innerRadius = INNER_RADIUS, @notes = NOTES) ->
    @midiRefs = {}

  render: (el) ->
    @svg = document.createElementNS "http://www.w3.org/2000/svg", "svg" 
    @svg.setAttribute "width", @radius
    @svg.setAttribute "height", @radius

    circles = document.createElementNS "http://www.w3.org/2000/svg", "g"
    lines = document.createElementNS "http://www.w3.org/2000/svg", "g"

    xx = yy = null

    for i in [0..@notes]
      o = 2*Math.PI/12 * (i%12)
      r = (@innerRadius+i*(@radius-10-@innerRadius)/@notes)/2
      x = @radius/2 + r*Math.sin(o)
      y = @radius/2 + r*Math.cos(o)
      circle = document.createElementNS "http://www.w3.org/2000/svg", "circle"
      circle.setAttribute "r", "5"
      circle.setAttribute "fill", "#9ea2b8"
      circle.setAttribute "cx", x 
      circle.setAttribute "cy", y
      circles.appendChild circle

      @midiRefs[i+36] = circle

      if xx
        line = document.createElementNS "http://www.w3.org/2000/svg", "line"
        line.setAttribute "x1", xx
        line.setAttribute "y1", yy
        line.setAttribute "x2", x
        line.setAttribute "y2", y
        lines.appendChild line
      xx = x
      yy = y

    @svg.appendChild lines
    @svg.appendChild circles
    
    el.appendChild @svg

  press: (key) ->
    circle = @midiRefs[key]
    circle.setAttribute "fill", "#F81338"
    circle.setAttribute "r", "8"

  unpress: (key) ->
    circle = @midiRefs[key]
    circle.setAttribute "fill", "#9ea2b8"
    circle.setAttribute "r", "5"

  update: ->
    #render
    requestAnimationFrame(@update)


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