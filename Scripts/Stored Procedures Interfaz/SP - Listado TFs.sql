USE BD1_TP3;

GO
CREATE OR ALTER PROCEDURE SP_ListadoTFs
(
	@inUsuario NVARCHAR(100)
	, @outResultCode INT OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		SET @outResultCode = 0;


		SELECT 
   			tf.Codigo AS CodigoTF
   			, tf.Activa
   			, 'TCM' AS TipoCuenta
			, tf.FechaCreacion
    		, tf.FechaVencimiento
		FROM dbo.TF tf
		INNER JOIN dbo.TC tc
		ON tc.id = tf.idTC
		-- Join para obtener la TCM
		INNER JOIN dbo.TCM tcm
		ON tcm.id = tc.idTCM
		INNER JOIN dbo.TH th
		ON th.id = tcm.idTH
		WHERE th.Usuario = @inUsuario

		UNION ALL

		SELECT 
   			tf.Codigo AS CodigoTF
   			, tf.Activa
   			, 'TCA' AS TipoCuenta
			, tf.FechaCreacion
    		, tf.FechaVencimiento
		FROM dbo.TF tf
		INNER JOIN dbo.TC tc
		ON tc.id = tf.idTC
		-- Joins para obtener la TCM en caso de que sea TCA
		INNER JOIN dbo.TCA tca
		ON tca.id = tc.idTCA
		INNER JOIN dbo.TCM tcm
		ON tcm.id = tca.idTCM
		INNER JOIN dbo.TH th
		ON th.id = tcm.idTH
		WHERE th.Usuario = @inUsuario

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
		EXEC SP_ConsultarError @outResultCode;
	END CATCH
	SET NOCOUNT OFF;
END

/*
EXEC SP_ListadoTFs @outResultCode=0, @inUsuario='jperez';
*/


SELECT * FROM TCM