module Page.NotFound exposing (view)

import Asset
import Html exposing (Html, div, h1, img, main_, p, text)
import Html.Attributes exposing (alt, class, id, src, tabindex)



-- VIEW


view : { title : String, content : Html msg }
view =
    { title = "Page Not Found"
    , content =
        div [ id "content", class "container", tabindex -1 ]
            [ h1 [] [ text "Not Found" ]
            , div [ class "row" ]
                [ p [] [ text "Sorry, that page does not exist" ] ]
            ]
    }
