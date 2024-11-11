USE BD1_TP3;

GO
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
		DECLARE @MovimientoTemporal dbo.MovimientoTemporal,
		 @MovimientoTemporalSospechoso dbo.MovimientoTemporal,
		 @MovimientoTemporalParaEC dbo.MovimientoTemporal,
		 @MovimientoTemporalPerdidaRobo dbo.MovimientoTemporal,
		 @MovimientoTemporalRenovacion dbo.MovimientoTemporal,
		 @tempNuevoSaldo MONEY;

        -- Crear una tabla temporal para almacenar la CTE MovimientosConInfo
        CREATE TABLE #MovimientosConInfo (
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
        INSERT INTO #MovimientosConInfo
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
            #MovimientosConInfo
        WHERE 
            Nombre IN ('Compra', 'Retiro en ATM', 'Pago en ATM', 'Retiro en Ventana', 'Pago en Ventana', 'Pago en Linea');

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
            #MovimientosConInfo
        WHERE 
            Nombre IN ('Cargos por Servicio', 'Cargos por Multa Exceso Uso ATM', 'Cargos por Multa Exceso Uso Ventana');

        INSERT INTO @MovimientoTemporalPerdidaRobo (idTF, idTipoMovimiento, Monto, Descripcion, Fecha, Referencia, Procesado, NuevoSaldo)
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
            #MovimientosConInfo
        WHERE 
            Nombre IN ('Recuperacion por Perdida', 'Recuperacion por Robo');

        INSERT INTO @MovimientoTemporalRenovacion (idTF, idTipoMovimiento, Monto, Descripcion, Fecha, Referencia, Procesado, NuevoSaldo)
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
            #MovimientosConInfo
        WHERE 
            Nombre IN ('Renovacion de TF');

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
            #MovimientosConInfo
        WHERE 
            fechaCreacionTF IS NULL
            OR fechaVencimientoTF IS NULL
            OR idTipoMovimiento IS NULL
            OR fechaCreacionTF > FechaMovimiento 
            OR fechaVencimientoTF < FechaMovimiento 
            OR TFActiva = 'NO';

		--Aplica los movimientos al saldo

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

		INSERT INTO @TablaIncrementos(Fecha, Referencia, Monto, idTF, idTCM)
		SELECT mt.Fecha, mt.Referencia, mt.Monto, tf.id, CASE 
					WHEN tcm.id IS NOT NULL THEN tcm.id
					WHEN tca.id IS NOT NULL THEN tcmAux.id
					ELSE ''
				END
		FROM 
			TipoMovimiento as TM
			INNER JOIN 
			@MovimientoTemporal as mt
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

		INSERT INTO @TablaDecrementos(Fecha, Referencia, Monto, idTF, idTCM)
		SELECT mt.Fecha, mt.Referencia, mt.Monto, tf.id, CASE 
					WHEN tcm.id IS NOT NULL THEN tcm.id
					WHEN tca.id IS NOT NULL THEN tcmAux.id
					ELSE ''
				END
		FROM 
			TipoMovimiento as TM
			INNER JOIN 
			@MovimientoTemporal as mt
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

		DECLARE @CurrentRow INT = 1;
		DECLARE @MaxRow INT;

		SELECT @MaxRow = COUNT(*) FROM @TablaIncrementos;


		--Ciclo para actualizar incrementos
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

			SET @CurrentRow = @CurrentRow + 1;
		END

		SET @CurrentRow = 1
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

			SET @CurrentRow = @CurrentRow + 1;
		END


		--Insercion de Movimientos a la tabla real----------------------------------------------------------------

		INSERT INTO Movimientos (idTF, idTipoMovimiento, Monto, Descripcion, Fecha, Referencia, Procesado, NuevoSaldo)
		SELECT idTF, idTipoMovimiento, Monto, Descripcion, Fecha, Referencia, Procesado, NuevoSaldo FROM @MovimientoTemporal
		UNION ALL
		--SELECT idTF, idTipoMovimiento, Monto, Descripcion, Fecha, Referencia, Procesado, NuevoSaldo FROM @MovimientoTemporalSospechoso
		--UNION ALL
		SELECT idTF, idTipoMovimiento, Monto, Descripcion, Fecha, Referencia, Procesado, NuevoSaldo FROM @MovimientoTemporalParaEC
		UNION ALL
		SELECT idTF, idTipoMovimiento, Monto, Descripcion, Fecha, Referencia, Procesado, NuevoSaldo FROM @MovimientoTemporalPerdidaRobo
		UNION ALL
		SELECT idTF, idTipoMovimiento, Monto, Descripcion, Fecha, Referencia, Procesado, NuevoSaldo FROM @MovimientoTemporalRenovacion;	
		

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


        -- Elimina la tabla temporal
        DROP TABLE #MovimientosConInfo;

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
GO

-----PRUEBAS---------------------------------------------------------------------------------------------------------------------------
/*
declare @ex MovimientoVariable

INSERT INTO @ex (FechaOperacion, Nombre, TF, FechaMovimiento, Monto, Descripcion, Referencia) 
VALUES('2024-01-01','Compra', '5655636577940569', '2030-01-01', '83779', 'ATM de Palmares', '18TPD')

INSERT INTO @ex (FechaOperacion, Nombre, TF, FechaMovimiento, Monto, Descripcion, Referencia) 
VALUES('2024-01-01','Cargos por Multa Exceso Uso ATM', '5373571423133445', '2025-01-01', '90358', 'En Goicoechea', 'S3W04')

INSERT INTO @ex (FechaOperacion, Nombre, TF, FechaMovimiento, Monto, Descripcion, Referencia) 
VALUES('2024-01-01','Recuperacion por Perdida', '5525247354599728', '2025-01-01', '0', 'Sucursal en Cartago', 'EQKNP')

INSERT INTO @ex (FechaOperacion, Nombre, TF, FechaMovimiento, Monto, Descripcion, Referencia) 
VALUES('2024-01-01','Compra', '5525247354599728', '2026-01-01', '10000', 'ATM de Palmares', '18MMMD')

INSERT INTO @ex (FechaOperacion, Nombre, TF, FechaMovimiento, Monto, Descripcion, Referencia) 
VALUES('2024-01-01','Pago en Linea', '7634009855741021', '2024-04-13', '28558', 'Sucursal en Atenas', 'QSRSO')

SELECT * FROM @ex

Declare @code int;
EXEC SP_InsertarLoteMovimientos @ex, @code OUTPUT;

SELECT * FROM TF as tf WHERE tf.Codigo = 5655636577940569
SELECT * FROM TF as tf WHERE tf.Codigo = 5373571423133445
SELECT * FROM TF as tf WHERE tf.Codigo = 5525247354599728

SELECT * FROM TF as tf WHERE id = 2
select * from TC where id = 6
select * from TCA where id = 3
select * from TCM where id = 3

select * from TCM where id = 1

UPDATE TCM
SET SaldoActual = SaldoActual + 87000
FROM TCM as tcm
where tcm.id = 3
*/
----------------------------------------------------------------------------------------------------------------------------------------------------------