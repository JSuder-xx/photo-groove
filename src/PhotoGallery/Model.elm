module PhotoGallery.Model exposing (Model, Photos, PhotosPayloadState, activityL, chosenSizeL, hueL, noiseL, receivePhotos, rippleL, surpriseMe, updateSelectUrl)

import Data.PayloadState as PayloadState exposing (PayloadState(..))
import Effectful.Core as Effectful exposing (Updater(..))
import Effectful.Lens as EffectfulLens
import External.PastaImageFilter as Filters exposing (FilterValue, ImageFilters)
import Monocle.Common as Monocle
import Monocle.Lens as Lens exposing (Lens)
import Monocle.Optional as Optional exposing (Optional)
import PhotoGallery.Photo exposing (Photo)
import PhotoGallery.ServiceApi as ServiceApi
import PhotoGallery.ThumbnailSize exposing (ThumbnailSize(..))
import Random


type alias Photos =
    ( List Photo, String )


type alias PhotosPayloadState =
    PayloadState Photos


type alias Model =
    { photosPayloadState : PhotosPayloadState
    , activity : String
    , chosenSize : ThumbnailSize
    , filters : ImageFilters
    }


activityL : Lens Model String
activityL =
    Lens .activity (\a m -> { m | activity = a })


chosenSizeL : Lens Model ThumbnailSize
chosenSizeL =
    Lens .chosenSize (\s m -> { m | chosenSize = s })


photosPayloadStateL : Lens Model PhotosPayloadState
photosPayloadStateL =
    Lens .photosPayloadState (\s m -> { m | photosPayloadState = s })


selectedUrlL : Optional Model String
selectedUrlL =
    Optional.compose
        (Optional.fromLens photosPayloadStateL)
        (Optional.compose PayloadState.loadedOptional (Optional.fromLens Monocle.second))


updateSelectUrl : String -> String -> Updater Model
updateSelectUrl imageElementId url =
    Updater <| selectedUrlL.set url >> applyFilters imageElementId


applyFilters : String -> Model -> ( Model, Cmd msg )
applyFilters id model =
    case .getOption PayloadState.loadedOptional model.photosPayloadState of
        Just ( _, selectedUrl ) ->
            ( model, Filters.apply { url = ServiceApi.largeUrl selectedUrl, id = id } model.filters )

        Nothing ->
            ( model, Cmd.none )


filtersL : Lens Model ImageFilters
filtersL =
    Lens .filters (\f m -> { m | filters = f })


hueL : String -> EffectfulLens.Lens Model FilterValue
hueL imageId =
    EffectfulLens.fromMonocleLens (applyFilters imageId) <| Lens.compose filtersL Filters.hueL


rippleL : String -> EffectfulLens.Lens Model FilterValue
rippleL imageId =
    EffectfulLens.fromMonocleLens (applyFilters imageId) <| Lens.compose filtersL Filters.rippleL


noiseL : String -> EffectfulLens.Lens Model FilterValue
noiseL imageId =
    EffectfulLens.fromMonocleLens (applyFilters imageId) <| Lens.compose filtersL Filters.noiseL


surpriseMe : String -> Updater Model
surpriseMe imageElementId =
    Updater <|
        \model ->
            case .getOption PayloadState.loadedOptional model.photosPayloadState of
                Just ( firstPhoto :: otherPhotos, _ ) ->
                    Random.uniform firstPhoto otherPhotos
                        |> Random.generate (.url >> updateSelectUrl imageElementId)
                        |> Tuple.pair model

                Just ( [], _ ) ->
                    ( model, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )


receivePhotos : String -> Result err (List Photo) -> Updater Model
receivePhotos imageElementId result =
    case result of
        Ok ((photo :: _) as photos) ->
            Updater <|
                photosPayloadStateL.set (Loaded ( photos, photo.url ))
                    >> applyFilters imageElementId

        Ok [] ->
            Effectful.lift <| photosPayloadStateL.set (Errored "0 photos found")

        Err _ ->
            Effectful.lift <| photosPayloadStateL.set (Errored "Server error!")
