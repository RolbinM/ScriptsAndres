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
