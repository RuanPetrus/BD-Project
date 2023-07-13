module Page.Disciplina exposing (Model, Msg, view, init, update)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import ErrorMsg exposing ( buildErrorMsg )

import Json.Decode as Decode exposing (..)
import Json.Encode as Encode exposing (..)

type Msg
    = WebData ( Result Http.Error ( Disciplina ) )

type State
    = Showing
    | Loading
    
                    
type alias Model =
    { disciplina : Disciplina
    , disciplinaId : Int
    , errorMsg : Maybe String
    , state : State
    }

type alias Disciplina =
    { nome : String
    , professores : List Professor
    }

type alias Professor =
    { id : Int
    , nome : String
    , qtdAvaliacoes: Int
    , sumAvaliacoes: Int
    }

view : Model -> Html Msg
view model =
    div []
        [  viewDisciplinaOrError model
        ]

viewDisciplinaOrError : Model -> Html Msg
viewDisciplinaOrError model =
    case model.errorMsg of
        Just message ->
            viewError message

        Nothing ->
            viewDisciplina model.disciplina


professorUrl : Int -> String
professorUrl id =
    "/professor/" ++ (String.fromInt  id)

viewDisciplina : Disciplina-> Html Msg
viewDisciplina disciplina =
    div []
        [ h3 [] [ text disciplina.nome ]
        , p [] [ text "Professores:" ]
        , ul [] (List.map viewProfessor disciplina.professores)
        ]

viewProfessor : Professor -> Html Msg
viewProfessor professor =
    li [] [ a [ href ( professorUrl professor.id ) ] [ text professor.nome ] ]

viewError : String -> Html Msg
viewError errorMessage =
    let
        errorHeading =
            "Couldn't fetch disciplina at this time."
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
                Ok disciplina ->
                    ( { model | disciplina = disciplina }, Cmd.none )
                    
                Err httpError ->
                    ( { model | errorMsg = Just (buildErrorMsg httpError) }, Cmd.none )



emptyDisciplina : Disciplina
emptyDisciplina =
    { nome = "", professores = [] }

init : Int -> ( Model, Cmd Msg )
init disciplinaId =
    ( { disciplina = emptyDisciplina
      , disciplinaId = disciplinaId
      , errorMsg = Nothing
      , state = Loading
      }
    , getDisciplina disciplinaId
    )

disciplinaUrl : Int -> String
disciplinaUrl id =
    "http://127.0.0.1:5000/api/disciplina/" ++ (String.fromInt id)

getDisciplina: Int -> Cmd Msg
getDisciplina disciplinaId =
    Http.get
        { url = disciplinaUrl disciplinaId
        , expect = Http.expectJson WebData disciplinaDecoder
        }

disciplinaDecoder: Decoder Disciplina
disciplinaDecoder =
    Decode.map2 Disciplina
        (Decode.field "nome" Decode.string)
        (Decode.field "professores" (Decode.list professorDecoder))

professorDecoder : Decoder Professor
professorDecoder =
    Decode.map4 Professor
        (Decode.field "id" Decode.int)
        (Decode.field "nome" Decode.string)
        (Decode.field "qtd_avaliacoes" Decode.int)
        (Decode.field "sum_avaliacoes" Decode.int)
