USE BD1_TP3;

GO
CREATE OR ALTER PROCEDURE SP_ListadoEstadosCuentaTCA
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

        DECLARE @idTCA INT = (SELECT idTCA FROM TC WHERE id = @idTC);
        IF @idTCA IS NULL
        BEGIN
            SET @outResultCode = 50014; -- TC no existe
            EXEC SP_ConsultarError @outResultCode;
            RETURN;
        END

		DECLARE @gridEC TABLE (
			FechaCorte DATE
            , PagoMinimo MONEY
            , PagoContado MONEY
            , InteresesCorrientes MONEY
            , InteresesMoratorios MONEY
            , CantidadOperacionesATM INT
            , CantidadOperacionesVentanilla INT
		);

        INSERT INTO @gridEC
            SELECT
                FechaCorte
                , OperacionesATM AS CantidadOperacionesATM
                , OperacionesVentanilla AS CantidadOperacionesVentanilla
                , CantidadCompras
                , SumaCompras
                , CantidadRetiros
                , SumaRetiros
            FROM SubEstadoCuenta
            WHERE idTCA = @idTCA;


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
EXEC SP_ListadoEstadosCuentaTCA @outResultCode=0, @inCodigoTF='5555666677778888';
*/