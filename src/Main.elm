module Main exposing (main)

import Browser
import CRDT exposing (CRDT)
import Html exposing (Html, br, div, h2, input, strong, text)
import Html.Attributes exposing (value)
import Html.Events exposing (onInput)


type Msg
    = UpdateCRDT String


type alias Model =
    { crdt : CRDT, control : String }


init : Model
init =
    { crdt = CRDT.demo, control = CRDT.toString CRDT.demo }


main : Program () Model Msg
main =
    Browser.sandbox { view = view, init = init, update = update }


view : Model -> Html Msg
view model =
    div []
        [ h2 [] [ text "CRDT" ]
        , input [ onInput UpdateCRDT, value (CRDT.toString model.crdt) ] []
        , div [] [ text (CRDT.toString model.crdt) ]
        , div [] (List.map (\operation -> div [] [ text (Debug.toString operation) ]) model.crdt.operations)
        , h2 [] [ text "control" ]
        , input [ onInput UpdateCRDT, value model.control ] []
        , div [] [ text model.control ]
        , br [] []
        , if CRDT.toString model.crdt == model.control then
            strong [] [ text "Result matches!" ]

          else
            strong [] [ text "Out of Sync!" ]
        ]


update : Msg -> Model -> Model
update msg model =
    case msg of
        UpdateCRDT updatedString ->
            { model
                | crdt = CRDT.update "bob" updatedString model.crdt
                , control = updatedString
            }
