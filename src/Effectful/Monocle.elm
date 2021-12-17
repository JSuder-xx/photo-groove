module Effectful.Monocle exposing
    ( toParentEffectLens
    , toParentEffectOptional
    , toParentUpdateLens
    , toParentUpdateOptional
    , toParentViewLens
    , toParentViewOptional
    )

import Effectful.Core exposing (Effect, Updater(..))
import Html exposing (Html)
import Monocle.Lens exposing (Lens)
import Monocle.Optional exposing (Optional)


type alias ModelView a =
    a -> Html (Updater a)


toParentEffectLens : Lens parent child -> Effect child -> parent -> Effect parent
toParentEffectLens abL ( b, cmdUpdateB ) a =
    ( abL.set b a, Cmd.map (toParentUpdateLens abL) cmdUpdateB )


toParentEffectOptional : Optional parent childCase -> Effect childCase -> parent -> Effect parent
toParentEffectOptional abO ( b, cmdUpdateB ) a =
    ( abO.set b a, Cmd.map (toParentUpdateOptional abO) cmdUpdateB )


toParentUpdateLens : Lens parent child -> Updater child -> Updater parent
toParentUpdateLens abL (Updater bUpdater) =
    Updater <| \a -> toParentEffectLens abL (a |> abL.get |> bUpdater) a


toParentUpdateOptional : Optional parent childCase -> Updater childCase -> Updater parent
toParentUpdateOptional abO (Updater bUpdater) =
    Updater
        (\a ->
            case abO.getOption a of
                Just b ->
                    toParentEffectOptional abO (bUpdater b) a

                Nothing ->
                    ( a, Cmd.none )
        )


toParentViewLens : Lens parent child -> ModelView child -> ModelView parent
toParentViewLens abL bView =
    abL.get >> bView >> Html.map (toParentUpdateLens abL)


toParentViewOptional : Optional parent child -> ModelView child -> parent -> Maybe (Html (Updater parent))
toParentViewOptional abO bView =
    abO.getOption >> Maybe.map (bView >> Html.map (toParentUpdateOptional abO))
