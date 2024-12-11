-- Creación de base de datos
CREATE DATABASE transacciones_empresas;
USE transacciones_empresas;

-- Tabla de Empresas
CREATE TABLE empresas (
    id_empresa INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    sector VARCHAR(50) NOT NULL,
    direccion VARCHAR(200),
    telefono VARCHAR(20),
    email VARCHAR(100)
);

-- Tabla de Cuentas Bancarias
CREATE TABLE cuentas_bancarias (
    id_cuenta INT AUTO_INCREMENT PRIMARY KEY,
    id_empresa INT,
    numero_cuenta VARCHAR(50) NOT NULL,
    banco VARCHAR(100) NOT NULL,
    saldo DECIMAL(15,2) NOT NULL DEFAULT 0,
    FOREIGN KEY (id_empresa) REFERENCES empresas(id_empresa)
);

-- Tabla de Transacciones
CREATE TABLE transacciones (
    id_transaccion INT AUTO_INCREMENT PRIMARY KEY,
    id_cuenta_origen INT,
    id_cuenta_destino INT,
    monto DECIMAL(15,2) NOT NULL,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    tipo ENUM('transferencia', 'pago', 'cobro') NOT NULL,
    descripcion TEXT,
    FOREIGN KEY (id_cuenta_origen) REFERENCES cuentas_bancarias(id_cuenta),
    FOREIGN KEY (id_cuenta_destino) REFERENCES cuentas_bancarias(id_cuenta)
);

-- Procedimiento almacenado para realizar transferencia con transacción
DELIMITER //
CREATE PROCEDURE transferir_fondos(
    IN p_id_cuenta_origen INT,
    IN p_id_cuenta_destino INT,
    IN p_monto DECIMAL(15,2),
    IN p_descripcion TEXT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Verificar saldo suficiente
    IF (SELECT saldo FROM cuentas_bancarias WHERE id_cuenta = p_id_cuenta_origen) < p_monto THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Saldo insuficiente';
    END IF;

    -- Restar de cuenta origen
    UPDATE cuentas_bancarias 
    SET saldo = saldo - p_monto 
    WHERE id_cuenta = p_id_cuenta_origen;

    -- Sumar a cuenta destino
    UPDATE cuentas_bancarias 
    SET saldo = saldo + p_monto 
    WHERE id_cuenta = p_id_cuenta_destino;

    -- Registrar transacción
    INSERT INTO transacciones (
        id_cuenta_origen, 
        id_cuenta_destino, 
        monto, 
        tipo, 
        descripcion
    ) VALUES (
        p_id_cuenta_origen,
        p_id_cuenta_destino,
        p_monto,
        'transferencia',
        p_descripcion
    );

    COMMIT;
END //
DELIMITER ;

-- Ejemplo de inserción de datos
INSERT INTO empresas (nombre, sector, direccion, telefono, email) VALUES 
('Tecnología Innovadora SA', 'Tecnología', 'Av. Siempre Viva 123', '555-1234', 'contacto@tecnoinnovadora.com'),
('Servicios Globales SRL', 'Servicios', 'Calle Principal 456', '555-5678', 'info@serviciosglobales.com');

INSERT INTO cuentas_bancarias (id_empresa, numero_cuenta, banco, saldo) VALUES 
(1, '1234-5678-9012', 'Banco Nacional', 50000.00),
(2, '9876-5432-1098', 'Banco Internacional', 75000.00);

-- Ejemplo de uso del procedimiento de transferencia
CALL transferir_fondos(1, 2, 10000.00, 'Pago por servicios de consultoría');

-- Consulta para verificar transacciones
SELECT 
    t.id_transaccion,
    e_origen.nombre AS empresa_origen,
    e_destino.nombre AS empresa_destino,
    t.monto,
    t.fecha,
    t.descripcion
FROM 
    transacciones t
JOIN 
    cuentas_bancarias cb_origen ON t.id_cuenta_origen = cb_origen.id_cuenta
JOIN 
    cuentas_bancarias cb_destino ON t.id_cuenta_destino = cb_destino.id_cuenta
JOIN 
    empresas e_origen ON cb_origen.id_empresa = e_origen.id_empresa
JOIN 
    empresas e_destino ON cb_destino.id_empresa = e_destino.id_empresa;
