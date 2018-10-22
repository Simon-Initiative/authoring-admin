module Page.TestBed exposing (Model, Msg(..), init, toContext, view)

import AppContext exposing (AppContext)
import Asset
import Html.Styled exposing (Html, div, h1, img, main_, node, p, text, toUnstyled)
import Html.Styled.Attributes exposing (alt, class, id, property, src, tabindex)
import Html.Styled.Lazy exposing (lazy)
import Json.Encode exposing (string)
import Theme exposing (globalThemeStyles)



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
    let
        formula =
            "$\\binom{n}{k} = \\frac{n!}{k!(n-k)!}$"

        encodedFormula =
            string formula

        viewNode a =
            node
                "math-text"
                [ property "content" encodedFormula ]
                []
    in
    { title = "Test bed"
    , content =
        div []
            [ lazy viewNode
                formula
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
