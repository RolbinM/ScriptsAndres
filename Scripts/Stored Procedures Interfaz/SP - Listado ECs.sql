USE BD1_TP3;

GO
CREATE OR ALTER PROCEDURE SP_ListadoEstadosCuenta
(
	@inCodigoTF VARCHAR(16)
	, @outResultCode INT OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		SET @outResultCode = 0;

		DECLARE @gridEC TABLE (
			
		);

		DECLARE idTF INT = (SELECT id FROM TF WHERE codigo = @inCodigoTF);
		IF idTF IS NULL
		BEGIN
			SET @outResultCode = 50019; -- TF no existe
			EXEC SP_ConsultarError @outResultCode;
			RETURN;
		END

		IF EXISTS (SELECT TC.idTCM FROM TF INNER JOIN TC ON )



		SELECT * FROM @gridEC;

	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK TRANSACTION ListadoTF;
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
		SELECT @outResultCode AS outResultCode;
	END CATCH
	SET NOCOUNT OFF;
END

/*
EXEC SP_ListadoTFs @outResultCode=0, @inUsuario='jperez';
*/