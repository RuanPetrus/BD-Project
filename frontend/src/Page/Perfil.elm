module Page.Perfil exposing (Model, Msg, view, init, update)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
import Http
import ErrorMsg exposing ( buildErrorMsg )

import Json.Decode as Decode exposing (..)
import Json.Encode as Encode exposing (..)

type Msg
    = WebData ( Result Http.Error ( User ) )
    | SetNome String
    | SetEmail String
    | SetMatricula String
    | SetCurso String
    | SetNewPassword String
    | SetCurrentPassword String
    | ClickUpdateUser
    | ClickUpdatePassword
    | ClickCancel
    | ClickSendUserUpdate
    | ClickSendPasswordUpdate

type PerfilState
    = Showing
    | UpdatingUser
    | UpdatingPassword

type alias User =
    { email: String
    , nome: String
    , matricula: String
    , curso: String
    }

type alias Model =
    { user: Maybe User
    , updatingUser: User
    , errorMsg : Maybe String
    , state : PerfilState
    , userId: Int
    , passwordInfo : PasswordInfo
    }

type alias PasswordInfo =
    { currentPassword: String
    , newPassword: String
    }

emptyUser : User
emptyUser =
    { email = ""
    , nome  = ""
    , matricula  = ""
    , curso  = ""
    }

emptyPasswordInfo : PasswordInfo
emptyPasswordInfo =
    { currentPassword = ""
    , newPassword = ""
    }

updateNome : Model -> String -> Model
updateNome model value =
    { model | updatingUser = (\u -> { u | nome = value }) model.updatingUser }

updateMatricula : Model -> String -> Model
updateMatricula model value =
    { model | updatingUser = (\u -> { u | matricula = value }) model.updatingUser }

updateCurso : Model -> String -> Model
updateCurso model value =
    { model | updatingUser = (\u -> { u | curso = value }) model.updatingUser }

updateEmail : Model -> String -> Model
updateEmail model value =
    { model | updatingUser = (\u -> { u | email = value }) model.updatingUser }

updateNewPassword : Model -> String -> Model
updateNewPassword model value =
    { model | passwordInfo = (\p -> { p | newPassword = value }) model.passwordInfo }

updateCurrentPassword : Model -> String -> Model
updateCurrentPassword model value =
    { model | passwordInfo = (\p -> { p | currentPassword = value }) model.passwordInfo }

view : Model -> Html Msg
view model =
    div []
        [  viewUserOrError model
        ]

viewUserOrError : Model -> Html Msg
viewUserOrError model =
    case model.errorMsg of
        Just message ->
            viewError message

        Nothing ->
            viewUser model


viewUser : Model -> Html Msg
viewUser model =
    case model.user of
        Just user ->
            case model.state of
                Showing -> 
                    viewUserInfo user
                UpdatingUser ->
                    viewUpdateUser model.updatingUser
                UpdatingPassword ->
                    viewUpdatePassword model.passwordInfo
                    
        Nothing ->
            div [] []

viewUserInfo : User -> Html Msg
viewUserInfo user =
    div []
        [ div []
            [ p []  [ text ("Nome: " ++ user.nome)]
            , p []  [ text ("Email: " ++ user.email)]
            , p []  [ text ("Matricula: " ++ user.matricula)]
            , p []  [ text ("Curso: " ++ user.curso)]
            ]
        , div []
            [ button [ onClick ClickUpdateUser ] [ text "Update" ]
            , button [ onClick ClickUpdatePassword ] [ text "Update Password" ]
            ]
        ]
    
