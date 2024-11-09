CREATE OR ALTER PROCEDURE dbo.SP_InsertarNuevaTarjetaCreditoMaestra(
	@inCodigo VARCHAR(50),
	@inTipoTCM VARCHAR(50),
	@inLimiteCredito MONEY,
	@inValorDocumentoTarjetaHabiente VARCHAR(100),
	@outResultCode INT OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @idTarjetaHabiente INT
		DECLARE @idTipoTCM INT
		DECLARE @idTCM INT
			
		SET @outResultCode = 0;
		BEGIN TRANSACTION NuevaTarjetaCreditoMaestra;

			IF NOT EXISTS (SELECT id FROM dbo.TH WHERE ValorDI = @inValorDocumentoTarjetaHabiente)
			BEGIN
				-- No se ha encontrado el usuario con ese documento de identidad.
				SET @outResultCode = 50010;
				EXEC SP_ConsultarError @outResultCode;
				COMMIT TRANSACTION NuevaTarjetaCreditoMaestra;
				RETURN
			END

			IF NOT EXISTS (SELECT id FROM dbo.TipoTCM WHERE Nombre = @inTipoTCM)
			BEGIN
				-- El tipo de TCM ingresado no se ha encontrado.
				SET @outResultCode = 50011;
				EXEC SP_ConsultarError @outResultCode;
				COMMIT TRANSACTION NuevaTarjetaCreditoMaestra;
				RETURN
			END

			IF EXISTS (SELECT id FROM dbo.TCM WHERE Codigo = @inCodigo)
			BEGIN
				-- Ya existe una TCM registrada con ese codigo.
				SET @outResultCode = 50012;
				EXEC SP_ConsultarError @outResultCode;
				COMMIT TRANSACTION NuevaTarjetaCreditoMaestra;
				RETURN
			END
			
			SELECT
				@idTarjetaHabiente = id
			FROM dbo.TH  
			WHERE ValorDI = @inValorDocumentoTarjetaHabiente

			SELECT
				@idTipoTCM = id
			FROM dbo.TipoTCM  
			WHERE Nombre = @inTipoTCM

			INSERT INTO dbo.TCM(
				Codigo,
				LimiteCredito,
				idTipoTCM,
				idTH
			) VALUES(
				@inCodigo,
				@inLimiteCredito,
				@idTipoTCM,
				@idTarjetaHabiente
			)

			SELECT
				@idTCM = id
			FROM dbo.TCM  
			WHERE Codigo = @inCodigo

			INSERT INTO dbo.TC(
				idTCM,
				idTCA
			) VALUES(
				@idTCM,
				NULL
			)

		COMMIT TRANSACTION NuevaTarjetaCreditoMaestra;
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK TRANSACTION NuevaTarjetaCreditoMaestra;
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