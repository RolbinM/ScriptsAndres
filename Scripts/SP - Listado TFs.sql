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
		BEGIN TRANSACTION ListadoTF;

		DECLARE @gridTF TABLE (
			CodigoTF VARCHAR(150)
			, Activa VARCHAR(3)
			, TipoCuenta VARCHAR(10)
			, FechaVencimiento DATETIME
		);

		INSERT INTO @gridTF
			SELECT 
   				TF.Codigo AS CodigoTF
   				, TF.Activa
   				, CASE
				    WHEN TC.idTCA IS NOT NULL THEN 'TCA'
        			ELSE 'TCM'
    				END AS TipoCuenta
    			, TF.FechaVencimiento
			FROM TF
			JOIN TC ON TF.idTC = TC.id
			LEFT JOIN TCA ON TC.idTCA = TCA.id
			LEFT JOIN TCM ON TC.idTCM = TCM.id;

		-- Select para verificar los resultados
		SELECT * FROM @gridTF;

		COMMIT TRANSACTION ListadoTF;
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
EXEC SP_ListadoTFs @outResultCode=0, @inUsuario='cmendoza';
*/