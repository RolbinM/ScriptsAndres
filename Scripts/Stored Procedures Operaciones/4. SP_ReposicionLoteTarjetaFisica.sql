USE BD1_TP3;

DROP PROCEDURE IF EXISTS dbo.SP_ReposicionLoteTarjetaFisica;

GO
CREATE OR ALTER PROCEDURE dbo.SP_ReposicionLoteTarjetaFisica(
	@inMovimientos dbo.MovimientoVariable READONLY, 
	@outResultCode INT OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @Movimientos TABLE(
			FechaOperacion DATETIME,
			Nombre VARCHAR(100),
			TF VARCHAR(100),
			FechaMovimiento DATETIME,
			Monto DECIMAL(28,8),
			Descripcion VARCHAR(200),
			Referencia VARCHAR(100),
			Procesado BIT DEFAULT 0,
			NuevoSaldo MONEY
		)

		DECLARE @idTC INT
		DECLARE @nuevoCodigo VARCHAR(16)
		DECLARE @nuevoCCV VARCHAR(16)
		DECLARE @inCodigoTarjetaRobada VARCHAR(150)

		DECLARE @NombreMovimientoReposicion VARCHAR(100)
		DECLARE @NombreMovimiento VARCHAR(100)
		DECLARE @Descripcion VARCHAR(100)
		DECLARE @Referencia VARCHAR(100)

		DECLARE @idTipoTCMReposicion INT
		DECLARE @idTCM INT
		DECLARE @idTF INT
		DECLARE @idMov INT
		DECLARE @Valor MONEY
		DECLARE @nuevoSaldo MONEY

		DECLARE @FechaOperacion DATETIME

		DECLARE @Count INT
			
		SET @outResultCode = 0;
		BEGIN TRANSACTION ReposicionTarjetaFisica;
			
			INSERT INTO @Movimientos
			SELECT * FROM @inMovimientos

			SELECT @Count = COUNT(*) FROM @Movimientos

			WHILE @Count > 0
			BEGIN
				SELECT TOP(1)
					@inCodigoTarjetaRobada = TF,
					@NombreMovimiento = Nombre,
					@Descripcion = Descripcion,
					@Referencia = Referencia,
					@FechaOperacion = FechaOperacion
				FROM @Movimientos


				IF NOT EXISTS (SELECT 1 FROM dbo.TF WHERE Codigo = @inCodigoTarjetaRobada AND Activa = 'SI')
				BEGIN
					SET @outResultCode = 50021;
					EXEC SP_ConsultarError @outResultCode;
					COMMIT TRANSACTION ReposicionTarjetaFisica;
					RETURN
				END

				SELECT
					@idTC = idTC,
					@nuevoCCV = RIGHT(CAST(ABS(CHECKSUM(NEWID())) AS VARCHAR(4)), 4),
					@nuevoCodigo = CAST(ABS(CHECKSUM(NEWID())) AS VARCHAR(16)) 
					 + RIGHT(CAST(ABS(CHECKSUM(NEWID())) AS VARCHAR(16)), 8)
				FROM dbo.TF tf
				WHERE Codigo = @inCodigoTarjetaRobada


				UPDATE dbo.TF
				SET
					Activa = 'NO'
				WHERE Codigo = @inCodigoTarjetaRobada

				INSERT INTO dbo.TF(
					idTC,
					Codigo,
					CCV,
					FechaCreacion,
					FechaVencimiento,
					Activa
				) VALUES(
					@idTC,
					@nuevoCodigo,
					@nuevoCCV,
					GETDATE(),
					FORMAT(DATEADD(YEAR, 6, GETDATE()), 'M/yyyy'),
					'SI'
				)

				-- Movimiento en MOVIMIENTOS
				SELECT
					@idTCM = CASE 
						WHEN tcm.id IS NOT NULL THEN tcm.id
						WHEN tcmAux.id IS NOT NULL THEN tcmAux.id
						ELSE 0
					END,
					@NombreMovimientoReposicion = CASE 
						WHEN tcm.id IS NOT NULL THEN 'Reposicion de tarjeta de TCM'
						WHEN tca.id IS NOT NULL THEN 'Reposicion de tarjeta de TCA'
						ELSE ''
					END,
					@idTipoTCMReposicion = CASE 
						WHEN tipoTCM.id IS NOT NULL THEN tipoTCM.id
						WHEN tipoTCMAux.id IS NOT NULL THEN tipoTCMAux.id
						ELSE 0
					END
				FROM dbo.TF tf
				INNER JOIN dbo.TC tc
				ON tc.id = tf.idTC

				-- Join para obtener la TCM
				LEFT JOIN dbo.TCM tcm
				ON tcm.id = tc.idTCM

				-- Joins para obtener la TCM en caso de que sea TCA
				LEFT JOIN dbo.TCA tca
				ON tca.id = tc.idTCA
				LEFT JOIN dbo.TCM tcmAux
				ON tcmAux.id = tca.idTCM

				-- Joins para obtener los tipos de las TCM y su nombre
				LEFT JOIN dbo.TipoTCM tipoTCM
				ON tipoTCM.id = tcm.idTipoTCM
				LEFT JOIN dbo.TipoTCM tipoTCMAux
				ON tipoTCMAux.id = tcmAux.idTipoTCM

				WHERE tf.Codigo = @inCodigoTarjetaRobada


				-- Retorna el valor para generar el movimiento
				SELECT 
					@Valor = Valor
				FROM dbo.RN rn
				INNER JOIN dbo.TipoRN trn
				ON trn.id = rn.idTipoRN
				WHERE 
					rn.Nombre = @NombreMovimientoReposicion
					AND rn.idTipoTCM = @idTipoTCMReposicion

				SELECT
					@idTf = id
				FROM dbo.TF 
				WHERE Codigo = @nuevoCodigo

				SELECT
					idMov = id
				FROM dbo.TipoMovimiento
				WHERE Nombre = @NombreMovimiento

				UPDATE TCM
				SET SaldoActual = SaldoActual + @Valor
				FROM TCM as tcm 
				WHERE tcm.id = @idTCM

				SELECT
					@nuevoSaldo = SaldoActual
				FROM dbo.TCM
				WHERE tcm.id = @idTCM

				INSERT INTO dbo.Movimientos (
					idTF,
					idTipoMovimiento, 
					Monto, Descripcion, 
					Fecha, 
					Referencia, 
					Procesado, 
					NuevoSaldo
				) VALUES(
					@idTf,
					@idMov,
					@Valor,
					@Descripcion,
					@Referencia,
					@FechaOperacion,
					'SI',
					@nuevoSaldo
				)

				DELETE FROM @Movimientos WHERE Referencia = @Referencia AND TF = @inCodigoTarjetaRobada

			END

			
		COMMIT TRANSACTION ReposicionTarjetaFisica;
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK TRANSACTION ReposicionTarjetaFisica;
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


