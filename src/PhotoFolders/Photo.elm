module PhotoFolders.Photo exposing (Photo)


type alias Photo =
    { title : String, size : Int, relatedUrls : List String, url : String }
