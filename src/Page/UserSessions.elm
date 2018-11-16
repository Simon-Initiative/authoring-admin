module Page.UserSessions exposing (Model, Msg, init, subscriptions, toContext, update, view)

import AppContext exposing (AppContext)
import Browser.Navigation as Nav
import Css exposing (..)
import Data.SessionClient exposing (SessionClient, retrieveSessionClients)
import Data.UserSession exposing (UserSession, logoutAllUsers, logoutUser, retrieveUserSessions)
import Html.Styled exposing (Html, a, button, div, fieldset, h1, i, input, li, table, tbody, td, text, textarea, th, thead, toUnstyled, tr, ul)
import Html.Styled.Attributes exposing (attribute, class, css, placeholder, type_, value)
import Html.Styled.Events exposing (onClick, onInput, onSubmit)
import Http
import Json.Decode as Decode exposing (Decoder, decodeString, field, list, string)
import Json.Decode.Pipeline exposing (hardcoded, required)
import Json.Encode as Encode
import List.Extra
import Loading
import Log
import Route
import Task
import Theme exposing (globalThemeStyles)
import Time exposing (..)



-- MODEL


type alias Model =
    { context : AppContext
    , status : Status
    }


type Status
    = Loading
    | LoadingSlowly
    | Loaded (List UserSession)
    | Failed Http.Error


init : AppContext -> ( Model, Cmd Msg )
init context =
    ( { context = context
      , status = Loading
      }
    , Cmd.batch
        [ retrieveSessionClients context.session.token context.baseUrl
            |> Http.send RetrievedClientSessions
        , Task.perform (\_ -> PassedSlowLoadThreshold) Loading.slowThreshold
        ]
    )



-- VIEW


toUSMonth : Month -> String
toUSMonth month =
    case month of
        Jan ->
            "January"

        Feb ->
            "February"

        Mar ->
            "March"

        Apr ->
            "April"

        May ->
            "May"

        Jun ->
            "June"

        Jul ->
            "July"

        Aug ->
            "August"

        Sep ->
            "September"

        Oct ->
            "October"

        Nov ->
            "November"

        Dec ->
            "December"


toStandardHours : Int -> String
toStandardHours hours =
    if hours > 0 && hours <= 12 then
        String.fromInt hours

    else if hours > 12 then
        String.fromInt (hours - 12)

    else
        String.fromInt hours


toStandardMinutes : Int -> String
toStandardMinutes minutes =
    if minutes < 10 then
        "0" ++ String.fromInt minutes

    else
        String.fromInt minutes


formatTime time =
    let
        date =
            Time.millisToPosix time

        hour =
            toStandardHours (Time.toHour Time.utc date)

        minutes =
            toStandardMinutes (Time.toMinute Time.utc date)

        ampm =
            case Time.toHour Time.utc date < 12 of
                True ->
                    "AM"

                False ->
                    "PM"
    in
    toUSMonth (Time.toMonth Time.utc date)
        ++ " "
        ++ String.fromInt (Time.toDay Time.utc date)
        ++ ", "
        ++ String.fromInt (Time.toYear Time.utc date)
        ++ " at "
        ++ hour
        ++ ":"
        ++ minutes
        ++ " "
        ++ ampm


viewSessions : List UserSession -> Html Msg
viewSessions userSessions =
    let
        rows =
            List.map
                (\s ->
                    tr []
                        [ td [] [ text s.username ]
                        , td [] [ text s.ipAddress ]
                        , td [] [ text (formatTime s.start) ]
                        , td [] [ text (formatTime s.lastAccess) ]
                        , td []
                            [ button [ class "pure-button", onClick (LogoutUser s.userId) ]
                                [ text "Logout" ]
                            ]
                        ]
                )
                userSessions
    in
    table [ class "pure-table" ]
        [ thead []
            [ tr []
                [ th [] [ text "Username" ]
                , th [] [ text "IP Address" ]
                , th [] [ text "Start" ]
                , th [] [ text "Last Access" ]
                , th [] [ text "Actions" ]
                ]
            ]
        , tbody [] rows
        ]


view : Model -> { title : String, content : Html Msg }
view model =
    let
        toolbarStyle =
            [ displayFlex
            , flexDirection row
            , margin2 (px 20) (px 0)
            ]
    in
    { title = "Active User Sessions"
    , content =
        div [ class "user-sessions-page" ]
            [ globalThemeStyles model.context.theme
            , div [ css toolbarStyle ]
                [ div []
                    [ button
                        [ class "button-error pure-button"
                        , onClick LogoutAllUsers
                        ]
                        [ text "Logout All" ]
                    ]
                , div [ css [ flex (int 1) ] ] []
                , div []
                    [ button
                        [ class "button-secondary pure-button"
                        , css [ marginRight (px 10) ]
                        , onClick RefreshSessions
                        ]
                        [ i
                            [ class "icon-loop2", css [ marginRight (px 8) ] ]
                            []
                        , text "Refresh"
                        ]
                    ]
                ]
            , div []
                [ case model.status of
                    Loaded userSessions ->
                        viewSessions userSessions

                    Loading ->
                        text "Loading..."

                    LoadingSlowly ->
                        -- Loading.icon
                        text "Loading..."

                    Failed err ->
                        case err of
                            Http.BadStatus response ->
                                text "bad status"

                            Http.BadPayload msg response ->
                                text msg

                            _ ->
                                text "error"
                ]
            ]
    }



-- UPDATE


type Msg
    = RetrievedClientSessions (Result Http.Error (List SessionClient))
    | RetrievedUserSessions (Result Http.Error (List UserSession))
    | PassedSlowLoadThreshold
    | LogoutAllUsers
    | CompletedLogoutAllUsers (Result Http.Error ())
    | LogoutUser String
    | CompletedLogoutUser (Result Http.Error ())
    | RefreshSessions


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        RetrievedClientSessions (Ok sessionClients) ->
            let
                maybeAccountClient =
                    List.Extra.find (\c -> c.clientId == "content_client") sessionClients
            in
            ( model
            , case maybeAccountClient of
                Just accountClient ->
                    retrieveUserSessions (toContext model).session.token accountClient.id (toContext model).baseUrl
                        |> Http.send RetrievedUserSessions

                Nothing ->
                    Cmd.none
            )

        RetrievedClientSessions (Err err) ->
            ( { model | status = Failed err }
            , Cmd.none
            )

        RetrievedUserSessions (Ok userSessions) ->
            ( { model | status = Loaded userSessions }
            , Cmd.none
            )

        RetrievedUserSessions (Err err) ->
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

        LogoutAllUsers ->
            ( model
            , logoutAllUsers (toContext model).session.token (toContext model).baseUrl
                |> Http.send CompletedLogoutAllUsers
            )

        CompletedLogoutAllUsers (Ok _) ->
            ( model, Route.replaceUrl (toContext model).session.navKey Route.Home )

        CompletedLogoutAllUsers (Err err) ->
            init (toContext model)

        LogoutUser userId ->
            ( model
            , logoutUser (toContext model).session.token userId (toContext model).baseUrl
                |> Http.send CompletedLogoutUser
            )

        CompletedLogoutUser (Ok _) ->
            init (toContext model)

        CompletedLogoutUser (Err err) ->
            init (toContext model)

        RefreshSessions ->
            init (toContext model)



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- EXPORT


toContext : Model -> AppContext
toContext model =
    model.context
