USE FestCine;
GO

--------------------------------------------------------------------------------
-- 1. MAESTROS BÁSICOS Y CATÁLOGOS
--------------------------------------------------------------------------------
-- Ediciones (IdEdicion manual, fechas reales)
INSERT INTO Edicion (IdEdicion, Anio, FechaInicio, FechaFin, Ciudad, Tema) VALUES 
(1, 2025, '2025-10-10', '2025-10-20', 'Santa Cruz de la Sierra', 'Orígenes y Memoria'),
(2, 2026, '2026-10-08', '2026-10-18', 'Santa Cruz de la Sierra', 'Nuevas Fronteras Digitales');
GO

-- Géneros (12)
INSERT INTO Genero (NombreGenero) VALUES 
('Drama'), ('Documental'), ('Comedia'), ('Thriller'), ('Ciencia Ficción'), 
('Animación'), ('Experimental'), ('Romance'), ('Cine Social'), ('Suspenso'),
('Terror'), ('Fantasía');
GO

-- Tarifas (4)
INSERT INTO Tarifa (TipoTarifa, Monto) VALUES 
('General', 40.00), 
('Estudiante', 25.00), 
('VIP', 80.00), 
('Acreditado', 0.00);
GO

-- Tipos de Abono (4)
INSERT INTO TipoAbono (NombreTipoAbono, Descripcion, CantidadMaxProyecciones, PrecioBase) VALUES 
('Pase Cinéfilo', 'Acceso a 5 proyecciones de competencia', 5, 150.00),
('Abono Total', 'Acceso a 12 proyecciones, incluyendo galas', 12, 300.00),
('Pase Industria', 'Acceso para miembros del mercado audiovisual', 10, 200.00),
('Pase Fin de Semana', 'Acceso a 4 funciones de viernes a domingo', 4, 120.00);
GO

-- Patrocinadores (6)
INSERT INTO Patrocinador (NombreEmpresa, Contacto, Email, Telefono) VALUES 
('Banco Bisa', 'Andrea Vaca', 'avaca@bisa.com', '+59170011122'),
('Cerveza Huari', 'Luis Suarez', 'lsuarez@huari.bo', '+59170033344'),
('BoA', 'Mariana Paz', 'mpaz@boa.bo', '+59170055566'),
('Tigo', 'Carlos Arce', 'carce@tigo.bo', '+59170077788'),
('Hotel Los Tajibos', 'Elena Rios', 'erios@lostajibos.com', '+59170088899'),
('Naturaleza Viva', 'Juan Perez', 'contacto@natviva.bo', '+59170099900');
GO

-- Sedes y Salas (4 Sedes, 10 Salas)
INSERT INTO Sede (NombreSede, Direccion, Ciudad) VALUES 
('Cine Center Santa Cruz', 'Segundo Anillo y Av. San Martin', 'Santa Cruz de la Sierra'),
('Centro Cultural CBA', 'Calle Sucre 340', 'Santa Cruz de la Sierra'),
('Casa de la Cultura', 'Plaza 24 de Septiembre', 'Santa Cruz de la Sierra'),
('Centro de Formación AECID', 'Calle Arenales 583', 'Santa Cruz de la Sierra');
GO

INSERT INTO Sala (IdSede, NombreSala, CapacidadAsientos) VALUES 
(1, 'Sala 1 - Principal', 250), -- Id 1
(1, 'Sala 2 - VIP', 80),        -- Id 2
(1, 'Sala 3', 150),             -- Id 3
(1, 'Sala 4 - 35mm', 120),      -- Id 4
(2, 'Auditorio CBA', 120),      -- Id 5
(2, 'Sala Alternativa', 60),    -- Id 6
(3, 'Sala Experimental', 70),   -- Id 7
(3, 'Patio Cultural', 150),     -- Id 8 (Aire libre)
(4, 'Sala Audiovisual AECID', 50),-- Id 9
(4, 'Terraza AECID', 80);       -- Id 10
GO

-- Categorías de Competencia
INSERT INTO CategoriaComp (NombreCategoria, Descripcion) VALUES 
('Mejor Largometraje Iberoamericano', 'Obras de ficción de más de 60 min.'),
('Mejor Documental', 'No ficción nacional e internacional.'),
('Mejor Cortometraje Nacional', 'Obras bolivianas menores a 30 min.'),
('Premio del Público', 'Votación abierta a los asistentes.'),
('Mejor Dirección', 'Reconocimiento a la dirección cinematográfica.'),
('Mejor Fotografía', 'Premio técnico a la dirección de arte visual.');
GO

