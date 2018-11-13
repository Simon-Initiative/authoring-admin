module Page.Users exposing (Model, Msg, init, subscriptions, toContext, update, view)

import AppContext exposing (AppContext)
import Browser.Navigation as Nav
import Data.User as User exposing (User, retrieveUsers)
import Data.Username as Username exposing (Username)
import Html.Styled exposing (Html, a, button, div, span, form, fieldset, h1, input, li, text, textarea, ul, b)
import Html.Styled.Attributes exposing (attribute, class, placeholder, type_, value, css)
import Html.Styled.Events exposing (onInput, onSubmit)
import Css exposing (..)
import Http
import Json.Decode as Decode exposing (Decoder, decodeString, field, list, string)
import Json.Decode.Pipeline exposing (hardcoded, required)
import Json.Encode as Encode
import Loading
import Log
import Route
import Task
import Theme exposing (globalThemeStyles)



-- MODEL


type alias Model =
    { context : AppContext
    , status : Status
    , filter : String
    }


type Status
    = Loading
    | LoadingSlowly
    | Loaded (List User)
    | Failed Http.Error


init : AppContext -> ( Model, Cmd Msg )
init context =
    ( { context = context
      , status = Loading
      , filter = ""
      }
    , Cmd.batch
        [ retrieveUsers context.session.token context.baseUrl
            |> Http.send RetrievedUsers
        , Task.perform (\_ -> PassedSlowLoadThreshold) Loading.slowThreshold
        ]
    )

nameOrUsername : User -> String
nameOrUsername user =
    if user.firstName == "" && user.lastName == "" then
        Username.toString user.username
    else
        user.firstName ++ " " ++ user.lastName

filterUsers : List User -> String -> List User
filterUsers users filter =
    let
        normalFilter = String.toLower filter
    in
    List.filter (\u ->
        let
            first = String.toLower u.firstName
            last = String.toLower u.lastName
            username = String.toLower (Username.toString u.username)
        in
        String.contains normalFilter first
            || String.contains normalFilter last
            || String.contains normalFilter username) users

-- VIEW


viewUsers : Model -> List User -> Html Msg
viewUsers model users =
    let
        filteredUsers = if model.filter == "" then users else filterUsers users model.filter
        listItems =
            List.map (\u -> li [] [ linkTo u ]) filteredUsers

        linkTo user =
            div []
                [ div [ css [ fontWeight bold ] ]
                    [ a [ Route.href (Route.UserDetails user.id) ] [ text (nameOrUsername user) ] ]
                , div [ css [ color ( rgb 99 110 114 ) ] ]
                    [ span [ css [ marginRight (px 20 ) ] ]
                        [ text (Username.toString user.username)  ]
                    ]
                ]
    in
    div []
    [ div [ css [ marginTop (px 20) ] ]
        [ form [ class "uk-grid-small", attribute "uk-grid" "true" ]
            [ div [ class "uk-width-2-3@s" ] []
            , div [ class "uk-width-1-3@s" ]
                [ div [ class "uk-margin" ]
                    [ div [ class "uk-inline" ]
                        [ span [ class "uk-form-icon", attribute "uk-icon" "icon: search"] []
                        , input [ class "uk-input", placeholder "Search...", onInput ChangeFilter ] []
                        ]
                    ]
                ]
            ]
        ]
    , if List.length filteredUsers > 0 then
        ul [ class "uk-list uk-list-divider" ] listItems
        else
            div [ css [ color ( rgb 99 110 114 ), textAlign center, marginTop (px 50) ] ]
                [ text "No packages match your search criteria" ]
    ]


view : Model -> { title : String, content : Html Msg }
view model =
    { title = "All Course Users"
    , content =
        div [ class "courses-page" ]
            [ globalThemeStyles model.context.theme
            , case model.status of
                Loaded users ->
                    viewUsers model users

                Loading ->
                    text ""

                LoadingSlowly ->
                    Loading.icon

                Failed err ->
                    case err of
                        Http.BadStatus response ->
                            text "bad status"

                        Http.BadPayload msg response ->
                            text msg

                        _ ->
                            text "error"
            ]
    }



-- UPDATE


type Msg
    = RetrievedUsers (Result Http.Error (List User))
    | PassedSlowLoadThreshold
    | ChangeFilter (String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        RetrievedUsers (Ok users) ->
            ( { model | status = Loaded users }
            , Cmd.none
            )

        RetrievedUsers (Err err) ->
            ( { model | status = Failed err }
            , Cmd.none
            )

        PassedSlowLoadThreshold ->
            case model.status of
                Loading ->
                    ( { model | status = LoadingSlowly }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        ChangeFilter filter ->
            ( { model | filter = filter }
            , Cmd.none
            )


-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- EXPORT


toContext : Model -> AppContext
toContext model =
    model.context
