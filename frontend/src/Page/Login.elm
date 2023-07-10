module Page.Login exposing (Model, Msg(..), view, init, update)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
import Http

import Json.Decode as Decode exposing (..)
import Json.Encode as Encode exposing (..)

import ErrorMsg exposing ( buildErrorMsg )

type Msg
    = SetEmail String
    | SetPassword String
    | ClickLogin
    | WebData ( Result Http.Error ( Int ) )

type alias Model =
    { email: String
    , password: String
    , errorMsg: Maybe String
    , user: Maybe Int
    }


view : Model -> Html Msg
view model =
    div []
        [ h3 [] [text "Página Login"]
        , viewError model.errorMsg
        , div []
            [ label [ for  "email" ] [text "Email:" ]
            , input [ id "email"
                    , type_ "text"
                    , Html.Attributes.value model.email, onInput SetEmail ]
                    []
            ]
        , div []
            [ label [ for  "password" ] [text "Password:" ]
            , input [ id "password"
                    , type_ "password"
                    , Html.Attributes.value model.password, onInput SetPassword ]
                    []
            ]
        , div []
            [ button [ onClick ClickLogin ] [ text "Login" ]
            ]
        ]

viewError : Maybe String -> Html Msg
viewError errorMessage =
    case errorMessage of
        Nothing ->
            div [] []
        Just msg ->
            div []
                [ h3 [] [ text "Fail to login" ]
                , text ("Error: " ++ msg)
                ]


loginUrl : String
loginUrl =
    "http://127.0.0.1:5000/api/user"

authUserCmd : Model -> String -> Cmd Msg
authUserCmd model apiUrl =
    Http.request
        { method = "POST"
        , url = apiUrl
        , body = Http.jsonBody (userEncoder model)
        , expect = Http.expectJson WebData userDecoder
        , headers = []
        , timeout = Nothing
        , tracker = Nothing
        }


userEncoder : Model -> Encode.Value
userEncoder model =
    Encode.object
        [ ("email", Encode.string model.email)
        , ("password", Encode.string model.password)
        ]

userDecoder : Decoder Int
userDecoder =
    Decode.field "user_id" Decode.int

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetEmail email ->
            ( { model | email = email },  Cmd.none )

        SetPassword password ->
            ( { model | password = password }, Cmd.none )

        ClickLogin ->
            ( model, authUserCmd model loginUrl )

        WebData result ->
            case result of 
                Ok user ->
                    ( { model | user = (Just user) } , Cmd.none )
                    
                Err httpError ->
                    ( { model | errorMsg = (Just ( buildErrorMsg httpError )) }, Cmd.none )
                    

init : ( Model, Cmd Msg )
init =
    ( { email = ""
      , password = ""
      , errorMsg = Nothing
      , user = Nothing
      }
    , Cmd.none
    )
