USE BD1_TP3;

GO
CREATE OR ALTER PROCEDURE dbo.SP_InsertarNuevaTarjetaFisica(
	@inCodigo VARCHAR(150),
	@inCodigoTCAsociada VARCHAR(100),
	@inFechaVencimiento VARCHAR(25),
	@inCCV VARCHAR(25),
	@inFechaOperacion DATETIME,
	@outResultCode INT OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @idTCAsociada INT
			
		SET @outResultCode = 0;
		BEGIN TRANSACTION NuevaTarjetaFisica;
			
			SELECT
				@idTCAsociada = tc.id
			FROM dbo.TC tc
			INNER JOIN dbo.TCM tcm
			ON tcm.id = tc.idTCM
			WHERE tcm.Codigo = @inCodigoTCAsociada

			IF @idTCAsociada IS NULL
			BEGIN
				SELECT
					@idTCAsociada = tc.id
				FROM dbo.TC tc
				INNER JOIN dbo.TCA tca
				ON tca.id = tc.idTCA
				WHERE tca.CodigoTCA = @inCodigoTCAsociada
			END

			IF @idTCAsociada IS NULL
			BEGIN
				-- No se encontro TC asociada.
				SET @outResultCode = 50014;
				EXEC SP_ConsultarError @outResultCode;
				COMMIT TRANSACTION NuevaTarjetaFisica;
				RETURN
			END
			
			IF EXISTS (SELECT id FROM dbo.TF WHERE Codigo = @inCodigo)
			BEGIN
				-- No se ingreso TF, ya existe ese codigo.
				SET @outResultCode = 50015;
				EXEC SP_ConsultarError @outResultCode;
				COMMIT TRANSACTION NuevaTarjetaFisica;
				RETURN
			END

			INSERT INTO dbo.TF(
				idTC,
				Codigo,
				CCV,
				FechaCreacion,
				FechaVencimiento,
				Activa
			) VALUES(
				@idTCAsociada,
				@inCodigo,
				@inCCV,
				@inFechaOperacion,
				@inFechaVencimiento,
				'SI'
			)


		COMMIT TRANSACTION NuevaTarjetaFisica;
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK TRANSACTION NuevaTarjetaFisica;
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