module Main where

import Data.Array
import Data.Traversable
import Control.Monad.Eff (Eff)
import Control.Monad.Eff.Random
import Data.Array.Partial as Partial
import Partial.Unsafe as PU
import Control.Monad.Eff.Console (CONSOLE, log)
import Data.Tuple
import Prelude
import Sigment
import Sigment as Sigment
import Sigment.Dom as D
import Data.Maybe
import Sigment.Dom.Props as P
import Sigment.Dom.Tweens as T
import DOM.Timer as Timer

foodCount = 50
cellCount = 50
cellSize = 10

data Action = Move | ChangeDirection Int

type Position = Tuple Int Int

type Snake = Array Position

type Model = {
  snake :: Snake,
  food :: Array Position,
  direction :: Int
}

randomPosition = do
  x <- randomIndex cellCount
  y <- randomIndex cellCount
  pure $ Tuple x y
  where
    randomIndex count = randomInt 0 (count - 1)

generateFoodPositions = 1 .. foodCount # traverse (const randomPosition)

init :: Eff _ Model
init = do
  food <- generateFoodPositions
  pure {
    snake : [Tuple (cellCount / 2) (cellCount / 2)],
    food : food,
    direction : 0
  }

isOut x size = x < 0 || x >= size

positionIsOut :: Position -> Boolean
positionIsOut (Tuple x y) = isOut x cellCount || isOut y cellCount

gameOver :: Partial => Model -> Boolean
gameOver state =
  positionIsOut head || elem head (Partial.tail state.snake)
  where
    head = Partial.head state.snake

directions = [
  Tuple 0 (-1),
  Tuple 1 0,
  Tuple 0 1,
  Tuple (-1) 0
]

directionKeys = [Tuple "up" 0, Tuple "right" 1, Tuple "down" 2, Tuple "left" 3]

changePosition directionIndex pos = Tuple (fst pos + fst direction) (snd pos + snd direction)
  where
    direction = Partial.unsafeIndex directions directionIndex

eval :: Partial => Eval Action Model _
eval (ChangeDirection direction) state dispatch = do
  pure $ state {direction = direction}
eval Move state dispatch = do
  Timer.timeout 100 (dispatch Move) *> pure unit
  if gameOver newState then init else pure newState
  where
    head = state.snake # Partial.head
    newHeadPosition = changePosition state.direction head
    snake = if elem newHeadPosition state.food then newHeadPosition : state.snake else newHeadPosition : Partial.init state.snake
    food = delete newHeadPosition state.food
    newState = state {snake = snake, food = food}

snakeSprite = "assets/snake.png"
foodSprite = "assets/food.png"

render :: Render Action Model _
render action state dispatch =
  D.group' [P.keyboard keys] [food, snake]
  where
    keys = directionKeys <#> (\(Tuple key direction) -> P.newKeys key (dispatch (ChangeDirection direction)))
    snake = D.group $ state.snake <#> (\(Tuple x y) -> D.sprite [P.src snakeSprite, P.x $ x * cellSize, P.y $ y * cellSize])
    food = D.group $ state.food <#> (\(Tuple x y) -> D.sprite [P.src foodSprite, P.x $ x * cellSize, P.y $ y * cellSize])

component :: Partial => Component Unit Action Model _
component = newComponent (const init) eval render

main = do
  let config = defConfig {
        sprites = [snakeSprite, foodSprite],
        containerId = "container",
        height = 800,
        width = 1000,
        initAction = Just Move}
  PU.unsafePartial $ Sigment.init config unit component
