module PhotoFolders.Model exposing (..)

import Data.Path exposing (Path)
import Data.PayloadState as PayloadState exposing (PayloadState(..))
import Monocle.Lens exposing (Lens)
import Monocle.Optional as Optional exposing (Optional)
import PhotoFolders.Folder exposing (Folder)
import PhotoFolders.Folders as Folders exposing (Folders)


type alias Model =
    { selectedPhotoUrl : Maybe String
    , foldersPayloadState : PayloadState Folders
    }


foldersPayloadStateL : Lens Model (PayloadState Folders)
foldersPayloadStateL =
    Lens .foldersPayloadState (\fs m -> { m | foldersPayloadState = fs })


foldersL : Optional Model Folders
foldersL =
    PayloadState.loadedOptional |> Optional.compose (Optional.fromLens foldersPayloadStateL)


selectedPhotoUrlL : Optional Model String
selectedPhotoUrlL =
    Optional .selectedPhotoUrl (\s m -> { m | selectedPhotoUrl = Just s })


selectFolder : Path Folder -> Model -> Model
selectFolder =
    Folders.toggleExpanded >> Optional.modify foldersL
