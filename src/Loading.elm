module Loading exposing (error, icon, slowThreshold)

{-| A loading spinner icon.
-}

import Asset
import Html.Styled exposing (Attribute, Html, img, text)
import Html.Styled.Attributes exposing (alt, height, src, width)
import Process
import Task exposing (Task)


icon : Html msg
icon =
    img
        [ Asset.src Asset.loading
        , width 64
        , height 64
        , alt "Loading..."
        ]
        []


error : String -> Html msg
error str =
    text ("Error loading " ++ str ++ ".")


slowThreshold : Task x ()
slowThreshold =
    Process.sleep 500
