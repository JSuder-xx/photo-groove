module External.Elements exposing (rangeSlider)

import Html exposing (..)
import Html.Attributes as Attr
import Html.Events exposing (on)
import Json.Decode exposing (at, int)
import Json.Encode as Encode


rangeSlider : { max : Int, val : Int, onSlide : Int -> msg } -> List (Attribute msg) -> List (Html msg) -> Html msg
rangeSlider { max, val, onSlide } attributes children =
    node
        "range-slider"
        (attributes
            ++ [ Attr.max <| String.fromInt max
               , Attr.property "val" (Encode.int val)
               , at [ "detail", "userSlidTo" ] int
                    |> Json.Decode.map onSlide
                    |> on "slide"
               ]
        )
        children
