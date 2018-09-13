module Page.Home exposing (view)

import Browser.Dom as Dom
import Html.Styled exposing (Html, toUnstyled, p, text)


view : { title : String, content : Html msg }
view =
    { title = "Course Editor Admin"
    , content =
        p [] [ text "Welcome to the Course Editor Admin application." ]
    }