--------------------------------------------------------------------------------
-- 2. PERSONAL Y PELÍCULAS
--------------------------------------------------------------------------------
-- Personal de Cine (20 Perfiles)
INSERT INTO PersonalCine (NombreCompleto, Nacionalidad, FechaNac, Biografia, Email) VALUES 
('Rodrigo Bellott', 'Boliviana', '1978-10-04', 'Director boliviano.', 'rodrigo@fest.com'),
('Kiro Russo', 'Boliviana', '1984-05-01', 'Director de El Gran Movimiento.', 'kiro@fest.com'),
('Celine Song', 'Canadiense', '1988-01-01', 'Directora de Vidas Pasadas.', 'celine@fest.com'),
('Pedro Almodóvar', 'Española', '1949-09-25', 'Director español.', 'pedro@fest.com'),
('Zendaya', 'Estadounidense', '1996-09-01', 'Actriz y productora.', 'zendaya@fest.com'),
('Gory Patiño', 'Boliviana', '1975-05-15', 'Director de Muralla.', 'gory@fest.com'),
('Ricardo Darín', 'Argentina', '1957-01-16', 'Actor argentino.', 'darin@fest.com'),
('Lucrecia Martel', 'Argentina', '1966-12-14', 'Directora argentina.', 'lucrecia@fest.com'),
('Vinko Tomicic', 'Boliviana', '1987-02-10', 'Director de El ladrón de perros.', 'vinko@fest.com'),
('Pablo Berger', 'Española', '1963-01-01', 'Director de Robot Dreams.', 'pablo@fest.com'),
('Coralie Fargeat', 'Francesa', '1976-01-01', 'Directora de La Sustancia.', 'coralie@fest.com'),
('Denis Villeneuve', 'Canadiense', '1967-10-03', 'Director de Dune.', 'denis@fest.com'),
('Alejandro Loayza Grisi', 'Boliviana', '1985-08-08', 'Director de Utama.', 'alejandro@fest.com'),
('Wim Wenders', 'Alemana', '1945-08-14', 'Director de Perfect Days.', 'wim@fest.com'),
('Anya Taylor-Joy', 'Británica', '1996-04-16', 'Actriz.', 'anya@fest.com'),
('Ciro Guerra', 'Colombia', '1981-02-06', 'Director colombiano.', 'ciro@fest.com'),
('Jayro Bustamante', 'Guatemala', '1977-05-07', 'Director de La Llorona.', 'jayro@fest.com'),
('Diego Luna', 'México', '1979-12-29', 'Actor y productor.', 'diego@fest.com'),
('Gael García Bernal', 'México', '1978-11-30', 'Actor y productor.', 'gael@fest.com'),
('Bong Joon Ho', 'Corea del Sur', '1969-09-14', 'Director de Parasite.', 'bong@fest.com');
GO

-- Películas (30 en total para tener un catálogo gigante)
INSERT INTO Pelicula (Titulo, AnioProduccion, DuracionMin, PaisOrigen, Sinopsis, ClasifEdades, FormatoProyeccion) VALUES 
('El Ladrón de Perros', 2024, 90, 'Bolivia', 'Un joven lustrabotas busca su lugar en La Paz.', '13+', 'Digital'), -- 1
('La Sustancia', 2024, 140, 'Reino Unido', 'Una estrella usa una droga para rejuvenecer.', '18+', 'Digital'), -- 2
('Dune: Parte Dos', 2024, 166, 'EEUU', 'El ascenso de Paul Atreides.', '13+', 'IMAX'), -- 3
('Robot Dreams', 2023, 102, 'España', 'La amistad entre un perro y un robot en NY.', 'TP', 'Digital'), -- 4
('Challengers', 2024, 131, 'EEUU', 'Drama y tensión en el mundo del tenis.', '16+', 'Digital'), -- 5
('Muralla', 2018, 98, 'Bolivia', 'Un ex arquero cae en el bajo mundo.', '16+', 'Digital'), -- 6
('El Gran Movimiento', 2021, 85, 'Bolivia', 'Sinfonía urbana y fiebre en La Paz.', '13+', 'Digital'), -- 7
('Utama', 2022, 87, 'Bolivia', 'El fin de una era en el altiplano.', 'TP', 'Digital'), -- 8
('Vidas Pasadas', 2023, 105, 'EEUU', 'Reencuentro de dos almas coreanas.', 'TP', 'Digital'), -- 9
('Argentina, 1985', 2022, 140, 'Argentina', 'El juicio histórico a las Juntas.', '13+', 'Digital'), -- 10
('El Eco', 2023, 102, 'México', 'Documental rural cautivador.', 'TP', 'Digital'), -- 11
('Anatomía de una Caída', 2023, 151, 'Francia', 'Disección de un matrimonio y un juicio.', '16+', 'Digital'), -- 12
('Los de Abajo', 2022, 83, 'Bolivia', 'La lucha campesina por el agua.', '13+', 'Digital'), -- 13
('Kneecap', 2024, 105, 'Irlanda', 'El origen del hip hop en irlandés.', '18+', 'Digital'), -- 14
('Corto Experimental 1', 2024, 15, 'Bolivia', 'Ensayo visual sobre la ciudad.', 'TP', 'Digital'), -- 15
('Raíces', 2024, 20, 'Bolivia', 'Documental corto sobre música chiquitana.', 'TP', 'Digital'), -- 16
('El Visitante', 2022, 86, 'Bolivia', 'Un padre ex-convicto busca a su hija.', '13+', 'Digital'), -- 17
('Pobres Criaturas', 2023, 141, 'Reino Unido', 'El viaje surrealista de Bella Baxter.', '18+', 'Digital'), -- 18
('Perfect Days', 2023, 124, 'Japón', 'La belleza de lo cotidiano en Tokio.', 'TP', 'Digital'), -- 19
('El Abrazo de la Serpiente', 2015, 125, 'Colombia', 'Chamanes y científicos en el Amazonas.', '13+', 'Digital'), -- 20
('La Llorona', 2019, 97, 'Guatemala', 'Los fantasmas de la guerra civil guatemalteca.', '16+', 'Digital'), -- 21
('Roma', 2018, 135, 'México', 'Un año en la vida de una trabajadora doméstica.', '16+', 'Digital'), -- 22
('Amores Perros', 2000, 154, 'México', 'Tres historias conectadas por un choque.', '18+', '35mm'), -- 23
('Parasite', 2019, 132, 'Corea del Sur', 'La lucha de clases a través de dos familias.', '16+', 'Digital'), -- 24
('Monos', 2019, 102, 'Colombia', 'Jóvenes guerrilleros en las montañas.', '16+', 'Digital'), -- 25
('Viejo Calavera', 2016, 80, 'Bolivia', 'La dura vida en las minas bolivianas.', '16+', 'Digital'), -- 26
('Zona Sur', 2009, 108, 'Bolivia', 'El ocaso de una familia acomodada en La Paz.', '13+', '35mm'), -- 27
('Chaco', 2020, 77, 'Bolivia', 'La sed y la locura en la Guerra del Chaco.', '13+', 'Digital'), -- 28
('La Promesa', 2024, 25, 'Bolivia', 'Corto sobre migrantes.', '13+', 'Digital'), -- 29
('Eco Urbano', 2024, 18, 'Argentina', 'Corto documental en Buenos Aires.', 'TP', 'Digital'); -- 30
GO

