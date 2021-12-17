module PhotoGallery.Page exposing (Model, init, initialModel, subscriptions, view)

import Data.Function exposing (flip)
import Data.PayloadState as PayloadState exposing (PayloadState(..))
import Effectful.Core exposing (Updater(..), lift)
import External.Elements exposing (rangeSlider)
import External.PastaImageFilter as Filters
import Html exposing (..)
import Html.Attributes exposing (class, classList, id, name, src, title, type_)
import Html.Events exposing (onClick)
import PhotoGallery.Model as Model
import PhotoGallery.Photo exposing (Photo)
import PhotoGallery.ServiceApi as ServiceApi
import PhotoGallery.ThumbnailSize as ThumbnailSize exposing (ThumbnailSize(..))
import Range


type alias Model =
    Model.Model


type alias Msg =
    Updater Model


imageElementId : String
imageElementId =
    "main-canvas"


view : Model -> Html Msg
view model =
    div [ class "content" ] <|
        [ PayloadState.view
            (\( photos, selectedUrl ) -> viewLoaded photos selectedUrl model |> div [])
            model.photosPayloadState
        ]


viewFilters : Model -> Html Msg
viewFilters model =
    let
        viewFilter ( lens, name ) =
            div [ class "filter-slider" ]
                [ label [] [ text name ]
                , rangeSlider
                    { max = Range.upperElement Filters.filterValueRange |> Maybe.map (flip (-) 1) |> Maybe.withDefault 0
                    , val = lens.view model
                    , onSlide = lens.update
                    }
                    []
                    []
                , label [] [ text (String.fromInt (lens.view model)) ]
                ]
    in
    div [ class "filters" ]
        ([ ( Model.hueL imageElementId, "Hue" )
         , ( Model.rippleL imageElementId, "Ripple" )
         , ( Model.noiseL imageElementId, "Noise" )
         ]
            |> List.map viewFilter
        )


viewLoaded : List Photo -> String -> Model -> List (Html Msg)
viewLoaded photos selectedUrl model =
    [ button [ onClick (Model.surpriseMe imageElementId) ] [ text "Surprise Me!" ]
    , div [ class "activity" ] [ text model.activity ]
    , viewFilters model
    , h3 [] [ text "Thumbnail Size:" ]
    , div [ id "choose-size" ]
        (List.map viewSizeChooser [ Small, Medium, Large ])
    , div [ id "thumbnails", class (ThumbnailSize.toString model.chosenSize) ]
        (List.map (viewThumbnail selectedUrl) photos)
    , canvas [ id imageElementId, class "large" ] []
    ]


viewThumbnail : String -> Photo -> Html Msg
viewThumbnail selectedUrl thumb =
    img
        [ src (ServiceApi.thumbnailUrl thumb.url)
        , title (thumb.title ++ " [" ++ String.fromInt thumb.size ++ " KB]")
        , classList [ ( "selected", selectedUrl == thumb.url ) ]
        , onClick (Model.updateSelectUrl imageElementId thumb.url)
        ]
        []


viewSizeChooser : ThumbnailSize -> Html Msg
viewSizeChooser size =
    label []
        [ input [ type_ "radio", name "size", onClick (Model.chosenSizeL.set size |> lift) ] []
        , text (ThumbnailSize.toString size)
        ]


initialModel : Model
initialModel =
    { photosPayloadState = Loading
    , activity = ""
    , chosenSize = Medium
    , filters = Filters.init 5
    }


init : Float -> ( Model, Cmd Msg )
init flags =
    ( Model.activityL.set ("Initializing Pasta v" ++ String.fromFloat flags) initialModel
    , ServiceApi.getPhotos (Model.receivePhotos imageElementId)
    )


subscriptions : Sub Msg
subscriptions =
    Filters.activityChanges (Model.activityL.set >> lift)
