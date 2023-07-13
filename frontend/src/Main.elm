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
import Page.Disciplina
import Page.Professores
import Page.Turma
import Page.Professor
import Page.Denuncias

import Json.Decode as Decode exposing (..)
import Json.Encode as Encode exposing (..)

type alias User =
    (Int, Bool)

type alias Model =
    { route : Route
    , page : Page
    , navKey : Nav.Key
    , user : Maybe User
    }


type Page
    = NotFoundPage
    | Disciplinas Page.ListDisciplinas.Model
    | Home Page.Home.Model
    | Login Page.Login.Model
    | Perfil Page.Perfil.Model
    | Disciplina Page.Disciplina.Model
    | Professores Page.Professores.Model
    | Turma Page.Turma.Model
    | Professor Page.Professor.Model
    | Denuncias Page.Denuncias.Model


type Msg
    = DisciplinasMsg Page.ListDisciplinas.Msg
    | HomeMsg Page.Home.Msg
    | PerfilMsg Page.Perfil.Msg
    | LoginMsg Page.Login.Msg
    | DisciplinaMsg Page.Disciplina.Msg
    | ProfessoresMsg Page.Professores.Msg
    | TurmaMsg Page.Turma.Msg
    | ProfessorMsg Page.Professor.Msg
    | DenunciasMsg Page.Denuncias.Msg
    | LinkClicked UrlRequest
    | UrlChanged Url

init : (Maybe User) -> Url -> Nav.Key -> ( Model, Cmd Msg )
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
                                    Page.Home.init (Tuple.second user)
                            in
                            ( Home pageModel, Cmd.map HomeMsg pageCmds )

                        Route.Login ->
                            let
                                ( pageModel, pageCmds ) =
                                    Page.Home.init (Tuple.second user)
                            in
                            ( Home pageModel, Cmd.map HomeMsg pageCmds )

                        Route.Perfil ->
                            let
                                ( pageModel, pageCmds ) =
                                    Page.Perfil.init (Tuple.first user)
                            in
                            ( Perfil pageModel, Cmd.map PerfilMsg pageCmds )

                        ( Route.Disciplina  disciplinaId ) ->
                            let
                                ( pageModel, pageCmds ) =
                                    Page.Disciplina.init disciplinaId
                            in
                            ( Disciplina pageModel, Cmd.map DisciplinaMsg pageCmds )

                        Route.Professores ->
                            let
                                ( pageModel, pageCmds ) =
                                    Page.Professores.init
                            in
                            ( Professores pageModel, Cmd.map ProfessoresMsg pageCmds )

                        ( Route.Turma  turmaId ) ->
                            let
                                ( pageModel, pageCmds ) =
                                    Page.Turma.init ( (Tuple.first user), turmaId )
                            in
                            ( Turma pageModel, Cmd.map TurmaMsg pageCmds )

                        ( Route.Professor  professorId ) ->
                            let
                                ( pageModel, pageCmds ) =
                                    Page.Professor.init ( (Tuple.first user), professorId )
                            in
                            ( Professor pageModel, Cmd.map ProfessorMsg pageCmds )

                        Route.Denuncias ->
                            let
                                ( pageModel, pageCmds ) =
                                    Page.Denuncias.init
                            in
                            ( Denuncias pageModel, Cmd.map DenunciasMsg pageCmds )
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

        Disciplina pageModel ->
            Page.Disciplina.view pageModel
                |> Html.map DisciplinaMsg

        Professores pageModel ->
            Page.Professores.view pageModel
                |> Html.map ProfessoresMsg

        Turma pageModel ->
            Page.Turma.view pageModel
                |> Html.map TurmaMsg

        Professor pageModel ->
            Page.Professor.view pageModel
                |> Html.map ProfessorMsg

        Denuncias pageModel ->
            Page.Denuncias.view pageModel
                |> Html.map DenunciasMsg

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

        ( PerfilMsg Page.Perfil.Loggout, Perfil pageModel ) ->
            ( { model | user = Nothing }
            , Cmd.batch [ Nav.pushUrl model.navKey "/login"
                        , removeUserIdFromStorage 0 
                        ]
            )

        ( PerfilMsg ( Page.Perfil.WebDeleteUser ( Ok infoMsg ) ), Perfil pageModel ) ->
            ( { model | user = Nothing }
            , Cmd.batch [ Nav.pushUrl model.navKey "/login"
                        , removeUserIdFromStorage 0
                        ]
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

        ( DisciplinaMsg subMsg, Disciplina pageModel ) ->
            let
                ( updatedPageModel, updatedCmd ) =
                    Page.Disciplina.update subMsg pageModel

            in
            ( { model | page = Disciplina updatedPageModel }
            , Cmd.map DisciplinaMsg updatedCmd
            )

        ( TurmaMsg subMsg, Turma pageModel ) ->
            let
                ( updatedPageModel, updatedCmd ) =
                    Page.Turma.update subMsg pageModel

            in
            ( { model | page = Turma updatedPageModel }
            , Cmd.map TurmaMsg updatedCmd
            )

        ( ProfessorMsg subMsg, Professor pageModel ) ->
            let
                ( updatedPageModel, updatedCmd ) =
                    Page.Professor.update subMsg pageModel

            in
            ( { model | page = Professor updatedPageModel }
            , Cmd.map ProfessorMsg updatedCmd
            )

        ( ProfessoresMsg subMsg, Professores pageModel ) ->
            let
                ( updatedPageModel, updatedCmd ) =
                    Page.Professores.update subMsg pageModel

            in
            ( { model | page = Professores updatedPageModel }
            , Cmd.map ProfessoresMsg updatedCmd
            )

        ( DenunciasMsg subMsg, Denuncias pageModel ) ->
            let
                ( updatedPageModel, updatedCmd ) =
                    Page.Denuncias.update subMsg pageModel

            in
            ( { model | page = Denuncias updatedPageModel }
            , Cmd.map DenunciasMsg updatedCmd
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

        (_, _) ->
            (model, Cmd.none)

main : Program (Maybe User) Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        , onUrlRequest = LinkClicked
        , onUrlChange = UrlChanged
        }

port sendUserIdToStorage : User -> Cmd msg
port removeUserIdFromStorage : Int -> Cmd msg
