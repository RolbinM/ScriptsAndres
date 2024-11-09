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
	@Referencia VARCHAR(100);

	-- Obtener los datos de la fila actual usando ROW_NUMBER
	;WITH FilasNumeradas AS (
	SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowID,
	   FechaOperacion, Nombre, TF, FechaMovimiento, Monto, Descripcion, Referencia
	FROM @Movimientos
	)
	SELECT @FechaOperacion = FechaOperacion,
	   @Nombre = Nombre,
	   @TF = TF,
	   @FechaMovimiento = FechaMovimiento,
	   @Monto = Monto,
	   @Descripcion = Descripcion,
	   @Referencia = Referencia
	FROM FilasNumeradas
	WHERE RowID = @FilaActual;

	-- Logica para ver como insertar el movimiento


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