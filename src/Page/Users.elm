module Page.Users exposing (Model, Msg, init, subscriptions, toContext, update, view)

import AppContext exposing (AppContext)
import Browser.Navigation as Nav
import Data.User as User exposing (User, retrieveUsers)
import Data.Username as Username exposing (Username)
import Html.Styled exposing (Html, a, button, div, fieldset, h1, input, li, text, textarea, ul)
import Html.Styled.Attributes exposing (attribute, class, placeholder, type_, value)
import Html.Styled.Events exposing (onInput, onSubmit)
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
      }
    , Cmd.batch
        [ retrieveUsers context.session.token context.baseUrl
            |> Http.send RetrievedUsers
        , Task.perform (\_ -> PassedSlowLoadThreshold) Loading.slowThreshold
        ]
    )



-- VIEW


viewUsers : List User -> Html Msg
viewUsers users =
    let
        listItems =
            List.map (\u -> li [] [ linkTo u.id (Username.toString u.username) ]) users

        linkTo userId title =
            a [ Route.href (Route.UserDetails userId) ] [ text title ]
    in
    ul [] listItems


view : Model -> { title : String, content : Html Msg }
view model =
    { title = "All Course Users"
    , content =
        div [ class "courses-page" ]
            [ globalThemeStyles model.context.theme
            , case model.status of
                Loaded users ->
                    viewUsers users

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



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- EXPORT


toContext : Model -> AppContext
toContext model =
    model.context
