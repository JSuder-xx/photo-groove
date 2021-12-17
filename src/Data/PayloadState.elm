module Data.PayloadState exposing (PayloadState(..), fromHttpErrorResult, fromResult, loadedOptional, map, over, view)

import Html exposing (Html, div, text)
import Http exposing (Error(..))
import Monocle.Optional as Optional exposing (Optional)


type PayloadState a
    = NotLoaded
    | Loading
    | Loaded a
    | Errored String


view : (a -> Html msg) -> PayloadState a -> Html msg
view viewPayload request =
    case request of
        NotLoaded ->
            text ""

        Loading ->
            div [] [ text "Loading..." ]

        Loaded a ->
            viewPayload a

        Errored err ->
            div [] [ text <| "Error Loading: " ++ err ]


{-| A Prism into the loaded state.
-}
loadedOptional : Optional (PayloadState a) a
loadedOptional =
    Optional
        (\req ->
            case req of
                Loaded a ->
                    Just a

                _ ->
                    Nothing
        )
        (\val _ ->
            Loaded val
        )


over : (a -> a) -> PayloadState a -> PayloadState a
over =
    Optional.modify loadedOptional


map : (a -> b) -> PayloadState a -> PayloadState b
map f req =
    case req of
        Loaded a ->
            Loaded <| f a

        NotLoaded ->
            NotLoaded

        Errored e ->
            Errored e

        Loading ->
            Loading


fromResult : (e -> String) -> Result e a -> PayloadState a
fromResult errorDisplay result =
    case result of
        Err err ->
            Errored <| errorDisplay err

        Ok a ->
            Loaded a


fromHttpErrorResult : Result Http.Error a -> PayloadState a
fromHttpErrorResult =
    fromResult httpErrorToString


httpErrorToString : Http.Error -> String
httpErrorToString error =
    case error of
        BadBody _ ->
            "I cannot understand what the server just said."

        BadUrl _ ->
            "Whoops. There is a software error and it looks like I asked for a bad url."

        Timeout ->
            "Server is busy. Try again later."

        NetworkError ->
            "There was a network error. Did you lose WiFi?"

        BadStatus code ->
            case code of
                400 ->
                    "Server did not understand me."

                401 ->
                    "Not authenticated."

                403 ->
                    "Not authorized."

                500 ->
                    "Error on the server."

                _ ->
                    "Bad response"
