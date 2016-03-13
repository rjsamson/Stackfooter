module View (..) where

import Html exposing (..)
import Html.Attributes exposing (href, class)
import Actions exposing (..)
import Models exposing (..)
import String

view : Signal.Address Action -> Model -> Html.Html
view address model =
  div
    []
    [ page address model ]

page : Signal.Address Action -> Model -> Html.Html
page address model =
  div
    []
    [ navbar address model
    , tickerTable address model
    ]

navbar : Signal.Address Action -> Model -> Html.Html
navbar address model =
  nav
    [ class "navbar navbar-default" ]
    [ div [ class "container-fluid" ]
      [ div [ class "navbar-header" ]
        [ brandLink address model ]
      ]
    ]

brandLink : Signal.Address Action -> Model -> Html.Html
brandLink address model =
  a
    [ href "#", class "navbar-brand" ][ text "Stackfooter" ]

tickerTable : Signal.Address Action -> Model -> Html.Html
tickerTable address model =
  table
    [ class "table table-bordered" ]
    [ thead
      []
      [ tr
        []
        [ th [] [ text "Symbol" ]
        , th [] [ text "Venue" ]
        , th [] [ text "Bid" ]
        , th [] [ text "Ask" ]
        , th [] [ text "Last" ]
        , th [] [ text "Bid Size/Depth" ]
        , th [] [ text "Ask Size/Depth" ]
        ]
      ]
    , tbody
      []
      [ tr
        []
        [ td [] [ text model.symbol ]
        , td [] [ text model.venue ]
        , td [] [ text (formatPrice model.bid) ]
        , td [] [ text (formatPrice model.ask) ]
        , td [] [ text (formatPrice model.last) ]
        , td [] [ text ((toString model.bidSize) ++ " / " ++ (toString model.bidDepth)) ]
        , td [] [ text ((toString model.askSize) ++ " / " ++ (toString model.askDepth)) ]
        ]
      ]
    ]

formatPrice : Int -> String
formatPrice price =
  let
    priceStr = toString price
    cents = String.right 2 priceStr
    dollars = String.slice 0 -2 priceStr
  in
    "$" ++ dollars ++ "." ++ cents