-- Géneros de Películas
INSERT INTO PeliculaGenero (IdPelicula, IdGenero) VALUES 
(1,1), (1,9), (2,4), (2,10), (3,5), (4,6), (4,1), (5,1), (5,8), (6,4), (6,9),
(7,1), (7,7), (8,1), (9,8), (10,1), (11,2), (12,1), (12,10), (13,1), (13,9),
(14,3), (14,1), (15,7), (16,2), (17,1), (18,1), (18,4), (19,1), (20,1), (20,2),
(21,11), (21,1), (22,1), (23,1), (23,4), (24,4), (24,3), (25,4), (26,1), 
(27,1), (28,1), (29,1), (30,2);
GO

-- Roles en Películas
INSERT INTO RolPelicula (IdPersonal, IdPelicula, Rol, PersonajeActuado) VALUES 
(9, 1, 'Director', NULL), (11, 2, 'Director', NULL), (12, 3, 'Director', NULL),
(10, 4, 'Director', NULL), (5, 5, 'Actor', 'Tashi Duncan'), (6, 6, 'Director', NULL),
(2, 7, 'Director', NULL), (3, 9, 'Director', NULL), (7, 10, 'Actor', 'Julio Strassera'),
(13, 8, 'Director', NULL), (14, 19, 'Director', NULL), (15, 18, 'Actor', 'Bella Baxter'),
(16, 20, 'Director', NULL), (17, 21, 'Director', NULL), (18, 22, 'Actor', 'Fermín'),
(19, 23, 'Actor', 'Octavio'), (20, 24, 'Director', NULL);
GO

-- Ediciones de Películas (Asignando a 2025 y 2026)
INSERT INTO PeliculaEdicion (IdPelicula, IdEdicion, EstadoFestival) VALUES 
-- 2025 (Históricas 10 películas)
(6, 1, 'Premiada'), (8, 1, 'Premiada'), (10, 1, 'Seleccionada'), 
(20, 1, 'Seleccionada'), (22, 1, 'Seleccionada'), (23, 1, 'Premiada'), 
(24, 1, 'Seleccionada'), (26, 1, 'Seleccionada'), (27, 1, 'Premiada'), (28, 1, 'Postulada'),

-- 2026 (Cartelera Actual 20 películas)
(1, 2, 'Premiada'),      -- El Ladron de Perros (ID PE: 11)
(2, 2, 'Seleccionada'),  -- La Sustancia (ID PE: 12)
(3, 2, 'Seleccionada'),  -- Dune 2 (ID PE: 13)
(4, 2, 'Seleccionada'),  -- Robot Dreams (ID PE: 14)
(5, 2, 'Premiada'),      -- Challengers (ID PE: 15)
(7, 2, 'Seleccionada'),  -- El Gran Movimiento (ID PE: 16)
(9, 2, 'Seleccionada'),  -- Vidas Pasadas (ID PE: 17)
(11, 2, 'Premiada'),     -- El Eco (ID PE: 18)
(12, 2, 'Premiada'),     -- Anatomia de una caida (ID PE: 19)
(13, 2, 'Seleccionada'), -- Los de Abajo (ID PE: 20)
(14, 2, 'Seleccionada'), -- Kneecap (ID PE: 21)
(15, 2, 'Seleccionada'), -- Corto Exper. (ID PE: 22)
(16, 2, 'Premiada'),     -- Raices (ID PE: 23)
(17, 2, 'Seleccionada'), -- El Visitante (ID PE: 24)
(18, 2, 'Rechazada'),    -- Pobres Criaturas (ID PE: 25) - No se programa
(19, 2, 'Premiada'),     -- Perfect Days (ID PE: 26)
(21, 2, 'Seleccionada'), -- La Llorona (ID PE: 27)
(25, 2, 'Seleccionada'), -- Monos (ID PE: 28)
(29, 2, 'Postulada'),    -- La Promesa (ID PE: 29) - No se programa
(30, 2, 'Seleccionada'); -- Eco Urbano (ID PE: 30)
GO

