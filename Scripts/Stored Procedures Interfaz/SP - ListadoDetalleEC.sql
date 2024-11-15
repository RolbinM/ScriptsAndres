USE BD1_TP3;

GO
CREATE OR ALTER PROCEDURE SP_ListadoDetalleEC
(
    @inIdEstadoCuenta INT = NULL
    , @inIdSubEstadoCuenta INT = NULL
    , @inCodigoTF VARCHAR(16)
    , @outResultCode INT OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		SET @outResultCode = 0;

		-- Para determinar el estado de cuenta a listar entonces hay que obtener los movimientos realizados en un cierto rango de fechas
		-- Por lo que hay que agregar el campo "FechaCreacion" a la tabla EstadoCuenta

		-- Lo mismo para la tabla SubEstadoCuenta

		DECLARE @idTF INT = (SELECT id FROM TF WHERE Codigo = @inCodigoTF);
		
		SELECT 
			Fecha
			, TM.Nombre AS TipoMovimiento
			, Descripcion
			, Referencia
			, Monto
			, NuevoSaldo
		FROM Movimientos M
		INNER JOIN TipoMovimiento TM ON TM.id = M.idTipoMovimiento
		WHERE
			idTF = @idTF
		AND
			(
				(Fecha BETWEEN (SELECT FechaCreacion FROM EstadoCuenta WHERE id = @inIdEstadoCuenta)
				AND (SELECT FechaCorte FROM EstadoCuenta WHERE id = @inIdEstadoCuenta))
				OR
				(Fecha BETWEEN (SELECT FechaCreacion FROM SubEstadoCuenta WHERE id = @inIdSubEstadoCuenta)
				AND (SELECT FechaCorte FROM SubEstadoCuenta WHERE id = @inIdSubEstadoCuenta))
			)
		ORDER BY Fecha ASC;
		

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
EXEC SP_ListadoDetalleEC @outResultCode=0, @inCodigoTF='5555666677778888';
*/