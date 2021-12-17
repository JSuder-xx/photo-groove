module PhotoFolders.Page exposing (Model, init, view)

import Data.Bool as Bool
import Data.Path exposing (Path)
import Data.PayloadState as Request exposing (PayloadState(..))
import Effectful.Core exposing (Updater(..))
import Html exposing (..)
import Html.Attributes exposing (class, href, src)
import Html.Events exposing (onClick)
import PhotoFolders.Folder exposing (Folder(..))
import PhotoFolders.Folders as Folders
import PhotoFolders.Model as Model
import PhotoFolders.Photo exposing (Photo)
import PhotoFolders.ServiceApi


type alias Model =
    Model.Model


init : Maybe String -> ( Model, Cmd (Updater Model) )
init selectedFilename =
    ( { selectedPhotoUrl = selectedFilename, foldersPayloadState = Loading }
    , PhotoFolders.ServiceApi.getFolders (Request.fromHttpErrorResult >> Model.foldersPayloadStateL.set >> Effectful.Core.lift)
    )


view : Model -> Html (Updater Model)
view model =
    div [ class "content" ]
        [ div
            [ class "folders" ]
            [ Request.view (viewFolder Data.Path.empty) (Request.map Folders.rootFolderL.get model.foldersPayloadState) ]
        , div
            [ class "selected-photo" ]
            [ model.selectedPhotoUrl
                |> Maybe.map Folders.photoByUrl
                |> Maybe.map2 Tuple.pair (Request.loadedOptional.getOption model.foldersPayloadState)
                |> Maybe.andThen (\( folders, maybePhotoFromFolders ) -> maybePhotoFromFolders folders)
                |> Maybe.map viewSelectedPhoto
                |> Maybe.withDefault (text "")
            ]
        ]


viewPhoto : String -> Html (Updater Model)
viewPhoto url =
    a [ href ("/photos/" ++ url), class "photo", onClick (Effectful.Core.lift <| Model.selectedPhotoUrlL.set url) ]
        [ text url ]


viewSelectedPhoto : Photo -> Html (Updater Model)
viewSelectedPhoto photo =
    div [ class "selected-photo" ]
        [ h2 [] [ text photo.title ]
        , img [ src (PhotoFolders.ServiceApi.fullPhotoUrl photo.url) ] []
        , span [] [ text (String.fromInt photo.size ++ "KB") ]
        , h3 [] [ text "Related" ]
        , div [ class "related-photos" ]
            (List.map viewRelatedPhoto photo.relatedUrls)
        ]


viewRelatedPhoto : String -> Html (Updater Model)
viewRelatedPhoto url =
    img
        [ class "related-photo"
        , onClick (Effectful.Core.lift <| Model.selectedPhotoUrlL.set url)
        , src (PhotoFolders.ServiceApi.thumbPhotoUrl url)
        ]
        []


viewFolder : Path Folder -> Folder -> Html (Updater Model)
viewFolder path (Folder folder) =
    div
        [ class ("folder " ++ Bool.decode "expanded" "collapsed" folder.expanded) ]
        [ label [ Model.selectFolder path |> Effectful.Core.lift |> onClick ] [ text folder.name ]
        , if not folder.expanded then
            text ""

          else
            div [ class "contents" ] <|
                List.append
                    (List.indexedMap (\index -> viewFolder (Data.Path.atChild index path)) folder.subfolders)
                    (List.map viewPhoto folder.photoUrls)
        ]
