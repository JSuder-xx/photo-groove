module PhotoFolders.Folder exposing (Folder(..), pathLens, subfoldersL, toggleExpanded)

import Data.Path exposing (Path)
import Monocle.Lens exposing (Lens)


type Folder
    = Folder
        { name : String
        , photoUrls : List String
        , subfolders : List Folder
        , expanded : Bool
        }


subfoldersL : Lens Folder (List Folder)
subfoldersL =
    Lens
        (\(Folder folder) -> folder.subfolders)
        (\subfolders (Folder folder) -> Folder { folder | subfolders = subfolders })


{-| Given a path provide a lens from one folder to another folder.
-}
pathLens : Path Folder -> Lens Folder Folder
pathLens =
    Data.Path.lens subfoldersL


toggleExpanded : Folder -> Folder
toggleExpanded (Folder folder) =
    Folder { folder | expanded = not folder.expanded }
