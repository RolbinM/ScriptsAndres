USE BD1_TP3;

/* Procedimiento de Inserción de Nuevos Tarjeta Habientes */
GO
CREATE OR ALTER PROCEDURE dbo.SP_InsertarNuevoTarjetaHabiente(
	@inNombre VARCHAR(100),
	@inValorDocIdentidad VARCHAR(100),
	@inFechaNacimiento DATETIME,
	@inNombreUsuario VARCHAR(100),
	@inContraseña VARCHAR(100),
	@outResultCode INT OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		SET @outResultCode = 0;
		BEGIN TRANSACTION InsertarNuevoTarjetaHabiente;

			IF EXISTS (SELECT id FROM dbo.TH WHERE ValorDI = @inValorDocIdentidad)
			BEGIN
				-- El documento de identidad ya esta registrado.
				SET @outResultCode = 50009;
				EXEC SP_ConsultarError @outResultCode;
				COMMIT TRANSACTION InsertarNuevoTarjetaHabiente;
				RETURN
			END
			
			INSERT INTO dbo.TH(
				idTipoDI,
				ValorDI,
				Nombre,
				FechaNacimiento,
				Usuario,
				Contraseña
			) VALUES(
				1,
				@inValorDocIdentidad,
				@inNombre,
				@inFechaNacimiento,
				@inNombreUsuario,
				@inContraseña
			)
	

		COMMIT TRANSACTION InsertarNuevoTarjetaHabiente;
		EXEC SP_ConsultarError @outResultCode;
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK TRANSACTION InsertarNuevoTarjetaHabiente;
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










/* Procedimiento de Insertar Nuevas Tarjetas Credito Maestras*/
GO
CREATE OR ALTER PROCEDURE dbo.SP_InsertarNuevaTarjetaCreditoMaestra(
	@inCodigo VARCHAR(50),
	@inTipoTCM VARCHAR(50),
	@inLimiteCredito MONEY,
	@inValorDocumentoTarjetaHabiente VARCHAR(100),
	@outResultCode INT OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @idTarjetaHabiente INT
		DECLARE @idTipoTCM INT
		DECLARE @idTCM INT
			
		SET @outResultCode = 0;
		BEGIN TRANSACTION NuevaTarjetaCreditoMaestra;

			IF NOT EXISTS (SELECT id FROM dbo.TH WHERE ValorDI = @inValorDocumentoTarjetaHabiente)
			BEGIN
				-- No se ha encontrado el usuario con ese documento de identidad.
				SET @outResultCode = 50010;
				EXEC SP_ConsultarError @outResultCode;
				COMMIT TRANSACTION NuevaTarjetaCreditoMaestra;
				RETURN
			END

			IF NOT EXISTS (SELECT id FROM dbo.TipoTCM WHERE Nombre = @inTipoTCM)
			BEGIN
				-- El tipo de TCM ingresado no se ha encontrado.
				SET @outResultCode = 50011;
				EXEC SP_ConsultarError @outResultCode;
				COMMIT TRANSACTION NuevaTarjetaCreditoMaestra;
				RETURN
			END

			IF EXISTS (SELECT id FROM dbo.TCM WHERE Codigo = @inCodigo)
			BEGIN
				-- Ya existe una TCM registrada con ese codigo.
				SET @outResultCode = 50012;
				EXEC SP_ConsultarError @outResultCode;
				COMMIT TRANSACTION NuevaTarjetaCreditoMaestra;
				RETURN
			END
			
			SELECT
				@idTarjetaHabiente = id
			FROM dbo.TH  
			WHERE ValorDI = @inValorDocumentoTarjetaHabiente

			SELECT
				@idTipoTCM = id
			FROM dbo.TipoTCM  
			WHERE Nombre = @inTipoTCM

			INSERT INTO dbo.TCM(
				Codigo,
				LimiteCredito,
				idTipoTCM,
				idTH
			) VALUES(
				@inCodigo,
				@inLimiteCredito,
				@idTipoTCM,
				@idTarjetaHabiente
			)

			SELECT
				@idTCM = id
			FROM dbo.TCM  
			WHERE Codigo = @inCodigo

			INSERT INTO dbo.TC(
				idTCM,
				idTCA
			) VALUES(
				@idTCM,
				NULL
			)

		COMMIT TRANSACTION NuevaTarjetaCreditoMaestra;
		EXEC SP_ConsultarError @outResultCode;
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK TRANSACTION NuevaTarjetaCreditoMaestra;
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






/* Procedimiento de Insertar Nuevas Tarjetas Credito Adicional*/
GO
CREATE OR ALTER PROCEDURE dbo.SP_InsertarNuevaTarjetaCreditoAdicional(
	@inCodigoTCM VARCHAR(50),
	@inCodigoTCA VARCHAR(50),
	@inValorDocumentoTarjetaHabiente VARCHAR(100),
	@outResultCode INT OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @idTarjetaHabiente INT
		DECLARE @idTCM INT
		DECLARE @idTCA INT
			
		SET @outResultCode = 0;
		BEGIN TRANSACTION NuevaTarjetaCreditoAdicional;

			IF NOT EXISTS (SELECT id FROM dbo.TH WHERE ValorDI = @inValorDocumentoTarjetaHabiente)
			BEGIN
				-- No se ha encontrado el usuario con ese documento de identidad.
				SET @outResultCode = 50010;
				EXEC SP_ConsultarError @outResultCode;
				COMMIT TRANSACTION NuevaTarjetaCreditoAdicional
				RETURN
			END

			IF NOT EXISTS (SELECT id FROM dbo.TCM WHERE Codigo = @inCodigoTCM)
			BEGIN
				-- No existe TCM a la que asociar la TCA.
				SET @outResultCode = 50020;
				EXEC SP_ConsultarError @outResultCode;
				COMMIT TRANSACTION NuevaTarjetaCreditoAdicional
				RETURN
			END

			IF EXISTS (SELECT id FROM dbo.TCA WHERE CodigoTCA = @inCodigoTCA)
			BEGIN
				-- Ya existe TCA registrada con ese codigo.
				SET @outResultCode = 50013;
				EXEC SP_ConsultarError @outResultCode;
				COMMIT TRANSACTION NuevaTarjetaCreditoAdicional
				RETURN
			END
			
			SELECT
				@idTarjetaHabiente = id
			FROM dbo.TH  
			WHERE ValorDI = @inValorDocumentoTarjetaHabiente

			SELECT
				@idTCM = id
			FROM dbo.TCM  
			WHERE Codigo = @inCodigoTCM

			INSERT INTO dbo.TCA(
				idTH,
				idTCM,
				CodigoTCA
			) VALUES(
				@idTarjetaHabiente,
				@idTCM,
				@inCodigoTCA
			)

			SELECT
				@idTCA = id
			FROM dbo.TCA  
			WHERE CodigoTCA = @inCodigoTCA

			INSERT INTO dbo.TC(
				idTCM,
				idTCA
			) VALUES(
				NULL,
				@idTCA
			)



		COMMIT TRANSACTION NuevaTarjetaCreditoAdicional;
		EXEC SP_ConsultarError @outResultCode;
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK TRANSACTION NuevaTarjetaCreditoAdicional;
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




/* Procedimiento de Insertar Nuevas Tarjetas Fisicas*/
GO
CREATE OR ALTER PROCEDURE dbo.SP_InsertarNuevaTarjetaFisica(
	@inCodigo VARCHAR(150),
	@inCodigoTCAsociada VARCHAR(100),
	@inFechaVencimiento VARCHAR(25),
	@inCCV VARCHAR(25),
	@outResultCode INT OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @idTCAsociada INT
			
		SET @outResultCode = 0;
		BEGIN TRANSACTION NuevaTarjetaFisica;
			
			SELECT
				@idTCAsociada = tc.id
			FROM dbo.TC tc
			INNER JOIN dbo.TCM tcm
			ON tcm.id = tc.idTCM
			WHERE tcm.Codigo = @inCodigoTCAsociada

			IF @idTCAsociada IS NULL
			BEGIN
				SELECT
					@idTCAsociada = tc.id
				FROM dbo.TC tc
				INNER JOIN dbo.TCA tca
				ON tca.id = tc.idTCA
				WHERE tca.CodigoTCA = @inCodigoTCAsociada
			END

			IF @idTCAsociada IS NULL
			BEGIN
				-- No se encontro TC asociada.
				SET @outResultCode = 50014;
				EXEC SP_ConsultarError @outResultCode;
				COMMIT TRANSACTION NuevaTarjetaFisica;
				RETURN
			END
			
			IF EXISTS (SELECT id FROM dbo.TF WHERE Codigo = @inCodigo)
			BEGIN
				-- No se ingreso TF, ya existe ese codigo.
				SET @outResultCode = 50015;
				EXEC SP_ConsultarError @outResultCode;
				COMMIT TRANSACTION NuevaTarjetaFisica;
				RETURN
			END

			INSERT INTO dbo.TF(
				idTC,
				Codigo,
				CCV,
				FechaCreacion,
				FechaVencimiento,
				Activa
			) VALUES(
				@idTCAsociada,
				@inCodigo,
				@inCCV,
				GETDATE(),
				@inFechaVencimiento,
				'SI'
			)


		COMMIT TRANSACTION NuevaTarjetaFisica;
		EXEC SP_ConsultarError @outResultCode;
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK TRANSACTION NuevaTarjetaFisica;
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












--<Movimiento Nombre="Cargos por Multa Exceso Uso ATM" TF="5373571423133445" FechaMovimiento="2024-01-01" Monto="90358" Descripcion="En Goicoechea" Referencia="S3W04" />

-- Inserción de nuevo movimiento 
GO
CREATE OR ALTER PROCEDURE dbo.SP_InsertarNuevoMovimiento(
	@inNombre NVARCHAR(100),
	@inTarjetaFisica VARCHAR(150),
	@inFechaMovimiento DATETIME,
	@inMonto MONEY,
	@inDescripcion NVARCHAR(300),
	@inReferencia NVARCHAR(300),
	@outResultCode INT OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRANSACTION InsertarNuevoMovimiento;
			SET @outResultCode = 0;
		
			-- Definimos el id tipo de movimiento en base al nombre que recibimos
			DECLARE @idTipoMovimiento INT;
			SET @idTipoMovimiento = (SELECT TM.id FROM [dbo].TipoMovimiento AS TM WHERE TM.Nombre = @inNombre);

			-- Definimos si el movimiento es sospechoso y extraemos los valores de las posibles fechas junto al id de la tarjeta fisica
			DECLARE @esSospechoso VARCHAR(3);
			DECLARE @fechaCreacionTF DATETIME;
			DECLARE @fechaVencimientoTF VARCHAR(25);
			DECLARE @idTarjetaFisica INT;

		
			SELECT @fechaCreacionTF = tf.FechaCreacion,
				   @fechaVencimientoTF = tf.FechaVencimiento ,
				   @idTarjetaFisica = tf.id
			FROM [dbo].TF AS tf 
			WHERE tf.Codigo = @inTarjetaFisica;

			-- Validamos que los valores sean validos
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

			--IF @fechaVencimientoTF IS NULL
			--BEGIN
			--	SET @outResultCode = 50018;
			--	EXEC SP_ConsultarError @outResultCode;
			--	COMMIT TRANSACTION InsertarNuevoMovimiento;
			--	RETURN
			--END 

			IF @idTarjetaFisica IS NULL
			BEGIN
				SET @outResultCode = 50019;
				EXEC SP_ConsultarError @outResultCode;
				COMMIT TRANSACTION InsertarNuevoMovimiento;
				RETURN
			END 
			
			--------------------------------- REVISAR -------------------------------------------------------------
			IF @fechaCreacionTF > @inFechaMovimiento -- AND @fechaVencimientoTF < @inFechaMovimiento
				SET @esSospechoso = 'SI';
			ELSE
				SET @esSospechoso = 'NO';

		
			INSERT INTO Movimientos (idTF, idTipoMovimiento, Monto, Descripcion, Fecha, Sospechoso, Referencia)
			 VALUES (@idTarjetaFisica, @idTipoMovimiento, @inMonto, @inDescripcion, @inFechaMovimiento, @esSospechoso, @inReferencia);

		COMMIT TRANSACTION InsertarNuevoMovimiento;
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK TRANSACTION InsertarNuevoMovimiento;
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