module PhotoFolders.ServiceApi exposing (fullPhotoUrl, getFolders, thumbPhotoUrl)

import Dict exposing (Dict)
import Http
import Json.Decode as Decode exposing (Decoder, int, list, string)
import Json.Decode.Pipeline exposing (required)
import PhotoFolders.Folder exposing (Folder(..))
import PhotoFolders.Folders exposing (Folders)
import PhotoFolders.Photo exposing (Photo)


getFolders : (Result Http.Error Folders -> msg) -> Cmd msg
getFolders a =
    Http.get
        { url = urlPrefix ++ "folders/list"
        , expect = Http.expectJson a foldersDecoder
        }


fullPhotoUrl : String -> String
fullPhotoUrl url =
    urlPrefix ++ "photos/" ++ url ++ "/full"


thumbPhotoUrl : String -> String
thumbPhotoUrl url =
    urlPrefix ++ "photos/" ++ url ++ "/thumb"


urlPrefix : String
urlPrefix =
    "http://elm-in-action.com/"


foldersDecoder : Decoder Folders
foldersDecoder =
    Decode.map2
        (\photos root ->
            { photos = photos, rootFolder = root }
        )
        modelPhotosDecoder
        folderDecoder


photosDecoder : Decoder (Dict String Photo)
photosDecoder =
    let
        jsonPhotoDecoder : Decoder ( String, Int, List String )
        jsonPhotoDecoder =
            Decode.succeed (\a b c -> ( a, b, c ))
                |> required "title" string
                |> required "size" int
                |> required "related_photos" (list string)

        finishPhoto ( url, ( title, size, relatedUrls ) ) =
            ( url
            , { url = url
              , size = size
              , title = title
              , relatedUrls = relatedUrls
              }
            )

        fromPairs =
            List.map finishPhoto >> Dict.fromList
    in
    Decode.keyValuePairs jsonPhotoDecoder |> Decode.map fromPairs


folderDecoder : Decoder Folder
folderDecoder =
    let
        folderFromJson name photos subfolders =
            Folder
                { name = name
                , expanded = True
                , subfolders = subfolders
                , photoUrls = Dict.keys photos
                }
    in
    Decode.succeed folderFromJson
        |> required "name" string
        |> required "photos" photosDecoder
        |> required "subfolders" (Decode.lazy (\_ -> list folderDecoder))


modelPhotosDecoder : Decoder (Dict String Photo)
modelPhotosDecoder =
    let
        modelPhotosFromJson folderPhotos subfolderPhotos =
            List.foldl Dict.union folderPhotos subfolderPhotos
    in
    Decode.succeed modelPhotosFromJson
        |> required "photos" photosDecoder
        |> required "subfolders" (Decode.lazy (\_ -> list modelPhotosDecoder))
