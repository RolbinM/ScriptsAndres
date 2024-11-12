USE BD1_TP3;

GO
CREATE OR ALTER PROCEDURE dbo.SP_InsertarMovimiento(
	@tablaMovimientos dbo.MovimientoTemporal READONLY,
	@outResultCode INT OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		
		BEGIN TRANSACTION InsertarMovimientos;
		
		INSERT INTO Movimientos (idTF, idTipoMovimiento, Monto, Descripcion, Fecha, Referencia, Procesado, NuevoSaldo)
		SELECT idTF, idTipoMovimiento, Monto, Descripcion, Fecha, Referencia, Procesado, NuevoSaldo FROM @tablaMovimientos

		COMMIT TRANSACTION InsertarMovimientos;
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK TRANSACTION InsertarMovimientos;
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