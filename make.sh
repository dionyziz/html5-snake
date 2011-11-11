#!/bin/sh

haml snake.haml > snake.html
sass style.scss style.css
coffee -c game.coffee
