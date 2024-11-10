USE BD1_TP3;

DROP PROCEDURE IF EXISTS dbo.SP_Login;

GO
CREATE OR ALTER PROCEDURE dbo.SP_Login(
    @inUsuario VARCHAR(150),
    @inClave VARCHAR(150),
    @outResultCode INT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @existeInAdministrador BIT = 0;
        DECLARE @existeInTH BIT = 0;

        IF EXISTS (SELECT 1 FROM dbo.Administrador a WHERE a.Usuario = @inUsuario AND a.Contraseña = @inClave)
        BEGIN
            SET @existeInAdministrador = 1;
        END

        IF EXISTS (SELECT 1 FROM dbo.TH th WHERE th.Usuario = @inUsuario AND th.Contraseña = @inClave)
        BEGIN
            SET @existeInTH = 1;
        END


        IF @existeInAdministrador = 1
        BEGIN
            SET @outResultCode = 1; -- Usuario encontrado en Administrador
        END
        ELSE IF @existeInTH = 1
        BEGIN
            SET @outResultCode = 2; -- Usuario encontrado en TH
        END
        ELSE
        BEGIN
            SET @outResultCode = 404; -- Usuario o contraseña no encontrados
        END

        BEGIN TRANSACTION LoginUsuario;
        COMMIT TRANSACTION LoginUsuario;
    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION LoginUsuario;
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
END
