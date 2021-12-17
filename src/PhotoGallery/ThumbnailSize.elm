module PhotoGallery.ThumbnailSize exposing (ThumbnailSize(..), toString)


type ThumbnailSize
    = Small
    | Medium
    | Large


toString : ThumbnailSize -> String
toString size =
    case size of
        Small ->
            "small"

        Medium ->
            "med"

        Large ->
            "large"
