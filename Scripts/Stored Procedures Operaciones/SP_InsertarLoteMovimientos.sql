--DROP PROCEDURE dbo.SP_InsertarLoteMovimientos

CREATE OR ALTER PROCEDURE dbo.SP_InsertarLoteMovimientos
(
	@Movimientos dbo.MovimientoVariable READONLY, 
	@outResultCode INT OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION InsertarNuevoMovimientoLote;
	SET @outResultCode = 0;
	DECLARE @FilaActual INT = 1;
	DECLARE @TotalFilas INT;

	-- Contar el número total de filas directamente en @Movimientos
	SET @TotalFilas = (SELECT COUNT(*) FROM @Movimientos);

	WHILE @FilaActual <= @TotalFilas
	BEGIN
		DECLARE @FechaOperacion DATETIME,
		@Nombre VARCHAR(100),
		@TF VARCHAR(100),
		@FechaMovimiento DATETIME,
		@Monto DECIMAL(28,8),
		@Descripcion VARCHAR(200),
		@Referencia VARCHAR(100),
		@Procesado BIT,
		@NuevoSaldo MONEY,
		@TFActiva VARCHAR(3)

		-- Obtener los datos de la fila actual usando ROW_NUMBER
		;WITH FilasNumeradas AS (
		SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowID,
		   FechaOperacion, Nombre, TF, FechaMovimiento, Monto, Descripcion, Referencia, Procesado, NuevoSaldo
		FROM @Movimientos
		)
		SELECT @FechaOperacion = FechaOperacion,
		   @Nombre = Nombre,
		   @TF = TF,
		   @FechaMovimiento = FechaMovimiento,
		   @Monto = Monto,
		   @Descripcion = Descripcion,
		   @Referencia = Referencia,
		   @Procesado = Procesado,
		   @NuevoSaldo = NuevoSaldo
		FROM FilasNumeradas
		WHERE RowID = @FilaActual;

		-- Logica para ver como insertar el movimiento
		DECLARE @MovimientoTemporal dbo.MovimientoTemporal;
		DECLARE @MovimientoTemporalSospechoso dbo.MovimientoTemporal;
		DECLARE @MovimientoTemporalParaEC dbo.MovimientoTemporal;

		SELECT @FechaCreacionTF = tf.FechaCreacion,
			   @FechaVencimientoTF = dbo.ParseFecha(tf.FechaVencimiento),
			   @idTarjetaFisica = tf.id
			   @TFActiva = tf.Activa
				FROM [dbo].TF AS tf 
				WHERE tf.Codigo = @inTarjetaFisica;

		IF @idTipoMovimiento IS NULL
				BEGIN
					SET @outResultCode = 50011;
					EXEC SP_ConsultarError @outResultCode;
					COMMIT TRANSACTION InsertarNuevoMovimiento;
					RETURN
				END
		
		IF @fechaCreacionTF IS NULL
			BEGIN
				SET @outResultCode = 50017;
				EXEC SP_ConsultarError @outResultCode;
				COMMIT TRANSACTION InsertarNuevoMovimiento;
				RETURN
			END

		IF @fechaVencimientoTFParsed IS NULL
			BEGIN
				SET @outResultCode = 50018
				SELECT @outResultCode
				COMMIT TRANSACTION InsertarNuevoMovimiento;
				RETURN
			END 

		IF @idTarjetaFisica IS NULL
			BEGIN
				SET @outResultCode = 50019;
				EXEC SP_ConsultarError @outResultCode;
				COMMIT TRANSACTION InsertarNuevoMovimiento;
				RETURN
			END 

		IF (@fechaCreacionTF > @inFechaMovimiento  AND @fechaVencimientoTFParsed < @inFechaMovimiento) OR @TFActiva = 'NO'
		BEGIN
			INSERT INTO @MovimientoTemporalSospechoso (idTF, idTipoMovimiento, Monto, Descripcion, Fecha, Referencia, Procesado, NuevoSaldo)
						VALUES (@idTarjetaFisica, @idTipoMovimiento, @Monto, @Descripcion, @fechaVencimientoTF, @Referencia, 0, 0);
		END
		ELSE
		BEGIN
			IF @Nombre IN ('Recuperacion por Perdida', 'Recuperacion por Robo')
			BEGIN
				INSERT INTO @MovimientoTemporal (idTF, idTipoMovimiento, Monto, Descripcion, Fecha, Referencia, Procesado, NuevoSaldo)
					VALUES (@idTarjetaFisica, @idTipoMovimiento, @Monto, @Descripcion, @fechaVencimientoTF, @Referencia, 1, 0);
			END
			ELSE IF @Nombre IN ('Renovacion de TF')
			BEGIN
				INSERT INTO @MovimientoTemporal (idTF, idTipoMovimiento, Monto, Descripcion, Fecha, Referencia, Procesado, NuevoSaldo)
					VALUES (@idTarjetaFisica, @idTipoMovimiento, @Monto, @Descripcion, @fechaVencimientoTF, @Referencia, 1, 0);
			END
			ELSE IF @Nombre IN ('Compra', 'Retiro en ATM', 'Pago en ATM', 'Retiro en Ventana', 'Pago en Ventana', 'Pago en Linea')
			BEGIN
				INSERT INTO @MovimientoTemporal (idTF, idTipoMovimiento, Monto, Descripcion, Fecha, Referencia, Procesado, NuevoSaldo)
					VALUES (@idTarjetaFisica, @idTipoMovimiento, @Monto, @Descripcion, @fechaVencimientoTF, @Referencia, 1, 0);
			END
			ELSE
			BEGIN
				INSERT INTO @MovimientoTemporalParaEC (idTF, idTipoMovimiento, Monto, Descripcion, Fecha, Referencia, Procesado, NuevoSaldo)
					VALUES (@idTarjetaFisica, @idTipoMovimiento, @Monto, @Descripcion, @fechaVencimientoTF, @Referencia, 0, 0);
			END
		END
		-- Incrementar el índice para la siguiente iteración
		SET @FilaActual = @FilaActual + 1;
	END;
	END TRY
	BEGIN CATCH
	IF @@TRANCOUNT > 0
	BEGIN
	ROLLBACK TRANSACTION InsertarNuevoMovimientoLote;
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
END;
GO