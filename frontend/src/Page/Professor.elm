module Page.Professor exposing (Model, Msg, view, init, update)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import ErrorMsg exposing ( buildErrorMsg )

import Json.Decode as Decode exposing (..)
import Json.Encode as Encode exposing (..)

type Msg
    = WebProfessorData ( Result Http.Error ( Professor ) )
    | WebNewAvaliacaoData ( Result Http.Error ( Avaliacao ) )
    | SetComentario String
    | SetPontuacao String
    | ClickNewComentario

type State
    = Showing
    | Loading
    
type alias Model =
    { professor : Professor
    , professorId : Int
    , errorMsg : Maybe String
    , state : State
    , newAvaliacao : NewAvaliacao
    }

type alias Professor =
    { nome : String
    , turmas : List Turma
    , qtdAvaliacoes : Int
    , sumAvaliacoes : Int
    , avaliacoes : List Avaliacao
    }

type alias Turma =
    { id : Int
    , numero: String
    , nome: String
    }

type alias Avaliacao =
    { id : Int
    , userId : Int
    , userNome: String
    , comentario: String
    , pontuacao: Int
    }

type alias NewAvaliacao =
    { userId : Int
    , comentario: String
    , pontuacao: Int
    }

emptyProfessor : Professor
emptyProfessor =
    { nome = ""
    , turmas = []
    , qtdAvaliacoes = 0
    , sumAvaliacoes = 0
    , avaliacoes = []
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
            viewProfessor model


viewProfessor : Model -> Html Msg
viewProfessor model =
    div []
        [ h3 [] [ text ("Nome: " ++ model.professor.nome) ]
        , h3 [] [ text ("Nota: " ++ String.fromInt(model.professor.sumAvaliacoes // model.professor.qtdAvaliacoes)) ]
        , p [] [ text "Turmas:" ]
        , ul [] (List.map viewTurma model.professor.turmas)
        , p [] [ text "Comentarios:" ]
        , ul [] (List.map viewAvaliacao model.professor.avaliacoes)
        , viewAddAvaliacao model.newAvaliacao
        ]

viewAddAvaliacao : NewAvaliacao -> Html Msg
viewAddAvaliacao avaliacao =
    div []
        [ h3 [] [ text "Adicione uma nova avaliação" ]
        , p [] [ text "Sua pontuacao será computada modulo 6" ]
        , div []
            [ label [ for  "comentario" ] [text "Comentario:" ]
            , input [ id "comentario"
                    , type_ "text"
                    , size 100
                    , Html.Attributes.value avaliacao.comentario, onInput SetComentario ]
                    []
            ]
        , div []
            [ label [ for  "pontuacao" ] [text "Pontuacao:" ]
            , input [ id "pontuacao"
                    , type_ "number"
                    , Html.Attributes.value (String.fromInt(avaliacao.pontuacao))
                    , onInput SetPontuacao ]
                    []
            ]
        , div []
            [ button [ onClick ClickNewComentario ] [ text "Comentar" ]
            ]
        ]

viewAvaliacao : Avaliacao -> Html Msg
viewAvaliacao avaliacao =
    div []
        [ hr [] []
        , p [] [ text ("Username: " ++ avaliacao.userNome) ]
        , p [] [ text ("Comentario: " ++ avaliacao.comentario) ]
        , p [] [ text ("Pontuacao: " ++ String.fromInt(avaliacao.pontuacao)) ]
        ]

turmaUrl : Int -> String
turmaUrl id =
    "/turma/" ++ String.fromInt(id)
        
viewTurma : Turma -> Html Msg
viewTurma turma =
    div []
        [ hr [] []
        , p [] [ a [ href ( turmaUrl turma.id ) ] [ text turma.nome ] ]
        , p [] [ text ("Turma: " ++ turma.numero) ]
        ]

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

updateComentario : NewAvaliacao -> String -> NewAvaliacao
updateComentario avaliacao value =
    { avaliacao | comentario = value }

updatePontuacao : NewAvaliacao -> String -> NewAvaliacao
updatePontuacao avaliacao value =
    { avaliacao | pontuacao = ( String.toInt value
                                              |> Maybe.withDefault 0
                                              |> modBy 6)  }


addAvalicao : Professor -> Avaliacao -> Professor
addAvalicao professor avaliacao =
    { professor | avaliacoes = professor.avaliacoes ++ [avaliacao]
    , qtdAvaliacoes = professor.qtdAvaliacoes + 1
    , sumAvaliacoes = professor.sumAvaliacoes + avaliacao.pontuacao
    }
        
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        WebProfessorData result ->
            case result of 
                Ok professor ->
                    ( { model | professor = professor }, Cmd.none )
                    
                Err httpError ->
                    ( { model | errorMsg = Just (buildErrorMsg httpError) }, Cmd.none )

        WebNewAvaliacaoData result ->
            case result of 
                Ok avaliacao ->
                    ( { model | professor = addAvalicao model.professor avaliacao }, Cmd.none )
                    
                Err httpError ->
                    ( { model | errorMsg = Just (buildErrorMsg httpError) }, Cmd.none )

        ( SetComentario comentario ) ->
            ( { model | newAvaliacao = updateComentario model.newAvaliacao comentario }, Cmd.none )
        ( SetPontuacao pontuacao ) ->
            ( { model | newAvaliacao = updatePontuacao model.newAvaliacao pontuacao }, Cmd.none )


        ( ClickNewComentario) ->
            (model, newAvaliacaoCmd model)



init : (Int, Int) -> ( Model, Cmd Msg )
init (userId, professorId) =
    ( { professor = emptyProfessor
      , professorId = professorId
      , errorMsg = Nothing
      , state = Loading
      , newAvaliacao = { userId = userId, comentario = "", pontuacao = 0 }
      }
    , getProfessor professorId
    )

professorUrl : Int -> String
professorUrl id =
    "http://127.0.0.1:5000/api/professor/" ++ (String.fromInt id)

getProfessor: Int -> Cmd Msg
getProfessor professorId =
    Http.get
        { url = professorUrl professorId
        , expect = Http.expectJson WebProfessorData professorDecoder
        }

professorDecoder: Decoder Professor
professorDecoder =
    Decode.map5 Professor
        (Decode.field "nome" Decode.string)
        (Decode.field "turmas" (Decode.list turmaDecoder))
        (Decode.field "qtd_avaliacoes" Decode.int)
        (Decode.field "sum_avaliacoes" Decode.int)
        (Decode.field "avaliacoes" (Decode.list avaliacaoDecoder))

turmaDecoder : Decoder Turma
turmaDecoder =
    Decode.map3 Turma
        (Decode.field "id" Decode.int)
        (Decode.field "numero" Decode.string)
        (Decode.field "nome" Decode.string)

avaliacaoDecoder : Decoder Avaliacao
avaliacaoDecoder =
    Decode.map5 Avaliacao
        (Decode.field "id" Decode.int)
        (Decode.field "user_id" Decode.int)
        (Decode.field "user_nome" Decode.string)
        (Decode.field "comentario" Decode.string)
        (Decode.field "pontuacao" Decode.int)

newAvaliacaoUrl : Int -> String
newAvaliacaoUrl id =
    "http://127.0.0.1:5000/api/professor/" ++ (String.fromInt id) ++ "/avaliacao"

newAvaliacaoEncoder : NewAvaliacao -> Encode.Value
newAvaliacaoEncoder avaliacao =
    Encode.object
        [ ("user_id",  Encode.int avaliacao.userId)
        , ("comentario", Encode.string avaliacao.comentario)
        , ("pontuacao", Encode.int avaliacao.pontuacao)
        ]

newAvaliacaoCmd : Model -> Cmd Msg
newAvaliacaoCmd model =
    Http.request
        { method = "POST"
        , url = newAvaliacaoUrl model.professorId
        , body = Http.jsonBody (newAvaliacaoEncoder model.newAvaliacao)
        , expect = Http.expectJson WebNewAvaliacaoData avaliacaoDecoder
        , headers = []
        , timeout = Nothing
        , tracker = Nothing
        }
