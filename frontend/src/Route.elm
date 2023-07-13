module Route exposing (Route(..), parseUrl)

import Url exposing (Url)
import Url.Parser exposing (..)


type Route
    = NotFound
    | Disciplinas
    | Professores
    | Denuncias
    | Home
    | Login
    | Perfil
    | Turma Int
    | Disciplina Int
    | Professor Int


parseUrl : Url -> Route
parseUrl url =
    case parse matchRoute url of
        Just route ->
            route

        Nothing ->
            NotFound


matchRoute : Parser (Route -> a) a
matchRoute =
    oneOf
        [ map Home top
        , map Disciplinas (s "disciplinas")
        , map Home (s "home")
        , map Login (s "login")
        , map Login (s "register")
        , map Perfil (s "perfil")
        , map Turma (s "turma" </> int)
        , map Disciplina (s "disciplina" </> int)
        , map Professor (s "professor" </> int)
        , map Professores (s "professores")
        , map Denuncias (s "denuncias")
        ]
