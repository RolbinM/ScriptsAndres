CREATE OR ALTER PROCEDURE dbo.SP_InsertarNuevaTarjetaCreditoAdicional(
	@inCodigoTCM VARCHAR(50),
	@inCodigoTCA VARCHAR(50),
	@inValorDocumentoTarjetaHabiente VARCHAR(100),
	@outResultCode INT OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @idTarjetaHabiente INT
		DECLARE @idTCM INT
		DECLARE @idTCA INT
			
		SET @outResultCode = 0;
		BEGIN TRANSACTION NuevaTarjetaCreditoAdicional;

			IF NOT EXISTS (SELECT id FROM dbo.TH WHERE ValorDI = @inValorDocumentoTarjetaHabiente)
			BEGIN
				-- No se ha encontrado el usuario con ese documento de identidad.
				SET @outResultCode = 50010;
				EXEC SP_ConsultarError @outResultCode;
				COMMIT TRANSACTION NuevaTarjetaCreditoAdicional
				RETURN
			END

			IF NOT EXISTS (SELECT id FROM dbo.TCM WHERE Codigo = @inCodigoTCM)
			BEGIN
				-- No existe TCM a la que asociar la TCA.
				SET @outResultCode = 50020;
				EXEC SP_ConsultarError @outResultCode;
				COMMIT TRANSACTION NuevaTarjetaCreditoAdicional
				RETURN
			END

			IF EXISTS (SELECT id FROM dbo.TCA WHERE CodigoTCA = @inCodigoTCA)
			BEGIN
				-- Ya existe TCA registrada con ese codigo.
				SET @outResultCode = 50013;
				EXEC SP_ConsultarError @outResultCode;
				COMMIT TRANSACTION NuevaTarjetaCreditoAdicional
				RETURN
			END
			
			SELECT
				@idTarjetaHabiente = id
			FROM dbo.TH  
			WHERE ValorDI = @inValorDocumentoTarjetaHabiente

			SELECT
				@idTCM = id
			FROM dbo.TCM  
			WHERE Codigo = @inCodigoTCM

			INSERT INTO dbo.TCA(
				idTH,
				idTCM,
				CodigoTCA
			) VALUES(
				@idTarjetaHabiente,
				@idTCM,
				@inCodigoTCA
			)

			SELECT
				@idTCA = id
			FROM dbo.TCA  
			WHERE CodigoTCA = @inCodigoTCA

			INSERT INTO dbo.TC(
				idTCM,
				idTCA
			) VALUES(
				NULL,
				@idTCA
			)



		COMMIT TRANSACTION NuevaTarjetaCreditoAdicional;
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK TRANSACTION NuevaTarjetaCreditoAdicional;
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