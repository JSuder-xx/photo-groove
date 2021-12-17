module AppPage exposing (AppPage(..), isActive, photoFoldersL, photoGalleryL)

import Monocle.Optional exposing (Optional)
import PhotoFolders.Model as PhotoFolders
import PhotoGallery.Model as PhotoGallery
import Routing exposing (Route(..))


type AppPage
    = GalleryPage PhotoGallery.Model
    | FoldersPage PhotoFolders.Model
    | NotFound


isActive : { link : Route, page : AppPage } -> Bool
isActive { link, page } =
    case ( link, page ) of
        ( Gallery, GalleryPage _ ) ->
            True

        ( Gallery, _ ) ->
            False

        ( Folders, FoldersPage _ ) ->
            True

        ( Folders, _ ) ->
            False

        ( SelectedPhoto _, _ ) ->
            False


photoGalleryL : Optional AppPage PhotoGallery.Model
photoGalleryL =
    Optional
        (\page ->
            case page of
                GalleryPage m ->
                    Just m

                _ ->
                    Nothing
        )
        (\m _ -> GalleryPage m)


photoFoldersL : Optional AppPage PhotoFolders.Model
photoFoldersL =
    Optional
        (\page ->
            case page of
                FoldersPage m ->
                    Just m

                _ ->
                    Nothing
        )
        (\m _ -> FoldersPage m)
