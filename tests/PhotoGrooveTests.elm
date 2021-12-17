module PhotoGrooveTests exposing (..)

import Data.Function exposing (flip)
import Data.PayloadState exposing (PayloadState(..))
import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, string)
import Html.Attributes as Attr
import Json.Decode exposing (decodeValue)
import Json.Encode as Encode
import PhotoGallery.Page exposing (initialModel, view)
import PhotoGallery.Photo exposing (Photo)
import PhotoGallery.ServiceApi exposing (photoDecoder, thumbnailUrl)
import Test exposing (..)
import Test.Html.Query as Query
import Test.Html.Selector exposing (attribute, tag)


decoderTest : Test
decoderTest =
    fuzz2 string int "title defaults to (untitled)" <|
        \url size ->
            [ ( "url", Encode.string url )
            , ( "size", Encode.int size )
            ]
                |> Encode.object
                |> decodeValue photoDecoder
                |> Result.map .title
                |> Expect.equal (Ok "(untitled)")


noPhotosNoThumbnails : Test
noPhotosNoThumbnails =
    test "No thumbnails render when there are no photos to render." <|
        \_ ->
            initialModel
                |> PhotoGallery.Page.view
                |> Query.fromHtml
                |> Query.findAll [ tag "img" ]
                |> Query.count (Expect.equal 0)


thumbnailRendered : String -> Query.Single msg -> Expectation
thumbnailRendered url query =
    query
        |> Query.findAll [ tag "img", attribute (Attr.src (thumbnailUrl url)) ]
        |> Query.count (Expect.atLeast 1)


photoFromUrl : String -> Photo
photoFromUrl url =
    { url = url, size = 0, title = "" }


withSuffix : String -> String -> String
withSuffix =
    flip String.append


urlsFuzzer : Fuzzer (List String)
urlsFuzzer =
    Fuzz.intRange 1 5
        |> Fuzz.map
            (List.range 1
                >> List.map (String.fromInt >> withSuffix ".png")
            )


thumbnailsWork : Test
thumbnailsWork =
    fuzz urlsFuzzer "URLs render as thumbnails" <|
        \urls ->
            { initialModel | photosPayloadState = Loaded ( List.map photoFromUrl urls, "" ) }
                |> view
                |> Query.fromHtml
                |> Expect.all (List.map thumbnailRendered urls)
