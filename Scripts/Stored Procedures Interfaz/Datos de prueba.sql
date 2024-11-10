USE BD1_TP3;

-- Insertar datos en la tabla de tarjeta habientes (TH)
INSERT INTO TH (idTipoDI, ValorDI, Nombre, FechaNacimiento, Usuario, Contraseña)
VALUES 
    (1, '1-1234-5678', 'Juan Pérez', '1990-05-15', 'jperez', 'password123'),
    (1, '1-9876-5432', 'Ana López', '1988-08-23', 'alopez', 'password456');

-- Insertar datos en la tabla de tarjetas de cuenta maestra (TCM)
INSERT INTO TCM (Codigo, SaldoActual, LimiteCredito, idTipoTCM, idTH)
VALUES 
    ('TCM001', 100000, 150000, 1, 1),
    ('TCM002', 50000, 100000, 1, 2);

-- Insertar datos en la tabla de tarjetas adicionales (TCA)
INSERT INTO TCA (idTH, idTCM, CodigoTCA)
VALUES 
    (1, 1, 'TCA001'),
    (2, 2, 'TCA002');

-- Insertar datos en la tabla de cuentas de tarjeta (TC)
INSERT INTO TC (idTCM, idTCA)
VALUES 
    (1, NULL),  -- Cuenta asociada a la tarjeta de cuenta maestra TCM001
    (NULL, 1),  -- Cuenta asociada a la tarjeta adicional TCA001
    (2, NULL),  -- Cuenta asociada a la tarjeta de cuenta maestra TCM002
    (NULL, 2);  -- Cuenta asociada a la tarjeta adicional TCA002

-- Insertar datos en la tabla de tarjetas físicas (TF)
INSERT INTO TF (idTC, Codigo, CCV, FechaCreacion, FechaVencimiento, Activa)
VALUES 
    (1, '1234567890123456', '123', '2023-01-01', '2027-01', 'SI'),
    (2, '9876543210987654', '456', '2023-02-01', '2027-02', 'SI'),
    (3, '1111222233334444', '789', '2023-03-01', '2027-03', 'SI'),
    (4, '5555666677778888', '012', '2023-04-01', '2027-04', 'SI');

-- Insertar datos en la tabla de movimientos (Movimientos)
INSERT INTO Movimientos (idTF, idTipoMovimiento, Monto, NuevoSaldo, Descripcion, Fecha, Referencia, Procesado)
VALUES 
    (1, 1, -5000, 95000, 'Pago en tienda', '2023-10-01', 'REF123', 1),
    (2, 1, 20000, 70000, 'Depósito', '2023-10-02', 'REF456', 1),
    (3, 2, -2500, 47500, 'Compra en supermercado', '2023-10-03', 'REF789', 1),
    (4, 3, -1000, 99000, 'Retiro en cajero', '2023-10-04', 'REF012', 0);

-- Insertar datos en la tabla Estad de cuenta
INSERT INTO EstadoCuenta (
    idTCM, FechaCorte, SaldoAlCorte, PagoMinimoMesAnterior, FechaLimitePago,
    InteresesAlCorte, InteresesMoratoriosAlCorte, OperacionesATM, OperacionesVentanilla,
    SumaPagosAntesFechaLimitePago, SumaPagosDuranteMes, CantidadPagos, 
    SumaCompras, CantidadCompras, SumaRetiros, CantidadRetiros, 
    SumaCreditos, CantidadCreditos, SumaDebitos, CantidadDebitos
)
VALUES 
    (1, '2023-10-31', 250000, 50000, '2023-11-05', 5000, 2000, 3, 5, 
    30000, 50000, 1, 10000, 2, 20000, 1, 15000, 1, 20000, 1),
    
    (2, '2023-10-31', 500000, 75000, '2023-11-10', 7500, 3000, 4, 3, 
    25000, 60000, 2, 30000, 1, 40000, 2, 20000, 1, 30000, 2);

-- Insertar datos de prueba en la tabla SubEstadoCuenta
INSERT INTO SubEstadoCuenta (
    idTCA, FechaCorte, OperacionesATM, OperacionesVentanilla, 
    SumaCompras, CantidadCompras, SumaRetiros, CantidadRetiros, 
    SumaCreditos, SumaDebitos
)
VALUES 
    (1, '2023-10-31', 2, 3, 15000, 1, 10000, 1, 20000, 10000),
    
    (2, '2023-10-31', 1, 2, 10000, 1, 5000, 1, 10000, 5000);
