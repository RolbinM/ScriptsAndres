USE BD1_TP3;

GO
CREATE OR ALTER PROCEDURE SP_ListadoTFs
(
	@inUsuario NVARCHAR(100)
	, @outResultCode INT OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		SET @outResultCode = 0;

		DECLARE @gridTF TABLE (
			CodigoTF VARCHAR(150)
			, Activa VARCHAR(3)
			, TipoCuenta VARCHAR(10)
			, FechaCreacion DATETIME
			, FechaVencimiento VARCHAR(7)
		);

		INSERT INTO @gridTF
			SELECT 
   				TF.Codigo AS CodigoTF
   				, TF.Activa
   				, CASE
				    WHEN TC.idTCA IS NOT NULL THEN 'TCA'
        			ELSE 'TCM'
    				END AS TipoCuenta
				, TF.FechaCreacion
    			, TF.FechaVencimiento
			FROM TF
			INNER JOIN TC ON TC.id = TF.idTC;


		SELECT * FROM @gridTF;

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
		EXEC SP_ConsultarError @outResultCode;
	END CATCH
	SET NOCOUNT OFF;
END

/*
EXEC SP_ListadoTFs @outResultCode=0, @inUsuario='jperez';
*/