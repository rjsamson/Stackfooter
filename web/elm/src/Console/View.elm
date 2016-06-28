module Console.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (href, class)
import Console.Actions exposing (..)
import Console.Models exposing (..)
import String
import Date exposing (..)
import Result

view : Model -> Html Msg
view model =
  div
    []
    [ page model ]

page : Model -> Html Msg
page model =
  div
    []
    [ tickerTable model ]

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
        , th [] [ text "Bid Size/Depth" ]
        , th [] [ text "Ask" ]
        , th [] [ text "Last" ]
        , th [] [ text "Ask Size/Depth" ]
        , th [] [ text "Last Trade" ]
        ]
      ]
    , tbody
      []
      [ tr
        []
        [ td [] [ text model.symbol ]
        , td [] [ text model.venue ]
        , td [] [ text (formatPrice model.bid) ]
        , td [] [ text ((toString model.bidSize) ++ " / " ++ (toString model.bidDepth)) ]
        , td [] [ text (formatPrice model.ask) ]
        , td [] [ text (formatPrice model.last) ]
        , td [] [ text ((toString model.askSize) ++ " / " ++ (toString model.askDepth)) ]
        , td [] [ text (formatDate model.lastTrade) ]
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

formatDate : String -> String
formatDate date =
  case Date.fromString date of
    Ok d ->
      toString (Date.hour d) ++ ":" ++ toString (Date.minute d) ++ ":" ++ toString (Date.second d) ++ ":" ++ toString (Date.millisecond d)
    Err err ->
      ""
