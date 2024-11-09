DROP PROCEDURE dbo.SP_ReposicionTarjetaFisica

CREATE OR ALTER PROCEDURE dbo.SP_ReposicionTarjetaFisica(
	@inCodigoTarjetaRobada VARCHAR(150),
	@outResultCode INT OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @idTC INT
		DECLARE @nuevoCodigo VARCHAR(16)
		DECLARE @nuevoCCV VARCHAR(16)

		DECLARE @NombreMovimientoReposicion VARCHAR(100)
		DECLARE @idTipoTCMReposicion INT
			
		SET @outResultCode = 0;
		BEGIN TRANSACTION ReposicionTarjetaFisica;
				
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
				Valor
			FROM dbo.RN rn
			INNER JOIN dbo.TipoRN trn
			ON trn.id = rn.idTipoRN
			WHERE 
				rn.Nombre = @NombreMovimientoReposicion
				AND rn.idTipoTCM = @idTipoTCMReposicion
			

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


