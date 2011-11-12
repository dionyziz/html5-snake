startGame = ->
  console.log "Starting..."
  
  _.templateSettings.interpolate = /\{\{(.+?)\}\}/g

  canvas = $("#game canvas")[0].getContext("2d")
  game = new SnakeGame(canvas, $("#game #hud"), 800, 400, 10, 10)
  game.start()

$ startGame

class Snake
  constructor: (@game, @x, @y, @direction = "RIGHT")->
    @alive = true
    @key = null 
    @increaseLengthBy = 0
    
    @tail = [ { x: @x, y: @y }
              { x: @x-1, y: @y }
              { x: @x-2, y: @y } ]

    true

  keyDown: (e) ->
    keys = { 38: "UP", 40: "DOWN", 37: "LEFT", 39: "RIGHT" }
    @key = keys[ e.keyCode ] if keys[ e.keyCode ]?

  eat: =>
    @increaseLengthBy += 5 #Causes the next update() to not remove the last element of @tail, thus increasing the length

  update: (delta) =>
    opposite = (@key == "UP" and @direction == "DOWN") or (@key == "DOWN" and @direction == "UP") or (@key == "LEFT" and @direction == "RIGHT") or (@key == "RIGHT" and @direction == "LEFT")

    @direction = @key if @key != null and (!opposite)

    #Find the position of the head
    @y-- if @direction == "UP"
    @y++ if @direction == "DOWN"
    @x-- if @direction == "LEFT"
    @x++ if @direction == "RIGHT"

    @x = 0 if @x >= @game.cols
    @x = @game.cols-1 if @x < 0
    @y = 0 if @y >= @game.rows
    @y = @game.rows-1 if @y < 0
    
    head =
      x: @x
      y: @y

    for t in @tail
      if t.x == head.x and t.y == head.y
        @alive = false

    @tail.pop() if @increaseLengthBy == 0
    @tail.unshift(head)
    @key = null
    @increaseLengthBy-- if @increaseLengthBy > 0

    true

  draw: (canvas, delta) =>
    for r in @tail
      canvas.beginPath()
      canvas.rect((r.x * @game.sprite_size) + 1, (r.y * @game.sprite_size) + 1, @game.sprite_size - 1, @game.sprite_size - 1)
      canvas.fillStyle = "#E3D000"
      canvas.fill()


class SnakeGame
  constructor: (@canvas, @hud, @width = 800, @height = 600, @sprite_size = 10, @fps = 20) ->
    console.log "Game created!"
    @lost = true
    @redrawHud = true
    @score = 0
    @cols = @width/@sprite_size
    @rows = @height/@sprite_size
    @food =
      x: Math.ceil(Math.random() * @cols) - 1
      y: Math.ceil(Math.random() * @rows) - 1

  start: =>
    return false unless @lost
    console.log "Game starting! Size is #{@width}-#{@height}"
    
    @lost = false
    @redrawHud = true
    @score = 0
    @then = Date.now()
    @snake = new Snake(this, 5, 5)
    addEventListener "keydown", @keyDown
    
    @gameLoop()
    true

  gameLoop: =>
    now = Date.now()
    @delta = now - @then

    @update()
    @draw()
    
    @then = now
    setTimeout @gameLoop, 1000/@fps unless @lost
    # @start() if @lost 
    true
  
  keyDown: (e) =>
    @snake.keyDown e

  drawHud: =>
    unless @lost
      @hud.html _.template ($ "#templates #hud #playing").html(), score: @score
    else
      @hud.html _.template ($ "#templates #hud #lost").html(), score: @score
      ($ "button#restart").click @start

    @redrawHud = false

  spawnFood: =>
    @food =
      x: Math.ceil(Math.random() * @cols) - 1
      y: Math.ceil(Math.random() * @rows) - 1
    for t in @snake.tail
      if @food.x == t.x and @food.y == t.y
        return @spawnFood()
  
  update: =>
    if not @snake.alive
      @lost = true
      @redrawHud = true
      return false

    @snake.update(@delta)

    if @snake.x == @food.x and @snake.y == @food.y
      @snake.eat()
      @spawnFood()

      @score++
      @redrawHud = true
    
    true

  draw: =>
    @canvas.clearRect 0, 0, @width, @height

    @drawHud() if @redrawHud

    #draw the food
    @canvas.beginPath()
    @canvas.arc (@food.x + 1/2) * @sprite_size, (@food.y + 1/2) * @sprite_size, (@sprite_size/2), 0, 2 * Math.PI, false
    @canvas.fillStyle = "#FF390D"
    @canvas.fill()

    @snake.draw @canvas, @delta