--------------------------------------------------------------------------------
-- 3. AGENDA MASIVA DE EVENTOS Y PROYECCIONES (OCTUBRE 2026)
--------------------------------------------------------------------------------
-- Desactivar temporalmente para insertar en lote masivo sin problemas de performance
DISABLE TRIGGER TR1_ControlAgenda ON Proyeccion;
GO

INSERT INTO Proyeccion (IdPeliculaEdicion, IdSala, FechaHoraInicio, TieneQA, AforoDisponibleActual) VALUES 
-- JUEVES 08 OCT 2026 (Apertura)
(11, 1, '2026-10-08 19:00:00', 1, 250), -- Ladrón de perros (Id 1)
(13, 1, '2026-10-08 21:30:00', 0, 250), -- Dune 2 (Id 2)
(17, 3, '2026-10-08 19:30:00', 1, 150), -- Vidas Pasadas (Id 3)
(27, 4, '2026-10-08 20:00:00', 0, 120), -- La Llorona (Id 4)

-- VIERNES 09 OCT 2026
(12, 1, '2026-10-09 18:00:00', 0, 250), -- La Sustancia (Id 5)
(15, 1, '2026-10-09 21:30:00', 1, 250), -- Challengers (Id 6)
(14, 2, '2026-10-09 19:00:00', 0, 80),  -- Robot Dreams (Id 7)
(16, 5, '2026-10-09 18:30:00', 1, 120), -- El Gran Movimiento (Id 8)
(26, 6, '2026-10-09 20:00:00', 0, 60),  -- Perfect Days (Id 9)

-- SÁBADO 10 OCT 2026
(19, 1, '2026-10-10 17:00:00', 1, 250), -- Anatomia de una caida (Id 10)
(11, 1, '2026-10-10 20:30:00', 0, 250), -- Ladrón de perros (Repetición) (Id 11)
(21, 5, '2026-10-10 16:30:00', 1, 120), -- Kneecap (Id 12)
(18, 7, '2026-10-10 19:00:00', 1, 70),  -- El Eco (Id 13)
(28, 8, '2026-10-10 21:00:00', 0, 150), -- Monos al aire libre (Id 14)

-- DOMINGO 11 OCT 2026
(20, 3, '2026-10-11 17:30:00', 1, 150), -- Los de Abajo (Id 15)
(24, 4, '2026-10-11 19:00:00', 1, 120), -- El Visitante (Id 16)
(13, 1, '2026-10-11 16:00:00', 0, 250), -- Dune 2 (Repetición) (Id 17)
(12, 1, '2026-10-11 20:00:00', 0, 250), -- La Sustancia (Repetición) (Id 18)

-- LUNES 12 OCT 2026 (Noche de Cortos y Documentales)
(22, 9, '2026-10-12 18:00:00', 1, 50),  -- Corto Experimental 1 (Id 19)
(23, 9, '2026-10-12 19:00:00', 1, 50),  -- Raíces (Id 20)
(30, 9, '2026-10-12 20:00:00', 1, 50),  -- Eco Urbano (Id 21)
(18, 5, '2026-10-12 19:30:00', 0, 120), -- El Eco (Id 22)

-- MARTES 13 OCT 2026
(19, 1, '2026-10-13 18:00:00', 0, 250), -- Anatomia (Id 23)
(26, 3, '2026-10-13 20:30:00', 1, 150), -- Perfect Days (Id 24)
(16, 7, '2026-10-13 19:00:00', 0, 70),  -- El Gran Movimiento (Id 25)

-- MIERCOLES 14 OCT 2026
(15, 1, '2026-10-14 18:30:00', 0, 250), -- Challengers (Id 26)
(27, 6, '2026-10-14 20:00:00', 1, 60),  -- La Llorona (Id 27)
(14, 8, '2026-10-14 19:30:00', 0, 150), -- Robot Dreams (Id 28)

-- JUEVES 15 OCT 2026
(11, 1, '2026-10-15 19:00:00', 0, 250), -- Ladrón de perros (Id 29)
(28, 4, '2026-10-15 21:00:00', 1, 120), -- Monos (Id 30)
(20, 5, '2026-10-15 18:30:00', 0, 120), -- Los de Abajo (Id 31)

