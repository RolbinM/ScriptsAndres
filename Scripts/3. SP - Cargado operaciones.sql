USE BD1_TP3

GO
CREATE OR ALTER PROCEDURE CargarOperacionesXML
(
	@outResultCode INT OUTPUT
	, @inRutaXML NVARCHAR(500)
)
AS
BEGIN

	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRANSACTION Cargado;
			
			DECLARE @Datos xml
			
			DECLARE @FechaOperacionTable TABLE (
				FechaOperacion DATETIME
			)

			DECLARE @NTH TABLE (
				FechaOperacion DATETIME,
				Nombre VARCHAR(100),
				ValorDocIdentidad VARCHAR(100),
				FechaNacimiento DATETIME,
				NombreUsuario VARCHAR(100),
				Password VARCHAR(100)
			)

			DECLARE @NTCM TABLE (
				FechaOperacion DATETIME,
				Codigo VARCHAR(100),
				TipoTCM VARCHAR(100),
				LimiteCredito MONEY,
				TH VARCHAR(100)
			)

			DECLARE @NTCA TABLE (
				FechaOperacion DATETIME,
				CodigoTCM VARCHAR(100),
				CodigoTCA VARCHAR(100),
				TH VARCHAR(100)
			)

			DECLARE @NTF TABLE (
				FechaOperacion DATETIME,
				Codigo VARCHAR(100),
				TCAsociada VARCHAR(100),
				FechaVencimiento VARCHAR(25),
				CCV VARCHAR(25)
			)

			DECLARE @Movimiento dbo.MovimientoVariable

			DECLARE @MovimientoVariable dbo.MovimientoVariable



			DECLARE @FechaOperacion DATETIME;
			DECLARE @FechaFinal DATETIME
			DECLARE @Nombre VARCHAR(100);
			DECLARE @ValorDocIdentidad VARCHAR(100);
			DECLARE @FechaNacimiento DATETIME;
			DECLARE @NombreUsuario VARCHAR(100);
			DECLARE @Password VARCHAR(100);

			DECLARE @Codigo VARCHAR(100);
			DECLARE @TipoTCM VARCHAR(100);
			DECLARE @LimiteCredito MONEY;
			DECLARE @TH VARCHAR(100);

			DECLARE @CodigoTCM VARCHAR(100);
			DECLARE @CodigoTCA VARCHAR(100);

			DECLARE @TCAsociada VARCHAR(100);
			DECLARE @FechaVencimiento VARCHAR(25);
			DECLARE @CCV VARCHAR(25);

			DECLARE @TF VARCHAR(100);
			DECLARE @FechaMovimiento DATETIME;
			DECLARE @Monto DECIMAL(28,8);
			DECLARE @Descripcion VARCHAR(200);
			DECLARE @Referencia VARCHAR(100);







			-- Variables para la carga del XML
			DECLARE @Comando NVARCHAR(500)= 'SELECT @root = D FROM OPENROWSET (BULK '  + CHAR(39) + @inRutaXML + CHAR(39) + ', SINGLE_BLOB) AS root(D)';
			DECLARE @Parametros NVARCHAR(500);
			DECLARE @hdoc INT;

			SET @Parametros = N'@root xml OUTPUT';

			EXEC sp_executesql @Comando, @Parametros, @Datos OUTPUT;
    		EXEC sp_xml_preparedocument @hdoc OUTPUT, @Datos;




			/* Obtener todas las fechas */
			INSERT INTO @FechaOperacionTable (FechaOperacion)
			SELECT *
				FROM OPENXML (@hdoc, '/root/fechaOperacion', 1)
				WITH(
					Fecha DATETIME
				);



			/* Cargar todos los datos del XML */

			-- Consulta para extraer datos de <NTH> en todas las <fechaOperacion>
			INSERT INTO @NTH (FechaOperacion, Nombre, ValorDocIdentidad, FechaNacimiento, NombreUsuario, Password)
			SELECT 
				fechaOperacion.value('@Fecha', 'DATETIME') AS FechaOperacion,
				nth.value('@Nombre', 'VARCHAR(100)') AS Nombre,
				nth.value('@ValorDocIdentidad', 'VARCHAR(100)') AS ValorDocIdentidad,
				nth.value('@FechaNacimiento', 'DATETIME') AS FechaNacimiento,
				nth.value('@NombreUsuario', 'VARCHAR(100)') AS NombreUsuario,
				nth.value('@Password', 'VARCHAR(100)') AS Password
			FROM 
				@Datos.nodes('/root/fechaOperacion') AS Fecha(fechaOperacion)
			CROSS APPLY 
				fechaOperacion.nodes('NTH/NTH') AS NTHData(nth);


			-- Consulta para extraer datos de <NTCM> en todas las <fechaOperacion>
			INSERT INTO @NTCM (FechaOperacion, Codigo, TipoTCM, LimiteCredito, TH)
			SELECT 
				fechaOperacion.value('@Fecha', 'DATETIME') AS FechaOperacion,
				ntcm.value('@Codigo', 'VARCHAR(100)') AS Codigo,
				ntcm.value('@TipoTCM', 'VARCHAR(100)') AS TipoTCM,
				ntcm.value('@LimiteCredito', 'money') AS LimiteCredito,
				ntcm.value('@TH', 'VARCHAR(100)') AS TH
			FROM 
				@Datos.nodes('/root/fechaOperacion') AS Fecha(fechaOperacion)
			CROSS APPLY 
				fechaOperacion.nodes('NTCM/NTCM') AS NTCMData(ntcm);

			-- Consulta para extraer datos de <NTCA> en todas las <fechaOperacion>
			INSERT INTO @NTCA(FechaOperacion, CodigoTCM, CodigoTCA, TH)
			SELECT 
				fechaOperacion.value('@Fecha', 'DATETIME') AS FechaOperacion,
				ntca.value('@CodigoTCM', 'VARCHAR(100)') AS CodigoTCM,
				ntca.value('@CodigoTCA', 'VARCHAR(100)') AS CodigoTCA,
				ntca.value('@TH', 'VARCHAR(100)') AS TH
			FROM 
				@Datos.nodes('/root/fechaOperacion') AS Fecha(fechaOperacion)
			CROSS APPLY 
				fechaOperacion.nodes('NTCA/NTCA') AS NTCAData(ntca);

			-- Consulta para extraer datos de <NTF> en todas las <fechaOperacion>
			INSERT INTO @NTF(FechaOperacion, Codigo, TCAsociada, FechaVencimiento, CCV)
			SELECT 
				fechaOperacion.value('@Fecha', 'DATETIME') AS FechaOperacion,
				ntf.value('@Codigo', 'VARCHAR(100)') AS Codigo,
				ntf.value('@TCAsociada', 'VARCHAR(100)') AS TCAsociada,
				ntf.value('@FechaVencimiento', 'VARCHAR(25)') AS FechaVencimiento,
				ntf.value('@CCV', 'VARCHAR(25)') AS CCV
			FROM 
				@Datos.nodes('/root/fechaOperacion') AS Fecha(fechaOperacion)
			CROSS APPLY 
				fechaOperacion.nodes('NTF/NTF') AS NTFData(ntf);


			-- Consulta para extraer Movimientos en todas las fechaOperacion
			INSERT INTO @Movimiento(FechaOperacion, Nombre, TF, FechaMovimiento, Monto, Descripcion, Referencia)
			SELECT 
				fechaOperacion.value('@Fecha', 'DATETIME') AS FechaOperacion,
				movimiento.value('@Nombre', 'VARCHAR(100)') AS Nombre,
				movimiento.value('@TF', 'VARCHAR(20)') AS TF,
				movimiento.value('@FechaMovimiento', 'DATETIME') AS FechaMovimiento,
				movimiento.value('@Monto', 'DECIMAL(18, 2)') AS Monto,
				movimiento.value('@Descripcion', 'VARCHAR(255)') AS Descripcion,
				movimiento.value('@Referencia', 'VARCHAR(50)') AS Referencia
			FROM 
				@Datos.nodes('/root/fechaOperacion') AS Fecha(fechaOperacion)
			CROSS APPLY 
				fechaOperacion.nodes('Movimiento/Movimiento') AS MovimientoData(movimiento);




			/* PRUEBAS */

			--SELECT * FROM @NTH
			--SELECT * FROM @NTCM
			--SELECT * FROM @NTCA
			--SELECT * FROM @NTF
			--SELECT * FROM @Movimiento



			-- Cursor para iterar sobre las fechas de operación
			
			SELECT
				@FechaOperacion = MIN(FechaOperacion),
				@FechaFinal = MAX(FechaOperacion)
			FROM @FechaOperacionTable
			
			
			WHILE @FechaOperacion <= @FechaFinal
			BEGIN
				-- Iterar sobre la tabla @NTH para cada FechaOperacion
				DECLARE NTHCursor CURSOR FOR
					SELECT Nombre, ValorDocIdentidad, FechaNacimiento, NombreUsuario, Password
					FROM @NTH
					WHERE FechaOperacion = @FechaOperacion;

				OPEN NTHCursor;
				FETCH NEXT FROM NTHCursor INTO @Nombre, @ValorDocIdentidad, @FechaNacimiento, @NombreUsuario, @Password;

				WHILE @@FETCH_STATUS = 0
				BEGIN
					-- Llamar al procedimiento almacenado para cada fila de @NTH
					EXEC dbo.SP_InsertarNuevoTarjetaHabiente @Nombre, @ValorDocIdentidad, @FechaNacimiento, @NombreUsuario, @Password, 0;

					FETCH NEXT FROM NTHCursor INTO @Nombre, @ValorDocIdentidad, @FechaNacimiento, @NombreUsuario, @Password;
				END

				CLOSE NTHCursor;
				DEALLOCATE NTHCursor;






				-- Iterar sobre la tabla @NTCM para cada FechaOperacion
				DECLARE NTCMCursor CURSOR FOR
					SELECT Codigo, TipoTCM, LimiteCredito, TH
					FROM @NTCM
					WHERE FechaOperacion = @FechaOperacion;

				OPEN NTCMCursor;
				FETCH NEXT FROM NTCMCursor INTO @Codigo, @TipoTCM, @LimiteCredito, @TH;

				WHILE @@FETCH_STATUS = 0
				BEGIN
					-- Llamar al procedimiento almacenado para cada fila de @NTCM
					EXEC dbo.SP_InsertarNuevaTarjetaCreditoMaestra @Codigo, @TipoTCM, @LimiteCredito, @TH, 0;

					FETCH NEXT FROM NTCMCursor INTO @Codigo, @TipoTCM, @LimiteCredito, @TH;
				END

				CLOSE NTCMCursor;
				DEALLOCATE NTCMCursor;





				-- Iterar sobre la tabla @NTCA para cada FechaOperacion
				DECLARE NTACursor CURSOR FOR
					SELECT CodigoTCM, CodigoTCA, TH
					FROM @NTCA
					WHERE FechaOperacion = @FechaOperacion;

				OPEN NTACursor;
				FETCH NEXT FROM NTACursor INTO @CodigoTCM, @CodigoTCA, @TH;

				WHILE @@FETCH_STATUS = 0
				BEGIN
					-- Llamar al procedimiento almacenado para cada fila de @NTCA
					EXEC dbo.SP_InsertarNuevaTarjetaCreditoAdicional @CodigoTCM, @CodigoTCA, @TH, 0;

					FETCH NEXT FROM NTACursor INTO @CodigoTCM, @CodigoTCA, @TH;
				END

				CLOSE NTACursor;
				DEALLOCATE NTACursor;





				-- Iterar sobre la tabla @NTF para cada FechaOperacion
				DECLARE NTFCursor CURSOR FOR
					SELECT Codigo, TCAsociada, FechaVencimiento, CCV
					FROM @NTF
					WHERE FechaOperacion = @FechaOperacion;

				OPEN NTFCursor;
				FETCH NEXT FROM NTFCursor INTO @Codigo, @TCAsociada, @FechaVencimiento, @CCV;

				WHILE @@FETCH_STATUS = 0
				BEGIN
					-- Llamar al procedimiento almacenado para cada fila de @NTF
					EXEC SP_InsertarNuevaTarjetaFisica @Codigo, @TCAsociada, @FechaVencimiento, @CCV, 0;

					FETCH NEXT FROM NTFCursor INTO @Codigo, @TCAsociada, @FechaVencimiento, @CCV;
				END

				CLOSE NTFCursor;
				DEALLOCATE NTFCursor;





				-- Sacamos el lote de movimientos de la fechaOperacion
				
				INSERT INTO @MovimientoVariable(FechaOperacion,Nombre, TF, FechaMovimiento, Monto, Descripcion, Referencia)
				SELECT FechaOperacion, Nombre, TF, FechaMovimiento, Monto, Descripcion, Referencia
				FROM @Movimiento
				WHERE FechaOperacion = @FechaOperacion;

				--EXEC dbo.SP_InsertarNuevoMovimiento @Nombre, @TF, @FechaMovimiento, @Monto, @Descripcion, @Referencia, 0;

				DELETE FROM @MovimientoVariable


				SELECT @FechaOperacion = DATEADD(DAY, 1, @FechaOperacion)
				
			END



			EXEC sp_xml_removedocument @hdoc

		COMMIT TRANSACTION Cargado;
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK TRANSACTION Cargado;
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
ANDRES
EXEC CargarOperacionesXML @outResultCode=50008, @inRutaXML='C:\Users\AndresMFIT\OneDrive\Principal\Universidad\Semestre II 2024\BD1\Tarea 3\BDI-T3\Resources\OperacionesFinal.xml';

FOFO
EXEC CargarOperacionesXML @outResultCode=50008, @inRutaXML='C:\Users\AndresMFIT\OneDrive\Principal\Universidad\Semestre II 2024\BD1\Tarea 3\BDI-T3\Resources\OperacionesFinal.xml';

ROLBINCITO
EXEC CargarOperacionesXML @outResultCode=50008, @inRutaXML='C:\OperacionesFinal.xml';
*/