viewUpdateUser : User -> Html Msg
viewUpdateUser user =
    div []
        [ div []
            [ label [ for  "nome" ] [text "Nome:" ]
            , input [ id "nome"
                    , type_ "text"
                    , Html.Attributes.value user.nome, onInput SetNome ]
                    []
            ]
        , div []
            [ label [ for  "email" ] [text "Email:" ]
            , input [ id "email"
                    , type_ "text"
                    , Html.Attributes.value user.email, onInput SetEmail ]
                    []
            ]
        , div []
            [ label [ for  "matricula" ] [text "Matricula:" ]
            , input [ id "matricula"
                    , type_ "text"
                    , Html.Attributes.value user.matricula, onInput SetMatricula ]
                    []
            ]
        , div []
            [ label [ for  "curso" ] [text "Curso:" ]
            , input [ id "curso"
                    , type_ "text"
                    , Html.Attributes.value user.curso, onInput SetCurso ]
                    []
            ]
        , div []
            [ button [ onClick ClickCancel ]     [ text "Cancel" ]
            , button [ onClick ClickSendUserUpdate ] [ text "Update" ]
            ]
        ]

viewUpdatePassword : PasswordInfo -> Html Msg
viewUpdatePassword passwordInfo =
    div []
        [ div []
              [ div []
                    [ label [ for  "currentPassord" ] [text "Current Password:" ]
                    , input [ id "currentPassword"
                            , type_ "password"
                            , Html.Attributes.value passwordInfo.currentPassword, onInput SetCurrentPassword ]
                            []
                    ]
              , div []
                    [ label [ for  "newPassword" ] [text "New Password:" ]
                    , input [ id "newPassword"
                            , type_ "password"
                            , Html.Attributes.value passwordInfo.newPassword, onInput SetNewPassword ]
                            []
                    ]
              ]
        , div []
            [ button [ onClick ClickCancel ]     [ text "Cancel" ]
            , button [ onClick ClickSendPasswordUpdate ] [ text "Update Password" ]
            ]
        ]
      

viewError : String -> Html Msg
viewError errorMessage =
    let
        errorHeading =
            "Couldn't fetch user at this time."
    in
    div []
        [ h3 [] [ text errorHeading ]
        , text ("Error: " ++ errorMessage)
        ]

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        WebData result ->
            case result of 
                Ok user ->
                    ( { model | user = (Just user), updatingUser = user }, Cmd.none )
                    
                Err httpError ->
                    ( { model | errorMsg = Just (buildErrorMsg httpError) }, Cmd.none )
                    
        (SetNome nome) ->
            ( updateNome model nome, Cmd.none )

        (SetMatricula matricula) ->
            ( updateMatricula model matricula, Cmd.none )

        (SetEmail email) ->
            ( updateEmail model email, Cmd.none )

        (SetCurso curso) ->
            ( updateCurso model curso, Cmd.none )

        (SetNewPassword newPassword) ->
            ( updateNewPassword model newPassword, Cmd.none )

        (SetCurrentPassword currentPassword) ->
            ( updateCurrentPassword model currentPassword, Cmd.none )

        ClickUpdateUser ->
            ( { model | state = UpdatingUser }, Cmd.none )

        ClickUpdatePassword ->
            ( { model | state = UpdatingPassword }, Cmd.none )

        ClickCancel ->
            ( { model | state = Showing }, Cmd.none )

        ClickSendUserUpdate ->
            ( model, Cmd.none )

        ClickSendPasswordUpdate ->
            ( model, Cmd.none )

init : Int -> ( Model, Cmd Msg )
init userId =
    ( { user = Nothing
      , errorMsg = Nothing
      , state = Showing
      , updatingUser = emptyUser
      , userId = userId
      , passwordInfo = emptyPasswordInfo
      }
    , getUser userId
    )

userUrl: Int ->  String
userUrl userId =
    "http://127.0.0.1:5000/api/user/" ++ (String.fromInt userId)

getUser : Int -> Cmd Msg
getUser userId =
    Http.get
        { url = userUrl userId
        , expect = Http.expectJson WebData userDecoder
        }

userDecoder : Decoder User
userDecoder =
    Decode.map4 User
        ( Decode.field "email" Decode.string )
        ( Decode.field "nome" Decode.string )
        ( Decode.field "matricula" Decode.string )
        ( Decode.field "curso" Decode.string )