-- VIERNES 16 OCT 2026
(12, 1, '2026-10-16 18:00:00', 0, 250), -- La Sustancia (Id 32)
(13, 1, '2026-10-16 21:30:00', 0, 250), -- Dune 2 (Id 33)
(17, 3, '2026-10-16 19:00:00', 1, 150), -- Vidas Pasadas (Id 34)

-- SABADO 17 OCT 2026
(19, 1, '2026-10-17 16:00:00', 0, 250), -- Anatomia (Id 35)
(26, 1, '2026-10-17 19:30:00', 1, 250), -- Perfect Days (Id 36)
(21, 5, '2026-10-17 18:00:00', 0, 120), -- Kneecap (Id 37)
(24, 6, '2026-10-17 20:30:00', 0, 60),  -- El Visitante (Id 38)

-- DOMINGO 18 OCT 2026 (Clausura)
(11, 1, '2026-10-18 17:00:00', 1, 250), -- Ladrón de perros (Ganadora) (Id 39)
(19, 1, '2026-10-18 20:00:00', 1, 250); -- Anatomia (Ganadora) (Id 40)

ENABLE TRIGGER TR1_ControlAgenda ON Proyeccion;
GO

-- Eventos Paralelos (6 Eventos)
INSERT INTO EventoParalelo (IdEdicion, IdSala, TipoEvento, Titulo, AforoMax, AforoDisponible, CostoInscripcion, FechaHora) VALUES 
(2, 5, 'Masterclass', 'Dirección de Actores', 120, 120, 50.00, '2026-10-09 10:00:00'),
(2, 7, 'Taller', 'Edición Documental', 40, 40, 80.00, '2026-10-10 14:00:00'),
(2, NULL, 'Coctel', 'Gala de Apertura 2026', 300, 300, 150.00, '2026-10-08 22:00:00'),
(2, NULL, 'Coctel', 'Fiesta de Clausura', 400, 400, 200.00, '2026-10-18 22:00:00'),
(2, 6, 'Masterclass', 'El Cine del Futuro (IA)', 60, 60, 0.00, '2026-10-12 10:00:00'),
(2, 9, 'Taller', 'Guion Cinematográfico', 50, 50, 60.00, '2026-10-14 15:00:00');
GO

INSERT INTO ExpositorEvento (IdEvento, IdPersonal, RolExpositor) VALUES 
(1, 4, 'Ponente Magistral'), (2, 1, 'Instructor'), (5, 12, 'Conferencista Invitado'),
(6, 8, 'Tallerista');
GO

--------------------------------------------------------------------------------
-- 4. COMPETENCIA, JURADOS Y EVALUACIONES (2026)
--------------------------------------------------------------------------------
INSERT INTO JuradoCategoria (IdEdicion, IdCategoria, NombreJurado) VALUES 
(2, 1, 'Jurado Oficial Largometraje'), (2, 2, 'Jurado Oficial Documental'),
(2, 3, 'Jurado Cortometrajes'), (2, 5, 'Jurado Dirección');
GO

INSERT INTO MiembroJurado (IdJuradoCategoria, IdPersonal) VALUES 
(1, 8), (1, 4), (1, 14), -- Martel, Almodovar, Wenders para Largos
(2, 1), (2, 13),         -- Bellott, Loayza para Documentales
(3, 6),                  -- Patiño para Cortos
(4, 12);                 -- Villeneuve para Dirección
GO

-- Asignar películas a competencias en 2026
-- (Usamos IDs de PeliculaEdicion: 11 Ladrón, 12 Sustancia, 15 Challengers, 16 Gran Mov, 18 Eco, 19 Anatomia, 20 Abajo, 23 Raices, 26 Perfect, 30 Eco Urbano)
INSERT INTO PeliculaCategoria (IdPeliculaEdicion, IdCategoria) VALUES 
(11, 1), (12, 1), (15, 1), (16, 1), (19, 1), (26, 1), -- Largos
(18, 2), (20, 2),                                     -- Documentales
(22, 3), (23, 3), (30, 3),                            -- Cortos
(11, 5), (19, 5), (26, 5);                            -- Dirección
GO

-- Muchas Evaluaciones para el Dashboard
INSERT INTO Evaluacion (IdMiembro, IdPeliculaEdicion, IdCategoria, Puntuacion, Comentario) VALUES 
(1, 11, 1, 9.5, 'Excelente retrato social boliviano.'), (2, 11, 1, 9.2, 'Gran dirección.'), (3, 11, 1, 8.8, 'Muy emotiva.'),
(1, 19, 1, 9.8, 'Guion y actuaciones impecables.'), (2, 19, 1, 9.6, 'Una obra maestra.'),
(1, 12, 1, 8.0, 'Impactante visualmente, pero excesiva.'), (3, 26, 1, 9.5, 'Poesía en movimiento.'),
(4, 18, 2, 9.0, 'Fotografía sublime en el campo.'), (5, 20, 2, 8.5, 'Necesaria y dura.'),
(6, 23, 3, 9.5, 'Gran rescate musical.'), (6, 30, 3, 8.0, 'Interesante formato.'),
(7, 19, 5, 9.9, 'Dirección soberbia.');
GO

