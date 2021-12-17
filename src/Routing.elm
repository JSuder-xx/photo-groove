module Routing exposing (Route(..), display, parse, urlString)

import Url exposing (Url)
import Url.Parser as Parser exposing ((</>), Parser)


type Route
    = Gallery
    | Folders
    | SelectedPhoto String


display : Route -> String
display route =
    case route of
        Gallery ->
            "Gallery"

        Folders ->
            "Folders"

        SelectedPhoto _ ->
            "?"


parse : Url -> Maybe Route
parse =
    Parser.parse parser


root : String
root =
    "/"


gallery : String
gallery =
    "gallery"


photos : String
photos =
    "photos"


urlString : Route -> String
urlString route =
    case route of
        Folders ->
            root

        Gallery ->
            root ++ gallery

        SelectedPhoto f ->
            String.join "" [ root, photos, "/", f ]


parser : Parser (Route -> a) a
parser =
    Parser.oneOf
        [ Parser.map Folders Parser.top
        , Parser.map Gallery (Parser.s gallery)
        , Parser.map SelectedPhoto (Parser.s photos </> Parser.string)
        ]
