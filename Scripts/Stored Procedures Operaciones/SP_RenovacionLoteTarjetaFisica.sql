USE BD1_TP3;
GO
CREATE OR ALTER PROCEDURE dbo.SP_RenovacionLoteTarjetaFisica(
    @inFechaOperacion DATETIME, 
    @outResultCode INT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Crear tabla temporal para almacenar la información intermedia y nuevos datos
        DECLARE @MovimientosTemp TABLE (
            idTC INT,
            nuevoCodigo VARCHAR(100),
            nuevoCCV VARCHAR(100),
            Valor MONEY,
            idTipoTCMReposicion INT,
            idTCM INT,
            idTF INT,
            idMov INT,
            Descripcion VARCHAR(100),
            nuevoSaldo MONEY,
            FechaOperacion DATETIME,
            TF VARCHAR(100)
        );

		BEGIN TRANSACTION RenoTarjetaFisica
			-- Insertar datos calculados masivamente en la tabla temporal
			INSERT INTO @MovimientosTemp (idTC, nuevoCodigo, nuevoCCV, Valor, nuevoSaldo, idTipoTCMReposicion, idTCM, idTF, idMov, Descripcion, FechaOperacion, TF)
			SELECT 
				tf.idTC,
				RIGHT('0000000000000000' + CAST(ABS(CHECKSUM(NEWID())) AS VARCHAR(16)), 16),
				RIGHT(CAST(ABS(CHECKSUM(NEWID())) AS VARCHAR(4)), 4),
				COALESCE(TRY_CAST(rn.Valor AS MONEY), 0),
				COALESCE(TRY_CAST(rn.Valor AS MONEY), 0) + COALESCE(tcm.saldoActual, tcmAux.saldoActual, 0),
				COALESCE(tipoTCM.id, tipoTCMAux.id, 0),
				COALESCE(tcm.id, tcmAux.id, 0),
				tf.id,
				tm.id,
				'Renovacion de TF',
				@inFechaOperacion,
				tf.Codigo
			FROM dbo.TF tf 
			INNER JOIN dbo.TC tc ON tc.id = tf.idTC
			LEFT JOIN dbo.TCM tcm ON tcm.id = tc.idTCM
			LEFT JOIN dbo.TCA tca ON tca.id = tc.idTCA
			LEFT JOIN dbo.TCM tcmAux ON tcmAux.id = tca.idTCM
			LEFT JOIN dbo.TipoTCM tipoTCM ON tipoTCM.id = tcm.idTipoTCM
			LEFT JOIN dbo.TipoTCM tipoTCMAux ON tipoTCMAux.id = tcmAux.idTipoTCM
			INNER JOIN dbo.RN rn ON rn.Nombre = CASE 
												   WHEN tcm.id IS NOT NULL THEN 'Cargo renovacion de TF de TCM' 
												   WHEN tcmAux.id IS NOT NULL THEN 'Cargo renovacion de TF de TCA' 
											   END
									AND rn.idTipoTCM = COALESCE(tipoTCM.id, tipoTCMAux.id)
			INNER JOIN dbo.TipoMovimiento tm ON tm.Nombre = 'Renovacion de TF'
			WHERE tf.Activa = 'SI' AND dbo.ParseFecha(TF.FechaVencimiento) <= DATEADD(DAY, 1, @inFechaOperacion) ;


			-- Actualizar masivamente las tarjetas originales para inactivar
			UPDATE tf
			SET Activa = 'NO'
			FROM dbo.TF tf
			INNER JOIN @MovimientosTemp mt ON tf.Codigo = mt.TF;

			-- Insertar las nuevas tarjetas masivamente
			INSERT INTO dbo.TF (idTC, Codigo, CCV, FechaCreacion, FechaVencimiento, Activa)
			SELECT 
				idTC, 
				nuevoCodigo, 
				nuevoCCV, 
				FechaOperacion, 
				FORMAT(DATEADD(YEAR, 6, FechaOperacion), 'M/yyyy'), 
				'SI'
			FROM @MovimientosTemp;

			-- Actualizar saldos de TCM masivamente
			UPDATE tcm
			SET SaldoActual = SaldoActual + mt.Valor
			FROM dbo.TCM tcm
			INNER JOIN @MovimientosTemp mt ON tcm.id = mt.idTCM;

			-- Insertar movimientos masivamente
			INSERT INTO dbo.Movimientos (idTF, idTipoMovimiento, Monto, Descripcion, Fecha, Referencia, Procesado, NuevoSaldo)
			SELECT 
				idTF,
				idMov,
				Valor,
				Descripcion,
				FechaOperacion,
				'',
				1,
				nuevoSaldo
			FROM @MovimientosTemp;

			SET @outResultCode = 0;
        COMMIT TRANSACTION RenoTarjetaFisica;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION RenoTarjetaFisica;
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
