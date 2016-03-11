module View (..) where

import Html exposing (..)
import Html.Attributes exposing (href, class)
import Actions exposing (..)
import Models exposing (..)

type alias ViewModel =
  { ticker : String }

view : Signal.Address Action -> ViewModel -> Html.Html
view address model =
  div
    []
    [ page address model ]

page : Signal.Address Action -> ViewModel -> Html.Html
page address model =
  div
    []
    [ navbar address model
    , tickerTable address model
    ]

navbar : Signal.Address Action -> ViewModel -> Html.Html
navbar address model =
  nav
    [ class "navbar navbar-default" ]
    [ div [ class "container-fluid" ]
      [ div [ class "navbar-header" ]
        [ brandLink address model ]
      ]
    ]

brandLink : Signal.Address Action -> ViewModel -> Html.Html
brandLink address model =
  a
    [ href "#", class "navbar-brand" ][ text "Stackfooter" ]

tickerTable : Signal.Address Action -> ViewModel -> Html.Html
tickerTable address model =
  p
    [][ text model.ticker ]
