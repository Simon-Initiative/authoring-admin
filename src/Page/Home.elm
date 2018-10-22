port module Page.Home exposing (Model, Msg(..), customDecoder, init, setStorage, subscriptions, targetValueTheme, toContext, update, view)

import AppContext exposing (..)
import Browser.Dom as Dom
import Css exposing (..)
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (..)
import Json.Decode as Json
import Json.Encode exposing (encode, string)
import Theme exposing (getTheme, globalThemeStyles, parseTheme)


port setStorage : String -> Cmd msg



-- MODEL


type alias Model =
    { context : AppContext }


init : AppContext -> ( Model, Cmd Msg )
init context =
    ( { context = context }
    , Cmd.none
    )



-- VIEW


view : Model -> { title : String, content : Html Msg }
view model =
    let
        isSelected val =
            case model.context.theme of
                Theme.Light ->
                    val == "light"

                Theme.Dark ->
                    val == "dark"
    in
    { title = "Course Editor Admin"
    , content =
        div []
            [ globalThemeStyles model.context.theme
            , p [] [ text "Welcome to the Course Editor Admin application." ]
            , div []
                [ div [ class "pure-u-1 pure-u-md-1-3" ]
                    [ label [ css [ marginRight (px 10) ] ] [ text "Theme:" ]

                    -- , select [ id "state", class "pure-input-1-2", onInput SelectTheme]
                    , select [ id "state", class "pure-input-1-2", on "change" (Json.map SetTheme targetValueTheme) ]
                        [ option [ value "light", selected (isSelected "light") ] [ text "Light" ]
                        , option [ value "dark", selected (isSelected "dark") ] [ text "Dark" ]
                        ]
                    ]
                ]
            ]
    }

-- modified decoder from https://github.com/elm-community/html-extra/blob/2.2.0/src/Html/Events/Extra.elm
customDecoder : Json.Decoder a -> (a -> Result String b) -> Json.Decoder b
customDecoder d f =
    let
        resultDecoder x =
            case x of
                Ok a ->
                    Json.succeed a

                Err e ->
                    Json.fail e
    in
    Json.map f d |> Json.andThen resultDecoder


targetValueTheme : Json.Decoder Theme.Theme
targetValueTheme =
    customDecoder targetValue
        (\s ->
            Ok <| parseTheme s
        )



-- UPDATE


type Msg
    = SetTheme Theme.Theme


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetTheme theme ->
            let
                context =
                    toContext model
            in
            ( { model | context = { context | theme = theme } }, Cmd.batch [ setStorage (getTheme theme).name ] )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- EXPORT


toContext : Model -> AppContext
toContext model =
    model.context
