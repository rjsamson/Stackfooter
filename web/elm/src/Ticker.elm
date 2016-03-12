module Ticker (..) where

import StartApp
import Effects exposing (Effects)
import Task
import View exposing (..)
import Html exposing (Html)
import Actions exposing (..)
import Models exposing (..)

update : Action -> Model -> ( Model, Effects Action )
update action model =
  case action of
    UpdateTicker newTicker ->
      (newTicker, Effects.none)

    _ ->
      (model, Effects.none)

init : ( Model, Effects action )
init =
  ( initialModel, Effects.none )

app : StartApp.App Model
app =
  StartApp.start
    { init = init
    , inputs = [tickertapeUpdate]
    , view = view
    , update = update
    }

tickertapeUpdate : Signal Action
tickertapeUpdate =
  Signal.map UpdateTicker tickertape

main : Signal.Signal Html
main =
  app.html

port tickertape : Signal Model
