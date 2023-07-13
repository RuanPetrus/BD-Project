# Requirements
O projeto possui as seguintes dependencias:
- Python 3.11 [python](https://www.python.org/)
- SGBD postgres. [postgres](https://www.postgresql.org/download/).
- psql [link](https://www.timescale.com/blog/how-to-install-psql-on-mac-ubuntu-debian-windows/)

O projeto também foi feito no Linux, então o funcionamento no Windows não é garantido.

# Database
Crie um banco de dados com o nome que preferir, chamaremos de _database\_name_
Encontre as informações de _hostname_, _user\_name_ e a porta geralmente 5432

*Dentro da pasta backend*

Para criar as tabelas utilizaremos o *psql* com a seguinte sintaxe
``` sh
psql -h hostname -d database_name -U user_name -p 5432 -a -q -f ./sql/create_tables.sql
```
No meu caso:
- database_name = emigue
- hostname = 172.17.0.2
- user_name = postgres
- porta = 5432

Então o comando completo fica:
``` sh
psql -h 172.17.0.2 -d emigue -U postgres -p 5432 -a -q -f ./sql/create_tables.sql
```
# Servidor
Criaremos um ambiente virtual e instaleremos as bibliotecas necessárias:
```sh
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

Precisa modificar o arquivo *dev.env* com as informações necessárias do banco de dados. Exemplo no meu caso:
```env
HOST_DB=172.17.0.2
NAME_DB=emigue
USER_DB=postgres
PORT_DB=5432
PASSWORD_DB=1234
```

Agora popularemos o banco de dados:
```sh
python seed.py
```
Podemos rodar o servidor backend:
```sh
uvicorn main:app --port 5000
```
