module Data.Bool exposing (decode)


decode : a -> a -> Bool -> a
decode t f b =
    if b then
        t

    else
        f
