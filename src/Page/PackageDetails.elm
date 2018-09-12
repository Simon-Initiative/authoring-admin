module Page.PackageDetails exposing (Model, Msg, init, subscriptions, toSession, update, view)

import Browser.Navigation as Nav
import Data.Guid as Guid exposing (Guid)
import Data.Package as Package exposing (Package)
import Data.PackageDetails as PackageDetails exposing (PackageDetails, retrievePackageDetails, hidePackage, lockPackage)
import Data.Resource as Resource exposing (Resource, ResourceState)
import Data.ResourceId as ResourceId exposing (ResourceId)
import Data.Username as Username exposing (Username)
import Html exposing (Html, button, div, fieldset, h1, h3, input, li, text, textarea, ul, label)
import Html.Attributes exposing (attribute, class, placeholder, type_, value, checked)
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

-- MODEL


type alias Model =
    { session : Session
    , status : Status
    }


type Status
    = Loading
    | LoadingSlowly
    | Loaded PackageDetails
    | Failed Http.Error



init : Guid -> Session -> ( Model, Cmd Msg )
init packageId session =
    ( { session = session
      , status = Loading
      }
    , Cmd.batch
        [ retrievePackageDetails packageId session.token
            |> Http.send RetrievedDetails
        , Task.perform (\_ -> PassedSlowLoadThreshold) Loading.slowThreshold
        ]
    )

type Msg
    = RetrievedDetails (Result Http.Error PackageDetails)
    | PassedSlowLoadThreshold
    | ToggleVisible PackageDetails
    | ToggleEditable PackageDetails
    | LockPermission (Result Http.Error PackageDetails.Locked)
    | HidePermission (Result Http.Error PackageDetails.Hidden)


-- VIEW


viewDetails : PackageDetails -> Html Msg
viewDetails details =
    div []
        [ h3 [] [ text details.title ]
        , div [] [
            label [] [
                input [type_ "checkbox"
                , checked <| details.visible
                , onClick <| ToggleVisible details][], text <| " visible"
            ]
            , label [] [
                input [type_ "checkbox"
                , checked <| details.editable
                , onClick <| ToggleEditable details][], text <| " editable"]
            ],
            viewResources details.resources
        ]


viewResources : List Resource -> Html Msg
viewResources resources =
    ul [] (List.map (\p -> li [] [ text p.title ]) resources)


view : Model -> { title : String, content : Html Msg }
view model =
    { title = "Package Details"
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
                            text "bad status"

                        Http.BadPayload msg response ->
                            text msg

                        _ ->
                            text "error"
            ]
    }



-- UPDATE


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
        LockPermission (Ok locked) ->
            ( model
             , Cmd.none
            )
        LockPermission (Err err) ->
            ( model
             , Cmd.none
            )
        HidePermission (Ok hidden) ->
            ( model
             , Cmd.none
            )
        HidePermission (Err err) ->
            ( model
             , Cmd.none
            )
        ToggleVisible details ->
            let
                viz = toggle details.visible
            in
            ({model | status =  Loaded {details | visible = viz}}
            , Cmd.batch
                [ hidePackage details.guid viz model.session.token
                    |> Http.send HidePermission
                ])

        ToggleEditable details ->
            let
                loc = toggle details.editable
            in
             ({model | status = Loaded {details | editable = loc}}
            , Cmd.batch
                [ lockPackage details.guid loc model.session.token
                    |> Http.send LockPermission
                ])

        PassedSlowLoadThreshold ->
            case model.status of
                Loading ->
                    ( { model | status = LoadingSlowly }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )


toggle: Bool -> Bool
toggle bool =
    not bool

-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- EXPORT


toSession : Model -> Session
toSession model =
    model.session
