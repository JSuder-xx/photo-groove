module PhotoGallery.ServiceApi exposing (getPhotos, largeUrl, photoDecoder, thumbnailUrl)

import Http
import Json.Decode exposing (Decoder, int, list, string, succeed)
import Json.Decode.Pipeline exposing (optional, required)
import PhotoGallery.Photo exposing (Photo)


getPhotos : (Result Http.Error (List Photo) -> msg) -> Cmd msg
getPhotos a =
    Http.get
        { url = "http://elm-in-action.com/photos/list.json"
        , expect = Http.expectJson a (list photoDecoder)
        }


photoDecoder : Decoder Photo
photoDecoder =
    succeed Photo
        |> required "url" string
        |> required "size" int
        |> optional "title" string "(untitled)"


thumbnailUrl : String -> String
thumbnailUrl url =
    urlPrefix ++ url


largeUrl : String -> String
largeUrl url =
    urlPrefix ++ "large/" ++ url


urlPrefix : String
urlPrefix =
    "http://elm-in-action.com/"
