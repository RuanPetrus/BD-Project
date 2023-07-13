# Front end

O front end do projeto depende de:
- [npm](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm)
- [elm](https://guide.elm-lang.org/install/elm.html)

Installando o elm-live

```sh
# Using NPM
npm install elm-live
# or 
# Using Yarn
yarn add elm-live
```

Rode o front end com o comando
```sh
elm-live src/Main.elm  --pushstate -- --output=main.js
```

O projeto estará agora disponível em http://localhost:8000