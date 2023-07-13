import psycopg
import dotenv
import os

IMAGE_FOLDER = "./images/"

def insert_departamentos(conn):
    with conn.cursor() as curr:
        curr.execute("""
            INSERT INTO Departamentos(nome) 
            VALUES 
                ('CIC'),
                ('MAT'),
                ('EST');
        """) 
    conn.commit()

def insert_professores(conn):
    with open(IMAGE_FOLDER + "joao.jpeg", "rb") as f:
        joao = f.read()

    with open(IMAGE_FOLDER + "luan.jpeg", "rb") as f:
        luan = f.read()

    with open(IMAGE_FOLDER + "rodrigo.jpeg", "rb") as f:
        rodrigo = f.read()

    with conn.cursor() as curr:
        curr.execute("""
            INSERT INTO Professores (nome, departamento_id, img)
            VALUES
                ('João Gomes', (SELECT id FROM Departamentos WHERE nome='CIC'), %s),
                ('Luan Lemos', (SELECT id FROM Departamentos WHERE nome='CIC'), %s),
                ('Rodrigo José', (SELECT id FROM Departamentos WHERE nome='CIC'), %s);
        """, (joao, luan, rodrigo)) 
    conn.commit()

def insert_disciplinas(conn):
    with conn.cursor() as curr:
        curr.execute("""
            INSERT INTO Disciplinas (nome, departamento_id)
            VALUES
                ('Programação Competitiva', (SELECT id FROM Departamentos WHERE nome='CIC')),
                ('Linguagens de Programação', (SELECT id FROM Departamentos WHERE nome='CIC')),
                ('Organização e Arquitetura de Computadores', (SELECT id FROM Departamentos WHERE nome='CIC'));
        """) 
    conn.commit()

def insert_turmas(conn):
    with conn.cursor() as curr:
        curr.execute("""
            INSERT INTO Turmas(numero, professor_id, disciplina_id)
            VALUES
                ('01', (SELECT id FROM Professores WHERE nome='João Gomes'), (SELECT id FROM Disciplinas WHERE nome='Programação Competitiva')),
                ('01', (SELECT id FROM Professores WHERE nome='João Gomes'), (SELECT id FROM Disciplinas WHERE nome='Linguagens de Programação')),
                ('01', (SELECT id FROM Professores WHERE nome='João Gomes'), (SELECT id FROM Disciplinas WHERE nome='Organização e Arquitetura de Computadores')),
                ('02', (SELECT id FROM Professores WHERE nome='Luan Lemos'), (SELECT id FROM Disciplinas WHERE nome='Programação Competitiva')),
                ('02', (SELECT id FROM Professores WHERE nome='Luan Lemos'), (SELECT id FROM Disciplinas WHERE nome='Linguagens de Programação')),
                ('02', (SELECT id FROM Professores WHERE nome='Rodrigo José'), (SELECT id FROM Disciplinas WHERE nome='Organização e Arquitetura de Computadores')),
                ('03', (SELECT id FROM Professores WHERE nome='Rodrigo José'), (SELECT id FROM Disciplinas WHERE nome='Programação Competitiva'));
        """) 
    conn.commit()

def insert_users(conn):
    with conn.cursor() as curr:
        curr.execute("""
            INSERT INTO Users(email, nome, matricula, curso, senha, is_admin)
            VALUES
                ('admin@email.com', 'Admin Admin', '000000000', 'CIC', 'admin', true),
                ('ruan@email.com', 'Ruan Petrus',  '211010459', 'CIC', '123', false),
                ('brines@email.com', 'Paulo Brines', '211010459', 'CIC', '123', false);
        """) 

def insert_avaliacoes(conn):
    with conn.cursor() as curr:
        curr.execute("""
            INSERT INTO Avaliacoes(pontuacao, comentario, user_id, turma_id)
            VALUES
                (5, 'Essa é com certeza a melhor matéria do curso, você aprende muita coisas sobre algoritmos que você jamais saberia caso não tivesse feito. Além disso o professor João é muito bom em explicar', (SELECT id FROM Users WHERE nome='Ruan Petrus'), 1),
                (3, 'Essa matéria aí é de maluco, não vou usar nada disso na minha carreira profissional, e também não entendi nada que o professor Jõao falou', (SELECT id FROM Users WHERE nome='Paulo Brines'), 1),
                (5, 'Achei o professor Luan um fofo', (SELECT id FROM Users WHERE nome='Paulo Brines'), 4),
                (3, 'Muito divertida a matéria', (SELECT id FROM Users WHERE nome='Ruan Petrus'), 4),
                (3, 'Matéria mais difícil do planeta terra', (SELECT id FROM Users WHERE nome='Paulo Brines'), 6),
                (4, 'Eu achei haskell muito divertido', (SELECT id FROM Users WHERE nome='Ruan Petrus'), 5),
                (3, 'Achei que o professor falava muito lento e a prova muito difícil', (SELECT id FROM Users WHERE nome='Paulo Brines'), 5),
                (4, 'Achei a materia OK', (SELECT id FROM Users WHERE nome='Paulo Brines'), 2),
                (4, 'O professor explicava bem', (SELECT id FROM Users WHERE nome='Ruan Petrus'), 3),
                (4, 'Achei a materia interessante', (SELECT id FROM Users WHERE nome='Ruan Petrus'), 7);
        """) 
    conn.commit()

def insert_professor_avaliacoes(conn):
    with conn.cursor() as curr:
        curr.execute("""
            INSERT INTO AvaliacoesProfessores(pontuacao, comentario, user_id, professor_id)
            VALUES
                (5, 'Acho ele um ótimo professor o PIBIC com ele foi ótimo', 2, 1),
                (5, 'Foi um ótimo orientador do meu TG', 3, 2),
                (2, 'Não gostei muito de fazer projeto ZEN com ele', 2, 3);
        """) 
    conn.commit()
    
    
def insert_denuncias(conn):
    with conn.cursor() as curr:
        curr.execute("""
            INSERT INTO Denuncias(avaliacao_id)
            VALUES
                (1),
                (1),
                (1);
        """) 
    conn.commit()

def main():
    dotenv.load_dotenv("./dev.env")
    host = os.getenv("HOST_DB")
    if host is None:
        host = "172.17.0.2"

    db_name = os.getenv("NAME_DB")
    if db_name is None:
        db_name = "emigue"

    user = os.getenv("USER_DB")
    if user is None:
        user = "postgres"

    port = os.getenv("PORT_DB")
    if port is None:
        port = "5432"

    password = os.getenv("PASSWORD_DB")
    if password is None:
        password = "1234"

    with psycopg.connect(
            f"""
            host={host}
            port={port}
            dbname={db_name}
            password={password}
            user={user}
            """
    ) as conn:
        insert_departamentos(conn)
        insert_professores(conn)
        insert_disciplinas(conn)
        insert_turmas(conn)
        insert_users(conn)
        insert_avaliacoes(conn)
        insert_professor_avaliacoes(conn)
        insert_denuncias(conn)


if __name__ == "__main__":
    main()
