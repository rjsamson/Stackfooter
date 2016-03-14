module Console (..) where

import StartApp
import Effects exposing (Effects)
import Task
import Html exposing (Html)

type Action
  = NoOp
  | UpdateTicker String

type alias Model =
  { symbol : String
  , key : String
  }

initialModel : Model
initialModel =
  { symbol = "NYC"
  , key = apiKey
  }

view : Signal.Address Action -> Model -> Html.Html
view address model =
  Html.div
    []
    [ Html.text ("API Key: " ++ model.key) ]

update : Action -> Model -> ( Model, Effects Action )
update action model =
  case action of
    UpdateTicker newTicker ->
      ({ model | symbol = newTicker }, Effects.none)

    _ ->
      (model, Effects.none)

init : ( Model, Effects action )
init =
  ( initialModel, Effects.none )

app : StartApp.App Model
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

port apiKey : String
