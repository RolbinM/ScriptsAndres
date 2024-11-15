USE BD1_TP3;

GO
CREATE OR ALTER PROCEDURE dbo.SP_InsertarLoteMovimientos
(
    @Movimientos dbo.MovimientoVariable READONLY, -- Se usa READONLY para que nos permita mandarla por parámetro
    @outResultCode INT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION InsertarNuevoMovimientoLote;
        SET @outResultCode = 0;
		DECLARE @MovimientoTemporal dbo.MovimientoTemporal,
		 @MovimientoTemporalSospechoso dbo.MovimientoTemporal,
		 @MovimientoTemporalParaEC dbo.MovimientoTemporal,
		 @MovimientoTemporalPerdidaRobo dbo.MovimientoTemporal,
		 @MovimientoTemporalRenovacion dbo.MovimientoTemporal,
		 @tempNuevoSaldo MONEY;

        -- Crear una tabla temporal para almacenar la CTE MovimientosConInfo
        DECLARE @MovimientosConInfo TABLE (
            FechaOperacion DATETIME,
            Nombre VARCHAR(100),
            TF VARCHAR(100),
            FechaMovimiento DATETIME,
            Monto DECIMAL(28,8),
            Descripcion VARCHAR(200),
            Referencia VARCHAR(100),
            Procesado BIT,
            NuevoSaldo MONEY,
            idTipoMovimiento INT,
            fechaCreacionTF DATETIME,
            fechaVencimientoTF DATETIME,
            idTarjetaFisica INT,
            TFActiva VARCHAR(3)
        );

        -- Insertar en la tabla temporal los resultados de la CTE MovimientosConInfo
        INSERT INTO @MovimientosConInfo
        SELECT 
            M.FechaOperacion,
            M.Nombre,
            M.TF,
            M.FechaMovimiento,
            M.Monto,
            M.Descripcion,
            M.Referencia,
            M.Procesado,
            M.NuevoSaldo,
            TM.id AS idTipoMovimiento,
            TF.FechaCreacion AS fechaCreacionTF,
            dbo.ParseFecha(TF.FechaVencimiento) AS fechaVencimientoTF,
            TF.id AS idTarjetaFisica,
            TF.Activa AS TFActiva
        FROM 
            @Movimientos AS M
            LEFT JOIN [dbo].TipoMovimiento AS TM ON M.Nombre = TM.Nombre
            LEFT JOIN [dbo].TF AS TF ON M.TF = TF.Codigo;

        -- Realizar las inserciones en las tablas temporales
        INSERT INTO @MovimientoTemporal (idTF, idTipoMovimiento, Monto, Descripcion, Fecha, Referencia, Procesado, NuevoSaldo)
        SELECT 
            idTarjetaFisica,
            idTipoMovimiento,
            Monto,
            Descripcion,
            FechaMovimiento,
            Referencia,
            0,
            0
        FROM 
            @MovimientosConInfo
        WHERE 
            Nombre IN ('Compra', 'Retiro en ATM', 'Pago en ATM', 'Retiro en Ventana', 'Pago en Ventana', 'Pago en Linea') 
			AND fechaCreacionTF <= FechaMovimiento 
            AND fechaVencimientoTF >= FechaMovimiento 
            AND TFActiva = 'SI';

        INSERT INTO @MovimientoTemporalParaEC (idTF, idTipoMovimiento, Monto, Descripcion, Fecha, Referencia, Procesado, NuevoSaldo)
        SELECT 
            idTarjetaFisica,
            idTipoMovimiento,
            Monto,
            Descripcion,
            FechaMovimiento,
            Referencia,
            0,
            0
        FROM 
            @MovimientosConInfo
        WHERE 
            Nombre IN ('Cargos por Servicio', 'Cargos por Multa Exceso Uso ATM', 'Cargos por Multa Exceso Uso Ventana');

        INSERT INTO @MovimientoTemporalSospechoso (idTF, idTipoMovimiento, Monto, Descripcion, Fecha, Referencia, Procesado, NuevoSaldo)
        SELECT 
            idTarjetaFisica,
            idTipoMovimiento,
            Monto,
            Descripcion,
            FechaMovimiento,
            Referencia,
            0,
            0
        FROM 
            @MovimientosConInfo
        WHERE 
            fechaCreacionTF IS NULL
            OR fechaVencimientoTF IS NULL
            OR idTipoMovimiento IS NULL
            OR fechaCreacionTF > FechaMovimiento 
            OR fechaVencimientoTF < FechaMovimiento 
            OR TFActiva = 'NO';

		--Inicia el proceso de actualizacion de saldo

		DECLARE @TablaIncrementos TABLE (
				RowNum INT PRIMARY KEY IDENTITY(1,1),
				Fecha DATETIME,
				Referencia NVARCHAR(300),
				Monto Money,
				NuevoMonto Money,
				idTCM INT,
				idTF INT
			);
		DECLARE @TablaDecrementos TABLE (
				RowNum INT PRIMARY KEY IDENTITY(1,1),
				Fecha DATETIME,
				Referencia NVARCHAR(300),
				Monto Money,
				NuevoMonto Money,
				idTCM INT,
				idTF INT
			);

		DECLARE @MixMovimientos dbo.MovimientoTemporal;  

		INSERT INTO @MixMovimientos (idTF, idTipoMovimiento, Monto, Descripcion, Fecha, Referencia, Procesado, NuevoSaldo)
		SELECT idTF, idTipoMovimiento, Monto, Descripcion, Fecha, Referencia, Procesado, NuevoSaldo 
		FROM @MovimientoTemporal
		UNION ALL
		SELECT idTF, idTipoMovimiento, Monto, Descripcion, Fecha, Referencia, Procesado, NuevoSaldo 
		FROM @MovimientoTemporalSospechoso;

		--Inserciones en tabla incrementos de Movimientos Diarios y Movimientos sospechosos

		INSERT INTO @TablaIncrementos(Fecha, Referencia, Monto, idTF, idTCM)
		SELECT mt.Fecha, mt.Referencia, mt.Monto, tf.id, CASE 
					WHEN tcm.id IS NOT NULL THEN tcm.id
					WHEN tca.id IS NOT NULL THEN tcmAux.id
					ELSE ''
				END
		FROM 
			TipoMovimiento as TM
			INNER JOIN 
			@MixMovimientos as mt
			ON TM.id = mt.idTipoMovimiento

			INNER JOIN 
			dbo.TF as tf
			ON mt.idTF = tf.id
			
			INNER JOIN dbo.TC tc
			ON tc.id = tf.idTC

			LEFT JOIN dbo.TCM tcm
			ON tcm.id = tc.idTCM

			LEFT JOIN dbo.TCA tca
			ON tca.id = tc.idTCA
			LEFT JOIN dbo.TCM tcmAux
			ON tcmAux.id = tca.idTCM
		WHERE TM.Accion = 'Credito'; 

		--Inserciones en tabla decrementos de Movimientos Diarios y Movimientos sospechosos

		INSERT INTO @TablaDecrementos(Fecha, Referencia, Monto, idTF, idTCM)
		SELECT mt.Fecha, mt.Referencia, mt.Monto, tf.id, CASE 
					WHEN tcm.id IS NOT NULL THEN tcm.id
					WHEN tca.id IS NOT NULL THEN tcmAux.id
					ELSE ''
				END
		FROM 
			TipoMovimiento as TM
			INNER JOIN 
			@MixMovimientos as mt
			ON TM.id = mt.idTipoMovimiento

			INNER JOIN 
			dbo.TF as tf
			ON mt.idTF = tf.id
			
			INNER JOIN dbo.TC tc
			ON tc.id = tf.idTC

			LEFT JOIN dbo.TCM tcm
			ON tcm.id = tc.idTCM

			LEFT JOIN dbo.TCA tca
			ON tca.id = tc.idTCA
			LEFT JOIN dbo.TCM tcmAux
			ON tcmAux.id = tca.idTCM
		WHERE TM.Accion = 'Debito'; 

		--Ciclo para actualizar incrementos

		DECLARE @CurrentRow INT = 1;
		DECLARE @MaxRow INT;

		SELECT @MaxRow = COUNT(*) FROM @TablaIncrementos;

		WHILE @CurrentRow <= @MaxRow
		BEGIN
			DECLARE @Fecha DATE;
			DECLARE @Referencia VARCHAR(50);
			DECLARE @Monto DECIMAL(18, 2);
			DECLARE @idTCM INT;
			DECLARE @idTF INT;

			SELECT 
				@Fecha = Fecha,
				@Referencia = Referencia,
				@Monto = Monto,
				@idTCM = idTCM,
				@idTF = idTF
			FROM 
				@TablaIncrementos
			WHERE 
				RowNum = @CurrentRow;

			-----Actualizacion saldo credito----------------------------------------------------------------------------------
			SET @tempNuevoSaldo = (SELECT tcm.SaldoActual + @Monto
									FROM TCM as tcm 
									WHERE tcm.id = @idTCM);

			UPDATE TCM
			SET SaldoActual = @tempNuevoSaldo
			FROM TCM as tcm 
			WHERE tcm.id = @idTCM

			UPDATE @MovimientoTemporal
			SET NuevoSaldo = @tempNuevoSaldo
			FROM @MovimientoTemporal as mt 
			WHERE  mt.Fecha = @Fecha AND mt.Referencia = @Referencia AND mt.Monto = @Monto

			-- Se usa @@ROWCOUNT porque se está haciendo carga masiva y nos sirve para ver las líneas
			-- que se han insertado hasta este punto.
			IF @@ROWCOUNT = 0
			BEGIN
				-- Si ninguna fila de movimiento temporal se actualiza entonces el registro debe estar en movimientos sospechosos
				UPDATE @MovimientoTemporalSospechoso
				SET NuevoSaldo = @tempNuevoSaldo
				FROM @MovimientoTemporalSospechoso as mt 
				WHERE  mt.Fecha = @Fecha AND mt.Referencia = @Referencia AND mt.Monto = @Monto
			END

			SET @CurrentRow = @CurrentRow + 1;
		END

		SET @CurrentRow = 1
		-- Acá usamos COUNT(*) a pesar de tener un peso en la eficiencia porque así evitamos usar cursores.
		SELECT @MaxRow = COUNT(*) FROM @TablaDecrementos;
		--Ciclo par actualizar decrementos
		WHILE @CurrentRow <= @MaxRow
		BEGIN

			SELECT 
				@Fecha = Fecha,
				@Referencia = Referencia,
				@Monto = Monto,
				@idTCM = idTCM,
				@idTF = idTF
			FROM 
				@TablaDecrementos
			WHERE 
				RowNum = @CurrentRow;

			--Obtener nuevo saldo
			SET @tempNuevoSaldo = (SELECT tcm.SaldoActual - @Monto
									FROM TCM as tcm 
									WHERE tcm.id = @idTCM);

			---Actualizacion saldo debito-------------------------------------------------------------------------
			UPDATE TCM
			SET SaldoActual = @tempNuevoSaldo
			FROM TCM as tcm 
			WHERE tcm.id = @idTCM

			UPDATE @MovimientoTemporal
			SET NuevoSaldo = @tempNuevoSaldo
			FROM @MovimientoTemporal as mt 
			WHERE  mt.Fecha = @Fecha AND mt.Referencia = @Referencia AND mt.Monto = @Monto

			IF @@ROWCOUNT = 0
			BEGIN
				-- Si ninguna fila de movimiento temporal se actualiza entonces el registro debe estar en movimientos sospechosos
				UPDATE @MovimientoTemporalSospechoso
				SET NuevoSaldo = @tempNuevoSaldo
				FROM @MovimientoTemporalSospechoso as mt 
				WHERE  mt.Fecha = @Fecha AND mt.Referencia = @Referencia AND mt.Monto = @Monto
			END

			SET @CurrentRow = @CurrentRow + 1;
		END


		--Insercion de Movimientos a la tabla real----------------------------------------------------------------

		DECLARE @tablaMovimientosAjustados dbo.MovimientoTemporal;

		-- Insertamos los datos en la tabla de tipo definido por el usuario
		INSERT INTO @tablaMovimientosAjustados (idTF, idTipoMovimiento, Monto, Descripcion, Fecha, Referencia, Procesado, NuevoSaldo)
		SELECT idTF, idTipoMovimiento, Monto, Descripcion, Fecha, Referencia, Procesado, NuevoSaldo FROM @MovimientoTemporal
		UNION ALL -- Se usa UNION ALL porque es más eficiente el que es solo UNION
		SELECT idTF, idTipoMovimiento, Monto, Descripcion, Fecha, Referencia, Procesado, NuevoSaldo FROM @MovimientoTemporalParaEC;


		EXEC dbo.SP_InsertarMovimiento
			@tablaMovimientos = @tablaMovimientosAjustados,
			@outResultCode = @outResultCode OUTPUT;
		
		EXEC dbo.SP_InsertarMovimientoSospechoso
			@tablaMovimientos = @MovimientoTemporalSospechoso,
			@outResultCode = @outResultCode OUTPUT;

		-- Commit la transacción si todo está correcto
        COMMIT TRANSACTION InsertarNuevoMovimientoLote;

        -- Selecciona los resultados
        --SELECT * FROM @MovimientoTemporal;
        --SELECT * FROM @MovimientoTemporalSospechoso;
        --SELECT * FROM @MovimientoTemporalParaEC;
        --SELECT * FROM @MovimientoTemporalPerdidaRobo;
        --SELECT * FROM @MovimientoTemporalRenovacion;
		--SELECT * FROM @TablaDecrementos;
		--SELECT * FROM @TablaIncrementos


    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION InsertarNuevoMovimientoLote;
        END
        SET @outResultCode = 50008; -- Error en base de datos
        INSERT INTO [dbo].[DBError] VALUES (
            SUSER_NAME(),
            ERROR_NUMBER(),
            ERROR_STATE(),
            ERROR_SEVERITY(),
            ERROR_LINE(),
            ERROR_PROCEDURE(),
            ERROR_MESSAGE(),
            GETDATE()
        );
        EXEC SP_ConsultarError @outResultCode;
    END CATCH
    SET NOCOUNT OFF;
END;