-- Premios 2026
INSERT INTO Premio (IdEdicion, IdCategoria, IdPeliculaEdicion, DescripcionPremio) VALUES 
(2, 1, 11, 'Estatuilla Mejor Largometraje (El Ladrón de Perros)'),
(2, 2, 18, 'Mejor Documental (El Eco)'),
(2, 3, 23, 'Mejor Cortometraje (Raíces)'),
(2, 5, 19, 'Galardón a la Mejor Dirección (Anatomía de una Caída)');
GO

--------------------------------------------------------------------------------
-- 5. TAQUILLA MASIVA: ASISTENTES, VENTAS Y ENTRADAS
--------------------------------------------------------------------------------
-- Asistentes (30 personas para llenar data de usuarios)
INSERT INTO Asistente (NombreCompleto, Email, Telefono, TipoAsistente) VALUES 
('Diego Salvatierra', 'diego.s@gmail.com', '71000001', 'PublicoGeneral'), ('Ana Vargas', 'ana.v@gmail.com', '71000002', 'PublicoGeneral'),
('Carlos Cortez', 'carlos.press@eldeber.com', '71000003', 'Acreditado'), ('María Justiniano', 'maria.j@hotmail.com', '71000004', 'PublicoGeneral'),
('Javier Ribera', 'javier.r@gmail.com', '71000005', 'PublicoGeneral'), ('Lucía Paz', 'lucia.paz@gmail.com', '71000006', 'PublicoGeneral'),
('Roberto Gomez', 'rgomez@yahoo.com', '71000007', 'PublicoGeneral'), ('Fernando Arce', 'farce@gmail.com', '71000008', 'PublicoGeneral'),
('Carla Roca', 'croca@hotmail.com', '71000009', 'Acreditado'), ('Daniela Velez', 'dvelez@gmail.com', '71000010', 'PublicoGeneral'),
('Mario Crapio', 'mario.c@gmail.com', '71000011', 'PublicoGeneral'), ('Luis Suarez', 'lsuarez2@gmail.com', '71000012', 'PublicoGeneral'),
('Paola Mendez', 'pmendez.tv@reduno.com', '71000013', 'Acreditado'), ('Julia Nava', 'jnava@gmail.com', '71000014', 'PublicoGeneral'),
('Oscar Daza', 'odaza@gmail.com', '71000015', 'PublicoGeneral'), ('Teresa Soto', 'tsoto@gmail.com', '71000016', 'PublicoGeneral'),
('Victor Hugo', 'vhugo@gmail.com', '71000017', 'PublicoGeneral'), ('Camila Ruiz', 'cruiz@gmail.com', '71000018', 'PublicoGeneral'),
('Andres Peña', 'apena.cine@blog.com', '71000019', 'Acreditado'), ('Sofia Loredo', 'sloredo@gmail.com', '71000020', 'PublicoGeneral'),
('Juan Perez', 'jperez@gmail.com', '71000021', 'PublicoGeneral'), ('Pedro Diaz', 'pdiaz@gmail.com', '71000022', 'PublicoGeneral'),
('Laura Franco', 'lfranco@gmail.com', '71000023', 'PublicoGeneral'), ('Carmen Rios', 'crios@gmail.com', '71000024', 'PublicoGeneral'),
('Esteban Quito', 'equito@gmail.com', '71000025', 'PublicoGeneral'), ('Rosa Melano', 'rmelano@gmail.com', '71000026', 'PublicoGeneral'),
('Armando Casas', 'acasas@gmail.com', '71000027', 'PublicoGeneral'), ('Alan Brito', 'abrito@gmail.com', '71000028', 'PublicoGeneral'),
('Elsa Pato', 'epato@gmail.com', '71000029', 'PublicoGeneral'), ('Zoila Vaca', 'zvaca@gmail.com', '71000030', 'PublicoGeneral');
GO

INSERT INTO Acreditacion (IdAsistente, IdEdicion, TipoAcred, FechaVencimiento) VALUES 
(3, 2, 'Prensa', '2026-10-19'), (9, 2, 'VIP', '2026-10-19'), 
(13, 2, 'Prensa', '2026-10-19'), (19, 2, 'Industria', '2026-10-19');
GO

