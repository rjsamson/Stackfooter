module Console exposing (..)

import Html.App as Html
import Effects exposing (Effects)
import Console.View exposing (..)
import Console.Actions exposing (..)
import Console.Models exposing (..)

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    UpdateTicker newTicker ->
      (newTicker, Cmd.none)

    _ ->
      (model, Cmd.none)

init : ( Model, Cmd msg )
init =
  ( initialModel, Cmd.none )

tickertapeUpdate : Signal Msg
tickertapeUpdate =
  map UpdateTicker tickertape

main =
  Html.program { init = init, update = update, view = view, subscriptions = \_ -> Sub.none }

port tickertape : (Model -> msg) -> Sub msg

port apiKey : String
