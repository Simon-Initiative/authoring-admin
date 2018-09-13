port module Main exposing (main)

import Browser exposing (Document)
import Browser.Navigation as Nav
import Data.Username exposing (Username)
import Debug
import Html exposing (..)
import Json.Decode as Decode exposing (Value)
import Page exposing (Page)
import Page.Home as Home
import Page.NotFound as NotFound
import Page.PackageDetails as PackageDetails
import Page.Packages as Packages
import Page.UserSessions as UserSessions
import Route exposing (Route)
import Session exposing (Session)
import Task
import Time
import Url exposing (Url)
import AppContext exposing (AppContext)
import Theme exposing (Theme, getLightTheme)

port onTokenUpdated : (String -> msg) -> Sub msg



-- WARNING: Based on discussions around how asset management features
-- like code splitting and lazy loading have been shaping up, I expect
-- most of this file to become unnecessary in a future release of Elm.
-- Avoid putting things in here unless there is no alternative!


type Model
    = NotFound AppContext
    | Home AppContext
    | Packages Packages.Model
    | PackageDetails PackageDetails.Model
    | UserSessions UserSessions.Model


type alias Flags =
    { token : String
    , logoutUrl : String
    }



-- MODEL


init : Flags -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url navKey =
    changeRouteTo (Route.fromUrl url)
        (Home (AppContext (Session navKey flags.token) getLightTheme ))



-- VIEW


view : Model -> Document Msg
view model =
    let
        viewPage page toMsg config =
            let
                { title, body } =
                    Page.view page config
            in
            { title = title
            , body = List.map (Html.map toMsg) body
            }
    in
    case model of
        NotFound _ ->
            viewPage Page.Other (\_ -> Ignored) NotFound.view

        Home home ->
            viewPage Page.Home (\_ -> Ignored) Home.view

        Packages packages ->
            viewPage Page.Packages GotPackagesMsg (Packages.view packages)

        PackageDetails details ->
            viewPage Page.PackageDetails GotPackageDetailsMsg (PackageDetails.view details)

        UserSessions sessions ->
            viewPage Page.UserSessions GotSessionsMsg (UserSessions.view sessions)



-- UPDATE


type Msg
    = Ignored
    | TokenUpdated String
    | ChangedRoute (Maybe Route)
    | ChangedUrl Url
    | ClickedLink Browser.UrlRequest
    | GotPackagesMsg Packages.Msg
    | GotPackageDetailsMsg PackageDetails.Msg
    | GotSessionsMsg UserSessions.Msg


toContext : Model -> AppContext
toContext page =
    case page of
        NotFound context ->
            context

        Home context ->
            context

        Packages packages ->
            Packages.toContext packages

        PackageDetails details ->
            PackageDetails.toContext details

        UserSessions sessions ->
            UserSessions.toContext sessions

changeRouteTo : Maybe Route -> Model -> ( Model, Cmd Msg )
changeRouteTo maybeRoute model =
    let
        context =
            toContext model
    in
    case maybeRoute of
        Nothing ->
            ( NotFound context, Cmd.none )

        Just Route.Root ->
            ( model, Route.replaceUrl context.session.navKey Route.Home )

        Just Route.Home ->
            ( Home context, Cmd.none )

        Just Route.Packages ->
            Packages.init context
                |> updateWith Packages GotPackagesMsg model

        Just (Route.PackageDetails resourceId) ->
            PackageDetails.init resourceId context
                |> updateWith PackageDetails GotPackageDetailsMsg model

        Just Route.UserSessions ->
            UserSessions.init context
                |> updateWith UserSessions GotSessionsMsg model



update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model ) of
        ( TokenUpdated token, _ ) ->
            let
                context =
                    toContext model
                session = context.session
            in
            ( updateContext { context | session = { session | token = token } } model, Cmd.none )

        ( Ignored, _ ) ->
            ( model, Cmd.none )

        ( ClickedLink urlRequest, _ ) ->
            case urlRequest of
                Browser.Internal url ->
                    case url.fragment of
                        Nothing ->
                            -- If we got a link that didn't include a fragment,
                            -- it's from one of those (href "") attributes that
                            -- we have to include to make the RealWorld CSS work.
                            --
                            -- In an application doing path routing instead of
                            -- fragment-based routing, this entire
                            -- `case url.fragment of` expression this comment
                            -- is inside would be unnecessary.
                            ( model, Cmd.none )

                        Just _ ->
                            ( model
                            , Nav.pushUrl (toContext model).session.navKey (Url.toString url)
                            )

                Browser.External href ->
                    ( model
                    , Nav.load href
                    )

        ( ChangedUrl url, _ ) ->
            changeRouteTo (Route.fromUrl url) model

        ( ChangedRoute route, _ ) ->
            changeRouteTo route model

        ( GotPackagesMsg subMsg, Packages packages ) ->
            Packages.update subMsg packages
                |> updateWith Packages GotPackagesMsg model

        ( GotPackageDetailsMsg subMsg, PackageDetails details ) ->
            PackageDetails.update subMsg details
                |> updateWith PackageDetails GotPackageDetailsMsg model

        ( GotSessionsMsg subMsg, UserSessions userSessions ) ->
            UserSessions.update subMsg userSessions
                |> updateWith UserSessions GotSessionsMsg model

        ( _, _ ) ->
            -- Disregard messages that arrived for the wrong page.
            ( model, Cmd.none )


updateWith : (subModel -> Model) -> (subMsg -> Msg) -> Model -> ( subModel, Cmd subMsg ) -> ( Model, Cmd Msg )
updateWith toModel toMsg model ( subModel, subCmd ) =
    ( toModel subModel
    , Cmd.map toMsg subCmd
    )

updateContext : AppContext -> Model -> Model
updateContext context model =
    case model of
        NotFound _ ->
            NotFound context

        Home _ ->
            Home context

        Packages courseModel ->
            Packages { courseModel | context = context }

        PackageDetails details ->
            PackageDetails { details | context = context }

        UserSessions sessions ->
            UserSessions { sessions | context = context }


-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        fromModel =
            case model of
                NotFound _ ->
                    []

                Packages packages ->
                    [ Sub.map GotPackagesMsg (Packages.subscriptions packages) ]

                PackageDetails details ->
                    [ Sub.map GotPackageDetailsMsg (PackageDetails.subscriptions details) ]

                Home home ->
                    []

                UserSessions sessions ->
                    [ Sub.map GotSessionsMsg (UserSessions.subscriptions sessions) ]

        subs =
            onTokenUpdated TokenUpdated :: fromModel
    in
    Sub.batch subs



-- MAIN


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , onUrlChange = ChangedUrl
        , onUrlRequest = ClickedLink
        , subscriptions = subscriptions
        , update = update
        , view = view
        }
