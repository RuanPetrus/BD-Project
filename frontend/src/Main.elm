port module Main exposing (..)

import Browser.Navigation as Nav
import Browser exposing (UrlRequest, Document)
import Url exposing (Url)
import Html exposing (..)

import Route exposing (Route)
import Page.ListDisciplinas
import Page.Home
import Page.Login
import Page.Perfil


type alias Model =
    { route : Route
    , page : Page
    , navKey : Nav.Key
    , user : Maybe Int
    }


type Page
    = NotFoundPage
    | Disciplinas Page.ListDisciplinas.Model
    | Home Page.Home.Model
    | Login Page.Login.Model
    | Perfil Page.Perfil.Model


type Msg
    = DisciplinasMsg Page.ListDisciplinas.Msg
    | HomeMsg Page.Home.Msg
    | PerfilMsg Page.Perfil.Msg
    | LoginMsg Page.Login.Msg
    | LinkClicked UrlRequest
    | UrlChanged Url
      

init : (Maybe Int) -> Url -> Nav.Key -> ( Model, Cmd Msg )
init user url navKey =
    let
        model =
            { route = Route.parseUrl url
            , page = NotFoundPage
            , navKey = navKey
            , user = user
            }
    in
    initCurrentPage ( model, Cmd.none )

initCurrentPage : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
initCurrentPage ( model, existingCmds ) =
    case model.user of
        Just user ->
            let
                ( currentPage, mappedPageCmds ) =
                    case model.route of
                        Route.NotFound ->
                            ( NotFoundPage, Cmd.none )

                        Route.Disciplinas ->
                            let
                                ( pageModel, pageCmds ) =
                                    Page.ListDisciplinas.init
                            in
                            ( Disciplinas pageModel, Cmd.map DisciplinasMsg pageCmds )

                        Route.Home ->
                            let
                                ( pageModel, pageCmds ) =
                                    Page.Home.init
                            in
                            ( Home pageModel, Cmd.map HomeMsg pageCmds )

                        Route.Login ->
                            let
                                ( pageModel, pageCmds ) =
                                    Page.Home.init
                            in
                            ( Home pageModel, Cmd.map HomeMsg pageCmds )

                        Route.Perfil ->
                            let
                                ( pageModel, pageCmds ) =
                                    Page.Perfil.init user
                            in
                            ( Perfil pageModel, Cmd.map PerfilMsg pageCmds )

                        ( Route.Turma turmaId ) ->
                            ( NotFoundPage, Cmd.none )
            in
            ( { model | page = currentPage }
            , Cmd.batch [ existingCmds, mappedPageCmds ]
            )
            
        Nothing ->
            let ( pageModel, pageCmds ) =
                    Page.Login.init
            in
            ( { model | page = (Login pageModel), route = Route.Login }
            , Cmd.map LoginMsg pageCmds
            )

view : Model -> Document Msg
view model =
    { title = "Post App"
    , body = [ currentView model ]
    }

currentView : Model -> Html Msg
currentView model =
    case model.page of
        NotFoundPage ->
            notFoundView

        Disciplinas pageModel ->
            Page.ListDisciplinas.view pageModel
                |> Html.map DisciplinasMsg

        Home pageModel ->
            Page.Home.view pageModel
                |> Html.map HomeMsg

        Login pageModel ->
            Page.Login.view pageModel
                |> Html.map LoginMsg

        Perfil pageModel ->
            Page.Perfil.view pageModel
                |> Html.map PerfilMsg

notFoundView : Html msg
notFoundView =
    h3 [] [ text "Oops! The page you requested was not found!" ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model.page ) of
        ( DisciplinasMsg subMsg, Disciplinas pageModel ) ->
            let
                ( updatedPageModel, updatedCmd ) =
                    Page.ListDisciplinas.update subMsg pageModel

            in
            ( { model | page = Disciplinas updatedPageModel }
            , Cmd.map DisciplinasMsg updatedCmd
            )

        ( HomeMsg subMsg, Home pageModel ) ->
            let
                ( updatedPageModel, updatedCmd ) =
                    Page.Home.update subMsg pageModel

            in
            ( { model | page = Home updatedPageModel }
            , Cmd.map HomeMsg updatedCmd
            )

        ( PerfilMsg subMsg, Perfil pageModel ) ->
            let
                ( updatedPageModel, updatedCmd ) =
                    Page.Perfil.update subMsg pageModel

            in
            ( { model | page = Perfil updatedPageModel }
            , Cmd.map PerfilMsg updatedCmd
            )

        ( LoginMsg subMsg, Login pageModel ) ->
            let
                ( updatedPageModel, updatedCmd ) =
                    Page.Login.update subMsg pageModel

            in
                case updatedPageModel.user of
                    Just user ->
                        ( { model | user = (Just user) }
                        , Cmd.batch [ Nav.pushUrl model.navKey "/home"
                                    , sendUserIdToStorage user
                                    ]
                        )

                        
                    Nothing ->
                        ( { model | page = Login updatedPageModel }
                        , Cmd.map LoginMsg updatedCmd
                        )
                        
            
        ( LinkClicked urlRequest, _ ) ->
            case urlRequest of
                Browser.Internal url ->
                    ( model
                    , Nav.pushUrl model.navKey (Url.toString url)
                    )

                Browser.External url ->
                    ( model
                    , Nav.load url
                    )

        ( UrlChanged url, _ ) ->
            let
                newRoute =
                    Route.parseUrl url
            in
            ( { model | route = newRoute }, Cmd.none )
                |> initCurrentPage

        ( _, _ ) ->
            ( model, Cmd.none )


main : Program (Maybe Int) Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        , onUrlRequest = LinkClicked
        , onUrlChange = UrlChanged
        }

port sendUserIdToStorage: Int -> Cmd msg
