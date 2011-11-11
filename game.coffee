$( ->
  startGame()
)

startGame = ->
  console.log "Starting..."
  
  _.templateSettings.interpolate = /\{\{(.+?)\}\}/g

  canvas = $("#game canvas")[0].getContext("2d")
  game = new SnakeGame(canvas, $("#game #hud"), 800, 400, 10, 10)
  game.start()

class Snake
  constructor: (@game, @x, @y, @direction = "RIGHT")->
    @alive = true
    @key = null 
    @tail = new Array
    @increaseLength = false
    
    @tail.push
      x: @x
      y: @y
    @tail.push
      x: @x-1
      y: @y
    @tail.push
      x: @x-2
      y: @y

    true

  keyDown: (e) ->
    @key = "UP" if e.keyCode == 38
    @key = "DOWN" if e.keyCode == 40
    @key = "LEFT" if e.keyCode == 37
    @key = "RIGHT" if e.keyCode == 39

  eat: =>
    @increaseLength = true #Causes the next update() to not remove the last element of @tail, thus increasing the length

  update: (delta) =>
    opposite = false
    opposite = true if (@key == "UP" and @direction == "DOWN") or (@key == "DOWN" and @direction == "UP") or (@key == "LEFT" and @direction == "RIGHT") or (@key == "RIGHT" and @direction == "LEFT")

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

    @tail.pop() unless @increaseLength
    @tail.unshift(head)
    
    @key = null
    @increaseLength = false

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
    addEventListener("keydown", @keyDown)
    
    @gameLoop()
    return true

  gameLoop: =>
    now = Date.now()
    @delta = now - @then

    @update()
    @draw()
    
    @then = now

    setTimeout(@gameLoop, 1000/@fps) unless @lost
    # @start() if @lost 
    return true
  
  keyDown: (e) =>
    @snake.keyDown(e)

  drawHud: =>
    unless @lost
      @hud.html _.template($("#templates #hud #playing").html(),
        score: @score
      )
    else
      @hud.html _.template($("#templates #hud #lost").html(),
        score: @score
      )
      $("button#restart").click(@start)

    @redrawHud = false
  
  update: =>
    if not @snake.alive
      @lost = true
      @redrawHud = true
      return false

    @snake.update(@delta)

    if @snake.x == @food.x and @snake.y == @food.y
      @food =
        x: Math.ceil(Math.random() * @cols) - 1
        y: Math.ceil(Math.random() * @rows) - 1
      @snake.eat()

      @score++
      @redrawHud = true
    
    return true

  draw: =>
    @canvas.clearRect(0, 0, @width, @height)
    
    @drawHud() if @redrawHud
    


    #draw the food
    @canvas.beginPath()
    @canvas.arc((@food.x * @sprite_size) + (@sprite_size/2), (@food.y * @sprite_size) + (@sprite_size/2), (@sprite_size/2), 0, 2 * Math.PI, false)
    @canvas.fillStyle = "#FF390D"
    @canvas.fill()


    @snake.draw(@canvas, @delta)

     
  
