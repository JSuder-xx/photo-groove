module PhotoFolders.Folders exposing (Folders, photoByUrl, rootFolderL, toggleExpanded)

import Data.Path exposing (Path)
import Dict exposing (Dict)
import Monocle.Lens as Lens exposing (Lens)
import PhotoFolders.Folder exposing (Folder(..))
import PhotoFolders.Photo exposing (Photo)


type alias Folders =
    { photos : Dict String Photo, rootFolder : Folder }


rootFolderL : Lens Folders Folder
rootFolderL =
    { get = \{ rootFolder } -> rootFolder, set = \rootFolder folders -> { folders | rootFolder = rootFolder } }


toggleExpanded : Path Folder -> Folders -> Folders
toggleExpanded path =
    Lens.modify rootFolderL (Lens.modify (PhotoFolders.Folder.pathLens path) PhotoFolders.Folder.toggleExpanded)


photoByUrl : String -> Folders -> Maybe Photo
photoByUrl url { photos } =
    Dict.get url photos
