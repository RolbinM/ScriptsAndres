USE BD1_TP3;

GO
CREATE OR ALTER PROCEDURE SP_ListadoEstadosCuentaTCM
(
	@inCodigoTF VARCHAR(16)
	, @outResultCode INT OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		SET @outResultCode = 0;


		DECLARE @idTC INT = (SELECT idTC FROM TF WHERE Codigo = @inCodigoTF);
		IF @idTC IS NULL
		BEGIN
			SET @outResultCode = 50019; -- TF no existe
			EXEC SP_ConsultarError @outResultCode;
			RETURN;
		END

        DECLARE @idTCM INT = (SELECT idTCM FROM TC WHERE id = @idTC);
        IF @idTCM IS NULL
        BEGIN
            SET @outResultCode = 50014; -- TC no existe
            EXEC SP_ConsultarError @outResultCode;
            RETURN;
        END

		SELECT
			FechaCorte
			, PagoMinimoMesAnterior AS PagoMinimo
			, SaldoAlCorte AS PagoContado
			, InteresesAlCorte AS InteresesCorrientes
			, InteresesMoratoriosAlCorte AS InteresesMoratorios
			, OperacionesATM AS CantidadOperacionesATM
			, OperacionesVentanilla AS CantidadOperacionesVentanilla
		FROM EstadoCuenta
		WHERE idTCM = @idTCM;

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
		EXEC SP_ConsultarError @outResultCode;
	END CATCH
	SET NOCOUNT OFF;
END

/*
EXEC SP_ListadoEstadosCuentaTCM @outResultCode=0, @inCodigoTF='1234567890123456';
*/