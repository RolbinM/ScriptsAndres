-- DROP DATABASE IF EXISTS BD1_TP3;

-- CREATE DATABASE BD1_TP3;

USE BD1_TP3;

-- Se desactiva el recuento de filas
SET NOCOUNT ON;

-- Resetea las INDENTITIES o IDs
-- (Se usa solo si en vez de DROP TABLE fuera DELETE [dbo].[Empleado];
-- DBCC CHECKIDENT ('[dbo].[Empleado]', RESEED, 0);

-- Limpia las tablas
-- Se puede usar la instrucción IF EXISTS para evitar errores: DROP TABLE IF EXISTS BitacoraEvento;
-- A continuación se usa así para efectos de testing...

-- Tablas con dependencias externas
DROP TABLE IF EXISTS MovimientosSospechosos;
DROP TABLE IF EXISTS Movimientos;
DROP TABLE IF EXISTS MIM;
DROP TABLE IF EXISTS MI;
DROP TABLE IF EXISTS EstadoCuenta;
DROP TABLE IF EXISTS SubEstadoCuenta;
DROP TABLE IF EXISTS TF;
DROP TABLE IF EXISTS TC;
DROP TABLE IF EXISTS TCA;
DROP TABLE IF EXISTS TCM;
DROP TABLE IF EXISTS RN;

-- Tablas sin dependencias externas
DROP TABLE IF EXISTS Administrador;
DROP TABLE IF EXISTS TH;
DROP TABLE IF EXISTS MIT;
DROP TABLE IF EXISTS TipoDI;
DROP TABLE IF EXISTS TipoMovimiento;
DROP TABLE IF EXISTS TipoMI;
DROP TABLE IF EXISTS TipoMIM;
DROP TABLE IF EXISTS TipoRN;
DROP TABLE IF EXISTS TipoTCM;

-- Tablas para manejo de errores
DROP TABLE IF EXISTS DBError;
DROP TABLE IF EXISTS Error;

-- Otros
DROP PROCEDURE IF EXISTS [dbo].[SP_ReposicionLoteTarjetaFisica]
DROP PROCEDURE IF EXISTS [dbo].[SP_InsertarLoteMovimientos]
DROP PROCEDURE IF EXISTS [dbo].[SP_InsertarMovimiento]
DROP PROCEDURE IF EXISTS [dbo].[SP_InsertarMovimientoSospechoso]
DROP TYPE IF EXISTS dbo.MovimientoVariable;
DROP TYPE IF EXISTS dbo.TFReposicionVariable;
DROP TYPE IF EXISTS dbo.MovimientoTemporal;





-- Tabla de tipos de tarjeta cuenta maestra
CREATE TABLE TipoTCM ( 
    id INT IDENTITY PRIMARY KEY
    , Nombre NVARCHAR(50)
);

-- Tabla de tipos de regla de negocio
CREATE TABLE TipoRN (
    id INT PRIMARY KEY IDENTITY(1,1)
    , Nombre NVARCHAR(100)
    , TipoDato NVARCHAR(50)
);

-- Tabla de tipos de documento de identidad  --------------------
CREATE TABLE TipoDI (
    id INT PRIMARY KEY IDENTITY(1,1)
    , Nombre NVARCHAR(100)
    , Formato NVARCHAR(75)
);

-- Cargado temporal a TipoDI, dado que no viene en el XML
INSERT INTO TipoDI VALUES ('Cedula', '1-2345-6789');
------------------------------------------------------------------

-- Tabla de tipos de movimientos
CREATE TABLE TipoMovimiento (
    id INT PRIMARY KEY IDENTITY(1,1)
    , Nombre NVARCHAR(100)
    , Accion NVARCHAR(100)
    , OperacionATM VARCHAR(3)
    , OperacionVentanilla VARCHAR(3)
);

-- Tabla de credenciales de administradores
CREATE TABLE Administrador (
    id INT PRIMARY KEY IDENTITY(1,1)
    , Usuario NVARCHAR(100)
    , Contraseña NVARCHAR(100)
);

-- Tabla de reglas de negocio
CREATE TABLE RN (
    id INT PRIMARY KEY IDENTITY(1,1)
	, Nombre NVARCHAR(300)
    , idTipoTCM INT FOREIGN KEY REFERENCES TipoTCM(id)
    , idTipoRN INT FOREIGN KEY REFERENCES TipoRn(id)
    , Valor NVARCHAR(100)
);

-- Tabla de tarjeta habientes
CREATE TABLE TH (
    id INT PRIMARY KEY IDENTITY(1,1)
    , idTipoDI INT FOREIGN KEY REFERENCES TipoDI(id)
    , ValorDI NVARCHAR(100)
    , Nombre NVARCHAR(300)
    , FechaNacimiento DATE
    , Usuario NVARCHAR(100)
    , Contraseña NVARCHAR(100)
);

-- Tabla de motivos de invalidación de tarjetas
CREATE TABLE MIT (
    id INT PRIMARY KEY IDENTITY(1,1)
    , Nombre NVARCHAR(75)
);

-- Tabla de tipo de movimientos de intereses
CREATE TABLE TipoMI (
    id INT PRIMARY KEY IDENTITY(1,1)
    , Nombre NVARCHAR(75)
);

-- Tabla de tipo de movimientos de intereses moratorios
CREATE TABLE TipoMIM (
    id INT PRIMARY KEY IDENTITY(1,1)
    , Nombre NVARCHAR(75)
);

-- Tabla de tarjetas de cuenta maestra
CREATE TABLE TCM (
    id INT PRIMARY KEY IDENTITY(1,1)
    , Codigo VARCHAR(50)
    , SaldoActual MONEY DEFAULT 0
    , LimiteCredito MONEY
    , idTipoTCM INT FOREIGN KEY REFERENCES TipoTCM(id)
    , idTH INT FOREIGN KEY REFERENCES TH(id)
);

-- Tabla de tarjetas adicionales
CREATE TABLE TCA (
    id INT PRIMARY KEY IDENTITY(1,1)
    , idTH INT FOREIGN KEY REFERENCES TH(id)
    , idTCM INT FOREIGN KEY REFERENCES TCM(id)
    , CodigoTCA VARCHAR(50)
);

-- Tabla de cuentas de tarjeta (TCM y TCA)
CREATE TABLE TC (
    id INT PRIMARY KEY IDENTITY(1,1)
    , idTCM INT NULL FOREIGN KEY REFERENCES TCM(id)
    , idTCA INT NULL FOREIGN KEY REFERENCES TCA(id)
);

-- Tabla de tarjetas físicas
CREATE TABLE TF (
    id INT PRIMARY KEY IDENTITY(1,1)
    , idTC INT FOREIGN KEY REFERENCES TC(id)
    , Codigo VARCHAR(16)
    , CCV VARCHAR(25)
    , FechaCreacion DATETIME
    , FechaVencimiento VARCHAR(7)
    , Activa VARCHAR(3) DEFAULT 'SI'
);

-- Tabla de movimientos respecto a intereses
CREATE TABLE MI (
    id INT PRIMARY KEY IDENTITY(1,1)
    , idTCM INT FOREIGN KEY REFERENCES TCM(id)
    , idTipoMI INT FOREIGN KEY REFERENCES TipoMI(id)
    , SaldoIntereses MONEY
    , Fecha DATE
);

-- Tabla de movimientos intereses moratorios
CREATE TABLE MIM(
    id INT PRIMARY KEY IDENTITY(1,1)
    , idTCM INT FOREIGN KEY REFERENCES TCM(id)
    , idTipoMIM INT FOREIGN KEY REFERENCES TipoMIM(id)
    , SaldoInteresesMoratorios MONEY
    , Fecha DATE
);

-- Tabla de movimientos
CREATE TABLE Movimientos (
    id INT PRIMARY KEY IDENTITY(1,1)
    , idTF INT FOREIGN KEY REFERENCES TF(id)
    , idTipoMovimiento INT FOREIGN KEY REFERENCES TipoMovimiento(id)
    , Monto MONEY
    , NuevoSaldo Money
    , Descripcion NVARCHAR(300)
    , Fecha DATETIME
    , Referencia NVARCHAR(300)
    , Procesado BIT DEFAULT 0
);

-- Tabla de movimientos sospechosos
CREATE TABLE MovimientosSospechosos (
    id INT PRIMARY KEY IDENTITY(1,1)
    , idTF INT FOREIGN KEY REFERENCES TF(id)
    , idTipoMovimiento INT FOREIGN KEY REFERENCES TipoMovimiento(id)
    , Monto MONEY
    , NuevoSaldo MONEY
    , Descripcion NVARCHAR(300)
    , Fecha DATETIME
    , Referencia NVARCHAR(300)
    , Procesado BIT DEFAULT 0
);

-- Tabla variable
GO
CREATE TYPE dbo.MovimientoVariable AS TABLE (
    FechaOperacion DATETIME,
    Nombre VARCHAR(100),
    TF VARCHAR(100),
    FechaMovimiento DATETIME,
    Monto DECIMAL(28,8),
    Descripcion VARCHAR(200),
    Referencia VARCHAR(100),
	Procesado BIT DEFAULT 0,
	NuevoSaldo MONEY
);

GO
CREATE TYPE dbo.TFReposicionVariable AS TABLE (
    FechaOperacion DATETIME,
    Razon VARCHAR(100),
    TF VARCHAR(100)
);

GO
CREATE TYPE dbo.MovimientoTemporal AS TABLE (
	idTF INT,
    idTipoMovimiento INT,
    Monto MONEY,
    Descripcion NVARCHAR(300),
    Fecha DATETIME,
    Referencia NVARCHAR(300),
    Procesado BIT,
    NuevoSaldo MONEY
);


-- Tabla de estados de cuenta
GO
CREATE TABLE EstadoCuenta (
    id INT PRIMARY KEY IDENTITY(1,1)
    , idTCM INT FOREIGN KEY REFERENCES TCM(id)
    , FechaCreacion DATE
    , FechaCorte DATE
    , SaldoAlCorte MONEY
    , PagoMinimoMesAnterior MONEY
    , FechaLimitePago DATE
    , InteresesAlCorte MONEY
    , InteresesMoratoriosAlCorte MONEY
    , OperacionesATM INT
    , OperacionesVentanilla INT
    , SumaPagosAntesFechaLimitePago MONEY
    , SumaPagosDuranteMes MONEY
    , CantidadPagos INT
    , SumaCompras MONEY
    , CantidadCompras INT
    , SumaRetiros MONEY
    , CantidadRetiros INT
    , SumaCreditos MONEY
    , CantidadCreditos INT
    , SumaDebitos MONEY
    , CantidadDebitos INT
);

-- Tabla para los sub-estados de cuenta
CREATE TABLE SubEstadoCuenta (
    id INT PRIMARY KEY IDENTITY(1,1)
    , idTCA INT FOREIGN KEY REFERENCES TCA(id)
    , FechaCreacion DATE
    , FechaCorte DATE
    , OperacionesATM INT
    , OperacionesVentanilla INT
    , SumaCompras MONEY
    , CantidadCompras INT
    , SumaRetiros MONEY
    , CantidadRetiros INT
    , SumaCreditos MONEY
    , SumaDebitos MONEY
);

-- Tabla que almacena los errores en la base de datos
CREATE TABLE DBError (
    id INT PRIMARY KEY IDENTITY(1,1)
    , UserName NVARCHAR(100)
    , [Number] INT
    , [State] INT
    , [Severity] INT
    , [Line] INT
    , [Procedure] NVARCHAR(100)
    , [Message] NVARCHAR(255)
    , [DateTime] DATETIME NOT NULL
);

-- Tabla con los errores definidos previamente y sus valores insertados
CREATE TABLE Error ( -------------------------------------------------------------
    id INT PRIMARY KEY IDENTITY(1,1)
    , Codigo INT NOT NULL
    , Descripcion NVARCHAR(255)
);

INSERT INTO Error VALUES
	  (50008, 'Error en base datos.')
	, (50009, 'El documento de identidad ya se encuentra registrado.')
	, (50010, 'El TH no se ha encontrado.')
	, (50011, 'El Tipo de TCM no se ha encontrado.')
	, (50012, 'Ya existe TCM registrada con ese codigo.')
	, (50013, 'Ya existe TCA registrada con ese codigo.')
	, (50014, 'No se encontro TC asociada.')
	, (50015, 'No se ingreso TF, ya existe ese codigo.')
	, (50016, 'No se encontro TipoMovimiento con ese nombre.')
	, (50017, 'Fecha de creacion de TF no se encontro.')
	, (50018, 'Fecha de vencimiento de TF no se encontro.')
	, (50019, 'Id de TF no se encontro.')
	, (50020, 'No existe TCM a la que asociar la TCA.')
	, (50021, 'No existe la TF buscada o esta inactiva.')

------------------------------------------------------------------------------------