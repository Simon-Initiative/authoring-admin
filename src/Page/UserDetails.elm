module Page.UserDetails exposing (Model, Msg, init, subscriptions, toSession, update, view)

import Browser.Navigation as Nav
import Data.Guid as Guid exposing (Guid)
import Data.Resource as Resource exposing (Resource, ResourceState)
import Data.ResourceId as ResourceId exposing (ResourceId)
import Data.User as User exposing (PackageMembership, User, retrieveUsers)
import Data.UserDetails as UserDetails exposing (retrieveUserDetails, resetPassword)
import Html exposing (Html, button, div, fieldset, h1, h3, h4, input, li, text, textarea, ul)
import Html.Attributes exposing (attribute, class, placeholder, type_, value)
import Html.Events exposing (onInput, onSubmit, onClick)
import Http
import Json.Decode as Decode exposing (Decoder, decodeString, field, list, string)
import Json.Decode.Pipeline exposing (hardcoded, required)
import Json.Encode as Encode
import Loading
import Log
import Route
import Session exposing (Session)
import Task
import Time


-- MODEL


type alias Model =
    { session : Session
    , status : Status
    }


type Status
    = Loading
    | LoadingSlowly
    | Loaded User
    | Failed Http.Error


init : Guid -> Session -> ( Model, Cmd Msg )
init userId session =
    ( { session = session, status = Loading }
    , Cmd.batch
        [ UserDetails.retrieveUserDetails userId session.token
            |> Http.send RetrievedDetails
        , Task.perform (\_ -> PassedSlowLoadThreshold) Loading.slowThreshold
        ]
    )


-- VIEW


viewDetails : User -> Html Msg
viewDetails user =
    div []
        [ h3 [] [ text <| user.firstName ++ " " ++ user.lastName ]
        , h4 [] 
            [ text <| user.email ++ " "
            -- , button [ onClick (ResetPasswordRequest user.id) ] [ text <| "Reset Password" ] 
            ]
        , viewPackages user.packages
        ]


viewPackages : List PackageMembership -> Html Msg
viewPackages packages =
    ul [] (List.map (\p -> li [] [ text p.title ]) packages)


view : Model -> { title : String, content : Html Msg }
view model =
    { title = "User Details"
    , content =
        div [ class "details-page" ]
            [ case model.status of
                Loaded details ->
                    viewDetails details

                Loading ->
                    text ""

                LoadingSlowly ->
                    Loading.icon

                Failed err ->
                    case err of
                        Http.BadStatus response ->
                            text <| "bad status: " ++ response.status.message


                        Http.BadPayload msg response ->
                            text msg

                        _ ->
                            text "error"
            ]
    }



-- UPDATE


type Msg
    = RetrievedDetails (Result Http.Error User)
    | PassedSlowLoadThreshold
    | ResetPasswordRequest Guid
    | PasswordReset (Result Http.Error User)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        RetrievedDetails (Ok details) ->
            ( { model | status = Loaded details }
            , Cmd.none
            )

        RetrievedDetails (Err err) ->
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

        ResetPasswordRequest userId ->
            ( model
            , resetPassword userId model.session.token
                |> Http.send PasswordReset
            )
        
        PasswordReset (Ok _) -> 
            ( model, Cmd.none )

        PasswordReset (Err _) -> 
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- EXPORT


toSession : Model -> Session
toSession model =
    model.session