-- VENTAS (15 Ventas diversas)
INSERT INTO Venta (IdAsistente, FechaVenta, TipoVenta, Total, EstadoVenta) VALUES 
(1, '2026-10-01 10:00:00', 'Entrada', 120.00, 'Completada'), -- Venta 1: 3 Grales
(2, '2026-10-02 11:30:00', 'Entrada', 50.00, 'Completada'),  -- Venta 2: 2 Estudiantes
(3, '2026-10-03 09:00:00', 'Entrada', 0.00, 'Completada'),   -- Venta 3: 1 Acred
(4, '2026-10-04 15:00:00', 'Abono', 150.00, 'Completada'),   -- Venta 4: Abono Cinefilo
(5, '2026-10-05 16:00:00', 'Evento', 150.00, 'Completada'),  -- Venta 5: Coctel
(6, '2026-10-06 10:00:00', 'Entrada', 40.00, 'Completada'),  -- Venta 6: 1 Gral
(7, '2026-10-06 12:00:00', 'Entrada', 80.00, 'Completada'),  -- Venta 7: 2 Grales
(8, '2026-10-06 14:00:00', 'Entrada', 40.00, 'Completada'),  -- Venta 8
(9, '2026-10-06 15:00:00', 'Evento', 0.00, 'Completada'),    -- Venta 9: Taller VIP
(10, '2026-10-07 09:00:00', 'Abono', 300.00, 'Completada'),  -- Venta 10: Abono Total
(11, '2026-10-07 10:00:00', 'Entrada', 80.00, 'Completada'), -- Venta 11
(12, '2026-10-07 11:00:00', 'Entrada', 40.00, 'Completada'), -- Venta 12
(14, '2026-10-07 16:00:00', 'Abono', 120.00, 'Completada'),  -- Venta 13: Abono Finde
(15, '2026-10-08 10:00:00', 'Entrada', 80.00, 'Completada'), -- Venta 14
(20, '2026-10-08 12:00:00', 'Evento', 50.00, 'Completada');  -- Venta 15: Masterclass
GO

INSERT INTO Pago (IdVenta, MetodoPago, MontoPagado, EstadoPago, FechaPago) VALUES 
(1, 'QR', 120.00, 'Aprobado', '2026-10-01 10:01:00'), (2, 'Tarjeta', 50.00, 'Aprobado', '2026-10-02 11:31:00'),
(3, 'Efectivo', 0.00, 'Aprobado', '2026-10-03 09:00:00'), (4, 'Transferencia', 150.00, 'Aprobado', '2026-10-04 15:05:00'),
(5, 'Tarjeta', 150.00, 'Aprobado', '2026-10-05 16:02:00'), (6, 'QR', 40.00, 'Aprobado', '2026-10-06 10:01:00'),
(7, 'Efectivo', 80.00, 'Aprobado', '2026-10-06 12:05:00'), (8, 'QR', 40.00, 'Aprobado', '2026-10-06 14:02:00'),
(9, 'Efectivo', 0.00, 'Aprobado', '2026-10-06 15:01:00'), (10, 'Tarjeta', 300.00, 'Aprobado', '2026-10-07 09:05:00'),
(11, 'QR', 80.00, 'Aprobado', '2026-10-07 10:02:00'), (12, 'Efectivo', 40.00, 'Aprobado', '2026-10-07 11:05:00'),
(13, 'Transferencia', 120.00, 'Aprobado', '2026-10-07 16:10:00'), (14, 'QR', 80.00, 'Aprobado', '2026-10-08 10:05:00'),
(15, 'Tarjeta', 50.00, 'Aprobado', '2026-10-08 12:02:00');
GO

INSERT INTO Factura (IdVenta, NroFactura, FechaEmision, MontoTotal) VALUES 
(1, 'FAC-000001', '2026-10-01 10:02:00', 120.00), (2, 'FAC-000002', '2026-10-02 11:32:00', 50.00),
(3, 'FAC-000003', '2026-10-03 09:01:00', 0.00), (4, 'FAC-000004', '2026-10-04 15:06:00', 150.00),
(5, 'FAC-000005', '2026-10-05 16:03:00', 150.00), (6, 'FAC-000006', '2026-10-06 10:02:00', 40.00),
(7, 'FAC-000007', '2026-10-06 12:06:00', 80.00), (8, 'FAC-000008', '2026-10-06 14:03:00', 40.00),
(9, 'FAC-000009', '2026-10-06 15:02:00', 0.00), (10, 'FAC-000010', '2026-10-07 09:06:00', 300.00),
(11, 'FAC-000011', '2026-10-07 10:03:00', 80.00), (12, 'FAC-000012', '2026-10-07 11:06:00', 40.00),
(13, 'FAC-000013', '2026-10-07 16:11:00', 120.00), (14, 'FAC-000014', '2026-10-08 10:06:00', 80.00),
(15, 'FAC-000015', '2026-10-08 12:03:00', 50.00);
GO

-- Entradas (Asientos Numéricos Válidos)
INSERT INTO Entrada (IdVenta, IdProyeccion, IdTarifa, Asiento, CodigoAcceso, Asistio) VALUES 
(1, 1, 1, '015', 'ENT-26-00001', 1), (1, 1, 1, '016', 'ENT-26-00002', 1), (1, 1, 1, '017', 'ENT-26-00003', 1), -- Venta 1 a Proy 1
(2, 2, 2, '040', 'ENT-26-00004', 1), (2, 2, 2, '041', 'ENT-26-00005', 0), -- Venta 2 a Proy 2
(3, 4, 4, '001', 'ENT-26-00006', 0), -- Venta 3 a Proy 4
(6, 10, 1, '050', 'ENT-26-00007', 0), -- Venta 6 a Proy 10
(7, 23, 1, '100', 'ENT-26-00008', 0), (7, 23, 1, '101', 'ENT-26-00009', 0), -- Venta 7 a Proy 23
(8, 35, 1, '200', 'ENT-26-00010', 0), -- Venta 8 a Proy 35
(11, 1, 1, '055', 'ENT-26-00011', 1), (11, 1, 1, '056', 'ENT-26-00012', 1), -- Venta 11 a Proy 1
(12, 5, 1, '110', 'ENT-26-00013', 0), -- Venta 12 a Proy 5
(14, 1, 1, '099', 'ENT-26-00014', 1), (14, 1, 1, '100', 'ENT-26-00015', 1); -- Venta 14 a Proy 1
GO

