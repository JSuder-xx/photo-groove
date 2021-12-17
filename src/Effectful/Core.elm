module Effectful.Core exposing
    ( Effect
    , Updater(..)
    , andThen
    , apply
    , lift
    , updateWithEffect
    )

import Html exposing (a)


{-| Describes an effectful update of an `a` where the effect includes the new `a` along with a Cmd whose message is an Updater.
-}
type Updater a
    = Updater (a -> Effect a)


{-| An effect for `a` includes a new `a` along with a Cmd that may update `a`.
-}
type alias Effect a =
    ( a, Cmd (Updater a) )


lift : (a -> a) -> Updater a
lift fn =
    Updater (\a -> ( fn a, Cmd.none ))


andThen : (a -> Updater a) -> Updater a -> Updater a
andThen secondUpdater firstUpdater =
    Updater
        (\a ->
            let
                ( first, firstCommand ) =
                    apply firstUpdater a

                ( second, secondCommand ) =
                    apply (secondUpdater first) first
            in
            ( second, Cmd.batch [ firstCommand, secondCommand ] )
        )


updateWithEffect : (a -> a) -> Cmd (Updater a) -> Updater a
updateWithEffect update cmdToUpdateA =
    Updater <|
        \a ->
            ( update a, cmdToUpdateA )


{-| Apply an updater to an `a` to produce an Effect.
-}
apply : Updater a -> a -> Effect a
apply (Updater fn) a =
    fn a
