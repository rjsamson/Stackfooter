module Ticker.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (href, class)
import Ticker.Actions exposing (..)
import Ticker.Models exposing (..)
import String

view : Model -> Html Msg
view model =
  div
    []
    [ page model ]

page : Model -> Html Msg
page model =
  div
    []
    [ navbar model
    , tickerTable model
    ]

navbar : Model -> Html Msg
navbar model =
  nav
    [ class "navbar navbar-default" ]
    [ div [ class "container-fluid" ]
      [ div [ class "navbar-header" ]
        [ brandLink model ]
      ]
    ]

brandLink : Model -> Html Msg
brandLink model =
  a
    [ href "#", class "navbar-brand" ][ text "Stackfooter" ]

tickerTable : Model -> Html Msg
tickerTable model =
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
    cents = if price < 10 then "0" ++  (String.right 2 priceStr) else String.right 2 priceStr
    dollars =  if price < 100 then "0" else String.slice 0 -2 priceStr
  in
    "$" ++ dollars ++ "." ++ cents
