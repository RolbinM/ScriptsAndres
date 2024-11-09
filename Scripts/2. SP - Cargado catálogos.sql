USE BD1_TP3;

GO
CREATE OR ALTER PROCEDURE CargarCatalogosXML
(
	@outResultCode INT OUTPUT
	, @inRutaXML NVARCHAR(500)
)
AS
BEGIN

	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRANSACTION Cargado;
			
			DECLARE @Datos xml

			-- Variables para la carga del XML
			DECLARE @Comando NVARCHAR(500)= 'SELECT @root = D FROM OPENROWSET (BULK '  + CHAR(39) + @inRutaXML + CHAR(39) + ', SINGLE_BLOB) AS root(D)';
			DECLARE @Parametros NVARCHAR(500);
			DECLARE @hdoc INT;

			SET @Parametros = N'@root xml OUTPUT';

			EXEC sp_executesql @Comando, @Parametros, @Datos OUTPUT;
    		EXEC sp_xml_preparedocument @hdoc OUTPUT, @Datos;

			-- Extracción TCCM 
			DELETE FROM dbo.TipoTCM

			INSERT INTO dbo.TipoTCM(Nombre)
			SELECT *
				FROM OPENXML (@hdoc, '/root/TTCM/TTCM', 1)
				WITH(
					Nombre VARCHAR(100)
				);


			-- Extracción TRN 
			DELETE FROM dbo.TipoRN

			INSERT INTO dbo.TipoRN(Nombre, TipoDato)
			SELECT *
				FROM OPENXML (@hdoc, '/root/TRN/TRN', 1)
				WITH(
					Nombre VARCHAR(100),
					tipo VARCHAR(100)
				);

			-- Extracción RN 
			DELETE FROM dbo.RN

			INSERT INTO dbo.RN (Nombre, idTipoTCM, idTipoRN, Valor)
			SELECT 
				Nombre,
				(SELECT id FROM dbo.TipoTCM WHERE Nombre = TTCM) AS idTipoTCM,
				(SELECT id FROM dbo.TipoRN WHERE Nombre = TipoRN) AS idTipoRN,
				Valor
			FROM OPENXML (@hdoc, '/root/RN/RN', 1)
			WITH (
				Nombre VARCHAR(100),
				TTCM VARCHAR(100),
				TipoRN VARCHAR(100),
				Valor VARCHAR(100)
			);

			-- Extracción MIT 
			DELETE FROM dbo.MIT

			INSERT INTO dbo.MIT(Nombre)
			SELECT *
				FROM OPENXML (@hdoc, '/root/MIT/MIT', 1)
				WITH(
					Nombre VARCHAR(100)
				);

			-- Extracción TM 
			DELETE FROM dbo.TipoMovimiento

			INSERT INTO dbo.TipoMovimiento(Nombre, Accion, OperacionATM, OperacionVentanilla)
			SELECT *
				FROM OPENXML (@hdoc, '/root/TM/TM', 1)
				WITH(
					Nombre VARCHAR(100),
					Accion VARCHAR(100),
					Acumula_Operacion_ATM VARCHAR(3),
					Acumula_Operacion_Ventana VARCHAR(3)
				);


			-- Extracción Usuarios 
			DELETE FROM dbo.Administrador

			INSERT INTO dbo.Administrador(Usuario, Contraseña)
			SELECT *
				FROM OPENXML (@hdoc, '/root/UA/Usuario', 1)
				WITH(
					Nombre VARCHAR(100),
					Password VARCHAR(100)
				);


			-- Extracción TMIC 
			DELETE FROM dbo.TipoMI

			INSERT INTO dbo.TipoMI(Nombre)
			SELECT *
				FROM OPENXML (@hdoc, '/root/TMIC/TMIC', 1)
				WITH(
					nombre VARCHAR(100)
				);


			-- Extracción TMIM 
			DELETE FROM dbo.TipoMIM

			INSERT INTO dbo.TipoMIM(Nombre)
			SELECT *
				FROM OPENXML (@hdoc, '/root/TMIM/TMIM', 1)
				WITH(
					nombre VARCHAR(100)
				);

			EXEC sp_xml_removedocument @hdoc

		COMMIT TRANSACTION Cargado;
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK TRANSACTION Cargado;
		END
		SET @outResultCode = 50008; -- Error en base de datos
		INSERT INTO [dbo].[DBError] VALUES (
			SUSER_NAME()
			, ERROR_NUMBER()
			, ERROR_STATE()
			, ERROR_SEVERITY()
			, ERROR_LINE()
			, ERROR_PROCEDURE()
			, ERROR_MESSAGE()
			, GETDATE()
			);
		EXEC SP_ConsultarError @outResultCode;
	END CATCH
	SET NOCOUNT OFF;
	

END


/*
ANDRES
EXEC CargarCatalogosXML @outResultCode=50008, @inRutaXML='C:\Users\AndresMFIT\OneDrive\Principal\Universidad\Semestre II 2024\BD1\Tarea 3\BDI-T3\Resources\CatalogosFinal.xml';

FOFO
EXEC CargarCatalogosXML @outResultCode=50008, @inRutaXML='E:\Downloads\CatalogosFinal.xml';

ROLBIN
EXEC CargarCatalogosXML @outResultCode=50008, @inRutaXML='C:\CatalogosFinal.xml';
*/