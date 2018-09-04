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
import Page.UserDetails as UserDetails
import Page.Users as Users
import Route exposing (Route)
import Session exposing (Session)
import Task
import Time
import Url exposing (Url)


port onTokenUpdated : (String -> msg) -> Sub msg



-- WARNING: Based on discussions around how asset management features
-- like code splitting and lazy loading have been shaping up, I expect
-- most of this file to become unnecessary in a future release of Elm.
-- Avoid putting things in here unless there is no alternative!


type Model
    = NotFound Session
    | Home Session
    | Packages Packages.Model
    | PackageDetails PackageDetails.Model
    | Users Users.Model
    | UserDetails UserDetails.Model


type alias Flags =
    { token : String
    , logoutUrl : String
    }



-- MODEL


init : Flags -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url navKey =
    changeRouteTo (Route.fromUrl url)
        (Home (Session navKey flags.token))



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

        Users users ->
            viewPage Page.Users GotUsersMsg (Users.view users)

        UserDetails details ->
            viewPage Page.UserDetails GotUserDetailsMsg (UserDetails.view details)



-- UPDATE


type Msg
    = Ignored
    | TokenUpdated String
    | ChangedRoute (Maybe Route)
    | ChangedUrl Url
    | ClickedLink Browser.UrlRequest
    | GotPackagesMsg Packages.Msg
    | GotPackageDetailsMsg PackageDetails.Msg
    | GotUsersMsg Users.Msg
    | GotUserDetailsMsg UserDetails.Msg


toSession : Model -> Session
toSession page =
    case page of
        NotFound session ->
            session

        Home session ->
            session

        Packages packages ->
            Packages.toSession packages

        PackageDetails details ->
            PackageDetails.toSession details

        Users users ->
            Users.toSession users

        UserDetails details ->
            UserDetails.toSession details


changeRouteTo : Maybe Route -> Model -> ( Model, Cmd Msg )
changeRouteTo maybeRoute model =
    let
        session =
            toSession model
    in
    case maybeRoute of
        Nothing ->
            ( NotFound session, Cmd.none )

        Just Route.Root ->
            ( model, Route.replaceUrl session.navKey Route.Home )

        Just Route.Home ->
            ( Home session, Cmd.none )

        Just Route.Packages ->
            Packages.init session
                |> updateWith Packages GotPackagesMsg model

        Just (Route.PackageDetails resourceId) ->
            PackageDetails.init resourceId session
                |> updateWith PackageDetails GotPackageDetailsMsg model

        Just Route.Users -> 
            Users.init session
                |> updateWith Users GotUsersMsg model

        Just (Route.UserDetails resourceId) ->
            UserDetails.init resourceId session
                |> updateWith UserDetails GotUserDetailsMsg model


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model ) of
        ( TokenUpdated token, _ ) ->
            let
                session =
                    toSession model
            in
            ( updateSession { session | token = token } model, Cmd.none )

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
                            , Nav.pushUrl (toSession model).navKey (Url.toString url)
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

        ( GotUsersMsg subMsg, Users users ) ->
            Users.update subMsg users
                |> updateWith Users GotUsersMsg model

        ( GotUserDetailsMsg subMsg, UserDetails details ) ->
            UserDetails.update subMsg details
                |> updateWith UserDetails GotUserDetailsMsg model

        ( _, _ ) ->
            -- Disregard messages that arrived for the wrong page.
            ( model, Cmd.none )


updateWith : (subModel -> Model) -> (subMsg -> Msg) -> Model -> ( subModel, Cmd subMsg ) -> ( Model, Cmd Msg )
updateWith toModel toMsg model ( subModel, subCmd ) =
    ( toModel subModel
    , Cmd.map toMsg subCmd
    )


updateSession : Session -> Model -> Model
updateSession session model =
    case model of
        NotFound _ ->
            NotFound session

        Home _ ->
            Home session

        Packages courseModel ->
            Packages { courseModel | session = session }

        PackageDetails details ->
            PackageDetails { details | session = session }

        Users courseModel ->
            Users { courseModel | session = session }

        UserDetails details ->
            UserDetails { details | session = session }



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

                Users users ->
                    [ Sub.map GotUsersMsg (Users.subscriptions users) ]

                UserDetails details ->
                    [ Sub.map GotUserDetailsMsg (UserDetails.subscriptions details) ]

                Home home ->
                    []

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
