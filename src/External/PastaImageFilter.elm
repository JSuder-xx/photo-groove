port module External.PastaImageFilter exposing (FilterValue, ImageFilters, activityChanges, apply, filterValueRange, hueL, init, noiseL, rippleL)

import Monocle.Lens exposing (Lens)
import Range


type alias FilterOptions =
    { id : String
    , url : String
    , filters : List { name : String, amount : Float }
    }


type alias FilterValue =
    Int


type alias ImageFilters =
    { hue : FilterValue
    , ripple : FilterValue
    , noise : FilterValue
    }


port setFilters : FilterOptions -> Cmd msg


port activityChanges : (String -> msg) -> Sub msg


filterValueRange : Range.Range Int
filterValueRange =
    Range.createWith Range.types.int (Just 0) (Just 11) (Just ( Range.Inc, Range.Inc )) |> Result.withDefault (Range.empty Range.types.int)


hueL : Lens ImageFilters FilterValue
hueL =
    Lens .hue (\h f -> { f | hue = h })


rippleL : Lens ImageFilters FilterValue
rippleL =
    Lens .ripple (\r f -> { f | ripple = r })


noiseL : Lens ImageFilters FilterValue
noiseL =
    Lens .noise (\n f -> { f | noise = n })


init : Int -> ImageFilters
init v =
    { hue = v, ripple = v, noise = v }


filterValueToFloat : FilterValue -> Float
filterValueToFloat fv =
    case ( Range.ce filterValueRange fv, Range.upperElement filterValueRange ) of
        ( True, Just upper ) ->
            toFloat fv / toFloat upper

        _ ->
            0.0


apply : { url : String, id : String } -> ImageFilters -> Cmd msg
apply { url, id } filters =
    let
        filterOptions =
            [ { name = "Hue", amount = filterValueToFloat filters.hue }
            , { name = "Ripple", amount = filterValueToFloat filters.ripple }
            , { name = "Noise", amount = filterValueToFloat filters.noise }
            ]
    in
    setFilters { url = url, id = id, filters = filterOptions }
