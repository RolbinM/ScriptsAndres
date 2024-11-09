USE BD1_TP3;

GO
CREATE OR ALTER PROCEDURE dbo.SP_ConsultarError
(
	@inCodigoError INT
)
AS
BEGIN
	SET NOCOUNT ON;
		DECLARE @outResultCode INT = 0;
	BEGIN TRY
		
		IF NOT EXISTS (SELECT Descripcion FROM [dbo].[Error] WHERE Codigo = @inCodigoError)
		BEGIN
			SELECT 'Error desconocido en la base de datos.' AS Descripcion
			RETURN
		END
		SELECT Descripcion FROM [dbo].[Error] WHERE Codigo = @inCodigoError

	END TRY

	BEGIN CATCH
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
EXEC SP_ConsultarError @inCodigoError = 31213212;
*/