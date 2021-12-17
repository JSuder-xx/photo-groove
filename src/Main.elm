module Main exposing (Model, init, main, subscriptions, view, viewFooter, viewHeader)

import AppPage exposing (AppPage(..))
import Browser exposing (Document)
import Browser.Navigation as Nav
import Data.Function exposing (flip)
import Effectful.Core as Effectful exposing (Updater(..))
import Effectful.Monocle exposing (toParentEffectOptional, toParentUpdateOptional, toParentViewOptional)
import Html exposing (Html, a, footer, h1, li, nav, text, ul)
import Html.Attributes exposing (classList, href)
import Html.Lazy exposing (lazy)
import Maybe.Extra as MaybeEx
import Monocle.Compose as MCompose
import Monocle.Lens exposing (Lens)
import Monocle.Optional exposing (Optional)
import PhotoFolders.Page as PhotoFolders
import PhotoGallery.Page as PhotoGallery
import Routing as Routing exposing (Route(..))
import Url exposing (Url)


type alias Model =
    { page : AppPage
    , key : Nav.Key
    , version : Float
    }


type alias Msg =
    Updater Model


pageL : Lens Model AppPage
pageL =
    Lens .page (\p m -> { m | page = p })


modelPhotoGalleryL : Optional Model PhotoGallery.Model
modelPhotoGalleryL =
    MCompose.lensWithOptional AppPage.photoGalleryL pageL


modelPhotoFoldersL : Optional Model PhotoFolders.Model
modelPhotoFoldersL =
    MCompose.lensWithOptional AppPage.photoFoldersL pageL


view : Model -> Document Msg
view model =
    { title = "Photo Groove, SPA Style"
    , body =
        [ lazy viewHeader model.page
        , model
            |> MaybeEx.oneOf
                [ toParentViewOptional modelPhotoFoldersL PhotoFolders.view
                , toParentViewOptional modelPhotoGalleryL PhotoGallery.view
                ]
            |> Maybe.withDefault (text "No Found")
        , viewFooter
        ]
    }


viewFooter : Html msg
viewFooter =
    footer [] [ text "One is never alone with a rubber duck. -Douglas Adams" ]


viewHeader : AppPage -> Html Msg
viewHeader page =
    let
        navLink : Route -> Html msg
        navLink route =
            li [ classList [ ( "active", AppPage.isActive { link = route, page = page } ) ] ]
                [ a
                    [ route |> Routing.urlString |> href ]
                    [ route |> Routing.display |> text ]
                ]
    in
    nav []
        [ h1 [] [ text "Photo Groove" ]
        , ul [] ([ Folders, Gallery ] |> List.map navLink)
        ]


clickedLink : Browser.UrlRequest -> Updater Model
clickedLink urlRequest =
    Updater <|
        \model ->
            case urlRequest of
                Browser.External href ->
                    ( model, Nav.load href )

                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.page of
        GalleryPage _ ->
            PhotoGallery.subscriptions
                |> Sub.map (toParentUpdateOptional modelPhotoGalleryL)

        _ ->
            Sub.none


init : Float -> Url -> Nav.Key -> ( Model, Cmd Msg )
init version url key =
    updateUrl url { page = NotFound, key = key, version = version }


updateUrl : Url -> Model -> ( Model, Cmd Msg )
updateUrl url model =
    model
        |> (case Routing.parse url of
                Just Gallery ->
                    toParentEffectOptional modelPhotoGalleryL (PhotoGallery.init model.version)

                Just Folders ->
                    toParentEffectOptional modelPhotoFoldersL (PhotoFolders.init Nothing)

                Just (SelectedPhoto filename) ->
                    toParentEffectOptional modelPhotoFoldersL (PhotoFolders.init <| Just filename)

                Nothing ->
                    pageL.set NotFound >> flip Tuple.pair Cmd.none
           )


main : Program Float Model Msg
main =
    Browser.application
        { init = init
        , onUrlRequest = clickedLink
        , onUrlChange = updateUrl >> Updater
        , subscriptions = subscriptions
        , update = Effectful.apply
        , view = view
        }