-- Entradas Eventos
INSERT INTO EntradaEvento (IdVenta, IdEvento, IdTarifa, CodigoAcceso, Asistio) VALUES 
(5, 3, 1, 'EVT-26-00001', 1), -- Venta 5 Coctel
(9, 2, 4, 'EVT-26-00002', 0), -- Venta 9 Taller VIP
(15, 1, 1, 'EVT-26-00003', 0); -- Venta 15 Masterclass
GO

-- Abonos y AbonoProyecciones
INSERT INTO Abono (IdVenta, IdTarifa, IdTipoAbono, MontoTotal) VALUES 
(4, 1, 1, 150.00),   -- Abono Cinefilo
(10, 1, 2, 300.00),  -- Abono Total
(13, 1, 4, 120.00);  -- Abono Finde
GO

INSERT INTO AbonoProyeccion (IdAbono, IdProyeccion, Asiento, CodigoAcceso, Asistio, FechaUso) VALUES 
(1, 1, '080', 'ABO-26-00001', 1, '2026-10-08 18:45:00'), (1, 5, '080', 'ABO-26-00002', 0, NULL), 
(1, 10, '080', 'ABO-26-00003', 0, NULL),
(2, 2, '005', 'ABO-26-00004', 1, '2026-10-08 21:15:00'), (2, 6, '005', 'ABO-26-00005', 0, NULL),
(2, 23, '005', 'ABO-26-00006', 0, NULL), (2, 35, '005', 'ABO-26-00007', 0, NULL),
(3, 5, '120', 'ABO-26-00008', 0, NULL), (3, 10, '120', 'ABO-26-00009', 0, NULL);
GO

--------------------------------------------------------------------------------
-- 6. ACTUALIZACIÓN DE AFOROS (Sincronización final)
--------------------------------------------------------------------------------
UPDATE P 
SET AforoDisponibleActual = S.CapacidadAsientos - 
    (SELECT COUNT(*) FROM Entrada E WHERE E.IdProyeccion = P.IdProyeccion) - 
    (SELECT COUNT(*) FROM AbonoProyeccion AP WHERE AP.IdProyeccion = P.IdProyeccion)
FROM Proyeccion P
INNER JOIN Sala S ON P.IdSala = S.IdSala;
GO

UPDATE EP
SET AforoDisponible = EP.AforoMax - 
    (SELECT COUNT(*) FROM EntradaEvento EE WHERE EE.IdEvento = EP.IdEvento)
FROM EventoParalelo EP;
GO

--------------------------------------------------------------------------------
-- 7. LOGÍSTICA
--------------------------------------------------------------------------------
INSERT INTO Alojamiento (IdPersonal, IdEdicion, NombreHotel, NroHabitacion, CheckIn, CheckOut) VALUES 
(4, 2, 'Hotel Los Tajibos', 'Suite 1', '2026-10-07', '2026-10-19'),
(8, 2, 'Hotel Los Tajibos', 'Suite 2', '2026-10-07', '2026-10-15'),
(12, 2, 'Marriott', '1015', '2026-10-07', '2026-10-12'),
(14, 2, 'Radisson', '502', '2026-10-08', '2026-10-18');
GO

INSERT INTO Traslado (IdPersonal, IdEdicion, TipoTraslado, Origen, Destino, FechaHora, NroVuelo) VALUES 
(4, 2, 'Vuelo', 'Madrid (MAD)', 'Viru Viru (VVI)', '2026-10-07 06:00:00', 'UX-025'),
(4, 2, 'Transfer', 'Aeropuerto Viru Viru', 'Hotel Los Tajibos', '2026-10-07 19:30:00', NULL),
(12, 2, 'Vuelo', 'Toronto (YYZ)', 'Viru Viru (VVI)', '2026-10-07 05:00:00', 'AC-980');
GO

INSERT INTO Patrocinio (IdPatrocinador, IdEdicion, TipoAportacion, MontoEconomico, DescripcionEspecie) VALUES 
(1, 2, 'Economica', 35000.00, NULL), 
(2, 2, 'Especie', NULL, 'Provisión de 2000 cervezas para cócteles y fiestas'),
(3, 2, 'Especie', NULL, '5 Pasajes aéreos internacionales para invitados VIP'),
(4, 2, 'Economica', 15000.00, NULL),
(5, 2, 'Especie', NULL, 'Alojamiento gratuito para 3 directores internacionales');
GO