module Page.Professores exposing (Model, Msg, view, init, update)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import ErrorMsg exposing ( buildErrorMsg )

import Json.Decode as Decode exposing (..)
import Json.Encode as Encode exposing (..)

type Msg
    = WebData ( Result Http.Error ( List Professor ) )

type State
    = Showing
    | Loading
    
                    
type alias Model =
    { professores : List Professor
    , errorMsg : Maybe String
    , state : State
    }

type alias Professor =
    { id : Int
    , nome : String
    , disciplinas : List String
    , qtdAvaliacoes: Int
    , sumAvaliacoes: Int
    }

view : Model -> Html Msg
view model =
    div []
        [  viewProfessorOrError model
        ]

viewProfessorOrError : Model -> Html Msg
viewProfessorOrError model =
    case model.errorMsg of
        Just message ->
            viewError message

        Nothing ->
            viewProfessores model.professores


professorUrl : Int -> String
professorUrl id =
    "/professor/" ++ (String.fromInt  id)

viewProfessores : List Professor -> Html Msg
viewProfessores professores =
    div []
        [ h3 [] [ text "Professores:" ]
        , ul [] (List.map viewProfessor professores)
        ]

viewProfessor : Professor -> Html Msg
viewProfessor professor =
    li [] [ a [ href ( professorUrl professor.id ) ] [ text professor.nome ]
          , ul [] (List.map viewDisciplina professor.disciplinas)
          ]

viewDisciplina : String -> Html Msg
viewDisciplina disciplina =
    li [] [ p [] [ text disciplina ] ]

viewError : String -> Html Msg
viewError errorMessage =
    let
        errorHeading =
            "Couldn't fetch professores at this time."
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
                Ok professores ->
                    ( { model | professores = professores }, Cmd.none )
                    
                Err httpError ->
                    ( { model | errorMsg = Just (buildErrorMsg httpError) }, Cmd.none )



init : ( Model, Cmd Msg )
init =
    ( { professores = []
      , errorMsg = Nothing
      , state = Loading
      }
    , getProfessores
    )

professoresUrl : String
professoresUrl =
    "http://127.0.0.1:5000/api/professores/"

getProfessores: Cmd Msg
getProfessores =
    Http.get
        { url = professoresUrl
        , expect = Http.expectJson WebData (Decode.list professoresDecoder)
        }

professoresDecoder : Decoder Professor
professoresDecoder =
    Decode.map5 Professor
        (Decode.field "id" Decode.int)
        (Decode.field "nome" Decode.string)
        (Decode.field "disciplinas" (Decode.list Decode.string))
        (Decode.field "qtd_avaliacoes" Decode.int)
        (Decode.field "sum_avaliacoes" Decode.int)
