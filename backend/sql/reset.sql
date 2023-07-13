DROP TRIGGER update_avaliacao_professor_on_inserting_avaliacao ON AvaliacoesProfessores;

DROP TABLE Departamentos, Professores, 
                    Disciplinas, Turmas, Users,
                    Avaliacoes, Denuncias, AvaliacoesProfessores
            CASCADE;

DROP FUNCTION update_avaliacao_professor
