module Data.Path exposing (Path, atChild, empty, lens)

import Monocle.Common exposing (list)
import Monocle.Lens as Lens exposing (Lens)


type Path a
    = EndOfPath
    | ChildIndex Int (Path a)


empty : Path a
empty =
    EndOfPath


atChild : Int -> Path a -> Path a
atChild index current =
    case current of
        EndOfPath ->
            ChildIndex index EndOfPath

        ChildIndex subfolderIndex remainingPath ->
            ChildIndex subfolderIndex (atChild index remainingPath)


{-| Given a parent/child lens for a recursive data structure and a path then return a lens from a specific parent to that child.
-}
lens : Lens a (List a) -> Path a -> Lens a a
lens parentChildL originalPath =
    let
        get parent =
            let
                aux path current =
                    case path of
                        EndOfPath ->
                            current

                        ChildIndex targetIndex remainingPath ->
                            case .getOption (list targetIndex) (parentChildL.get current) of
                                Nothing ->
                                    current

                                Just child ->
                                    aux remainingPath child
            in
            aux originalPath parent

        set child parent =
            let
                aux path current =
                    case path of
                        EndOfPath ->
                            child

                        ChildIndex targetIndex remainingPath ->
                            current
                                |> Lens.modify parentChildL
                                    (List.indexedMap <|
                                        \index childOfCurrent ->
                                            if index == targetIndex then
                                                aux remainingPath childOfCurrent

                                            else
                                                childOfCurrent
                                    )
            in
            aux originalPath parent
    in
    { get = get
    , set = set
    }
