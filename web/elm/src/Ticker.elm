module Ticker (..) where

import StartApp
import Effects exposing (Effects)
import Task
import View exposing (..)
import Html exposing (Html)
import Actions exposing (..)
import Models exposing (..)

update : Action -> AppModel -> ( AppModel, Effects Action )
update action model =
  case action of
    UpdateTicker newTicker ->
      ({ model | ticker = newTicker }, Effects.none)

    _ ->
      (model, Effects.none)

init : ( AppModel, Effects action )
init =
  ( initialModel, Effects.none )

app : StartApp.App AppModel
app =
  StartApp.start
    { init = init
    , inputs = []
    , view = view
    , update = update
    }

main : Signal.Signal Html
main =
  app.html
