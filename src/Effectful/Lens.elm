module Effectful.Lens exposing (Lens, fromMonocleLens, fromMonocleLensNoEffect, lensCompose)

import Effectful.Core exposing (Effect, Updater(..), apply)
import Effectful.Monocle exposing (toParentUpdateLens)
import Monocle.Lens as MLens


type alias Lens a b =
    { view : a -> b
    , update : b -> Updater a
    }


fromMonocleLens : (a -> Effect a) -> MLens.Lens a b -> Lens a b
fromMonocleLens effect { get, set } =
    { view = get
    , update = \b -> Updater (\a -> set b a |> effect)
    }


fromMonocleLensNoEffect : MLens.Lens a b -> Lens a b
fromMonocleLensNoEffect { get, set } =
    { view = get
    , update = \b -> Updater (\a -> ( set b a, Cmd.none ))
    }


{-| INTERNAL USE ONLY!!! This throws away information.
-}
toMonocleLensDroppingEffect : Lens a b -> MLens.Lens a b
toMonocleLensDroppingEffect { view, update } =
    { get = view
    , set =
        \b a ->
            Tuple.first <| apply (update b) a
    }


lensCompose : Lens a b -> Lens b c -> Lens a c
lensCompose abL bcL =
    { view = abL.view >> bcL.view
    , update =
        \c ->
            Updater
                (\a ->
                    let
                        ( newB, bCmd ) =
                            apply (bcL.update c) (abL.view a)

                        ( newA, aCmd ) =
                            apply (abL.update newB) a
                    in
                    ( newA
                    , Cmd.batch
                        [ aCmd
                        , Cmd.map (toParentUpdateLens (toMonocleLensDroppingEffect abL)) bCmd
                        ]
                    )
                )
    }
