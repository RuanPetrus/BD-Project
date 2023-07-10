INSERT INTO Departamentos(nome) 
VALUES 
    ('CIC'),
    ('MAT'),
    ('EST');


INSERT INTO Professores (nome, departamento_id)
VALUES
    ('João Gomes', (SELECT id FROM Departamentos WHERE nome='CIC')),
    ('Luan Lemos', (SELECT id FROM Departamentos WHERE nome='CIC')),
    ('Rodrigo José', (SELECT id FROM Departamentos WHERE nome='CIC'));

INSERT INTO Disciplinas (nome, departamento_id)
VALUES
    ('Programação Competitiva', (SELECT id FROM Departamentos WHERE nome='CIC')),
    ('Linguagens de Programação', (SELECT id FROM Departamentos WHERE nome='CIC')),
    ('Organização e Arquitetura de Computadores', (SELECT id FROM Departamentos WHERE nome='CIC'));

INSERT INTO Turmas(numero, professor_id, disciplina_id)
VALUES
    ('01', (SELECT id FROM Professores WHERE nome='João Gomes'), (SELECT id FROM Disciplinas WHERE nome='Programação Competitiva')),
    ('01', (SELECT id FROM Professores WHERE nome='João Gomes'), (SELECT id FROM Disciplinas WHERE nome='Linguagens de Programação')),
    ('01', (SELECT id FROM Professores WHERE nome='João Gomes'), (SELECT id FROM Disciplinas WHERE nome='Organização e Arquitetura de Computadores')),
    ('02', (SELECT id FROM Professores WHERE nome='Luan Lemos'), (SELECT id FROM Disciplinas WHERE nome='Programação Competitiva')),
    ('02', (SELECT id FROM Professores WHERE nome='Luan Lemos'), (SELECT id FROM Disciplinas WHERE nome='Linguagens de Programação')),
    ('02', (SELECT id FROM Professores WHERE nome='Rodrigo José'), (SELECT id FROM Disciplinas WHERE nome='Organização e Arquitetura de Computadores')),
    ('03', (SELECT id FROM Professores WHERE nome='Rodrigo José'), (SELECT id FROM Disciplinas WHERE nome='Programação Competitiva'));

INSERT INTO Users(email, nome, matricula, curso, senha, is_admin)
VALUES
    ('admin@email.com', 'Admin Admin', '000000000', 'CIC', 'admin', true),
    ('ruan@email.com', 'Ruan Petrus',  '211010459', 'CIC', '123', false),
    ('brines@email.com', 'Paulo Brines', '211010459', 'CIC', '123', false);

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

INSERT INTO Denuncias(user_id, avaliacao_id)
VALUES
    ((SELECT id FROM Users WHERE nome='Ruan Petrus'), 1),
    ((SELECT id FROM Users WHERE nome='Ruan Petrus'), 1),
    ((SELECT id FROM Users WHERE nome='Ruan Petrus'), 1);
    
