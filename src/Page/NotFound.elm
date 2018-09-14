module Page.NotFound exposing (..)

import Asset
import Html.Styled exposing (Html, toUnstyled, div, h1, img, main_, p, text)
import Html.Styled.Attributes exposing (alt, class, id, src, tabindex)
import Theme exposing (globalThemeStyles)
import AppContext exposing (AppContext)

-- MODEL

type alias Model =
    { context : AppContext }


init : AppContext -> ( Model, Cmd Msg )
init context =
    ( { context = context }
    , Cmd.none
    )


-- VIEW


view : Model -> { title : String, content : Html msg }
view model =
    { title = "Page Not Found"
    , content =
        div [ id "content", class "container", tabindex -1 ]
            [ globalThemeStyles(model.context.theme)
            , h1 [] [ text "Not Found" ]
            , div [ class "row" ]
                [ p [] [ text "Sorry, that page does not exist" ] ]
            ]
    }


-- UPDATE

type Msg
    = Init

-- update : Msg -> Model -> ( Model, Cmd Msg )
-- update msg model =


-- EXPORT

toContext : Model -> AppContext
toContext model =
    model.context
