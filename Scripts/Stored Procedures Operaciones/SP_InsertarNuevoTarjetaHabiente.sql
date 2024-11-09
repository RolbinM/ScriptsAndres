CREATE OR ALTER PROCEDURE dbo.SP_InsertarNuevoTarjetaHabiente(
	@inNombre VARCHAR(100),
	@inValorDocIdentidad VARCHAR(100),
	@inFechaNacimiento DATETIME,
	@inNombreUsuario VARCHAR(100),
	@inContraseña VARCHAR(100),
	@outResultCode INT OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		SET @outResultCode = 0;
		BEGIN TRANSACTION InsertarNuevoTarjetaHabiente;

			IF EXISTS (SELECT id FROM dbo.TH WHERE ValorDI = @inValorDocIdentidad)
			BEGIN
				-- El documento de identidad ya esta registrado.
				SET @outResultCode = 50009;
				EXEC SP_ConsultarError @outResultCode;
				COMMIT TRANSACTION InsertarNuevoTarjetaHabiente;
				RETURN
			END
			
			INSERT INTO dbo.TH(
				idTipoDI,
				ValorDI,
				Nombre,
				FechaNacimiento,
				Usuario,
				Contraseña
			) VALUES(
				1,
				@inValorDocIdentidad,
				@inNombre,
				@inFechaNacimiento,
				@inNombreUsuario,
				@inContraseña
			)
	

		COMMIT TRANSACTION InsertarNuevoTarjetaHabiente;

	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK TRANSACTION InsertarNuevoTarjetaHabiente;
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
