-- Universidad Técnica Nacional
-- Aplicación de Bases de Datos
-- Creación de Base de datos...
-- Utilice las siguientes instrucciones para crear la base de datos, llaves primarias, 
-- llaves foráneas e inserciones.
-- Recuerde....Se tiene que crear un folder en la unidad C: con el nombre de DB.

CREATE DATABASE [PracticaExamen] 
GO

Use PracticaExamen

-------------------------------------------------------------
--Creación de Tablas
-------------------------------------------------------------

Create Table Cliente
(
ID int not null,
Nombre varchar(20),
Direccion varchar(200),
TotalVenta Float null,
PorcDescuento float null
)

Create table EncFactura
(
ID int not null,
IDCliente int not null,
Impuesto float not null,
Descuento float not null,
Monto float not null
)

Create Table Producto 
(
ID int not null,
Nombre varchar(200),
Precio money,
Reorden int
)

Create table DetFactura
(
IDEncFactura int not null,
IDProducto int not null,
Cantidad int not null,
Precio int not null,
Descuento float not null
)

Create table CXC
(
IDEncFactura int not null,
IDCliente int,
Vencimiento smalldatetime,
Monto Float,
Saldo Float
)


-------------------------------------------------------------
-- Modificación de tablas - Llaves Primarias (PK)
-------------------------------------------------------------

ALTER TABLE cliente ADD CONSTRAINT pk_IDcliente PRIMARY KEY (ID)
ALTER TABLE EncFactura ADD CONSTRAINT pk_IDEncFactura PRIMARY KEY (ID)
ALTER TABLE producto ADD CONSTRAINT pk_IDProducto PRIMARY KEY (ID)
ALTER TABLE DetFactura ADD CONSTRAINT pk_IDDetFacturaIDProducto PRIMARY KEY (IDEncFactura, IDProducto)
ALTER TABLE CXC ADD CONSTRAINT pk_CXC PRIMARY KEY (IDEncFactura)


-------------------------------------------------------------
-- Modificación de tablas - Llaves Foráneas (FK)
-------------------------------------------------------------

ALTER TABLE EncFactura ADD CONSTRAINT FK_ClienteEncFactura FOREIGN KEY (IDCliente) REFERENCES Cliente(ID)
ALTER TABLE DetFactura ADD CONSTRAINT FK_EncFaturaDetFactura FOREIGN KEY (IDEncFactura) REFERENCES EncFactura(ID)
ALTER TABLE DetFactura ADD CONSTRAINT FK_ProductoDetFactura FOREIGN KEY (IDProducto) REFERENCES Producto(ID)
ALTER TABLE CXC ADD CONSTRAINT FK_ClienteCXC FOREIGN KEY (IDCliente) REFERENCES Cliente(ID)

 
-------------------------------------------------------------
-- Inserción de datos en las tablas - Insert
-------------------------------------------------------------

insert into Cliente values (1,'Cliente #1','Dirección #1',10,10);
insert into Cliente values (2,'Cliente #2','Dirección #2',11,11);
insert into Cliente values (3,'Cliente #3','Dirección #3',12,12);
insert into Cliente values (4,'Cliente #4','Dirección #4',13,13);
insert into Cliente values (5,'Cliente #5','Dirección #5',14,14);
insert into Cliente values (6,'Cliente #6','Dirección #6',15,15);
insert into Cliente values (7,'Cliente #7','Dirección #7',16,16);
insert into Cliente values (8,'Cliente #8','Dirección #8',17,17);
insert into Cliente values (9,'Cliente #9','Dirección #9',18,18);

insert into Producto values (1,'Producto #1',2000,30);
insert into Producto values (2,'Producto #2',3000,40);
insert into Producto values (3,'Producto #3',4000,50);
insert into Producto values (4,'Producto #4',5000,60);
insert into Producto values (5,'Producto #5',3000,100);
insert into Producto values (6,'Producto #6',4000,100);
insert into Producto values (7,'Producto #7',5000,100);

insert into EncFactura values (1,1,100,10,190);
insert into EncFactura values (2,2,200,20,1280);
insert into EncFactura values (3,3,300,30,1270);
insert into EncFactura values (4,4,400,40,1360);
insert into EncFactura values (5,5,500,50,1450);
insert into EncFactura values (6,6,600,60,5140);
insert into EncFactura values (7,7,700,70,1630);
insert into EncFactura values (8,8,800,80,1720);
insert into EncFactura values (9,1,900,90,1810);

insert into DetFactura values (1,1,1,100,10);
insert into DetFactura values (1,2,2,200,20);
insert into DetFactura values (1,3,3,300,30);
insert into DetFactura values (1,4,4,400,40);
insert into DetFactura values (1,5,5,500,50);
insert into DetFactura values (1,6,6,600,60);
insert into DetFactura values (1,7,7,700,70);

insert into DetFactura values (2,1,10,1000,100);
insert into DetFactura values (2,2,20,2000,200);
insert into DetFactura values (2,3,30,3000,300);
insert into DetFactura values (2,4,40,4000,400);
insert into DetFactura values (2,5,50,5000,500);
insert into DetFactura values (2,6,60,6000,600);
insert into DetFactura values (2,7,70,7000,700);

insert into DetFactura values (3,1,15,1500,150);
insert into DetFactura values (3,2,25,2500,250);
insert into DetFactura values (3,3,35,3500,350);
insert into DetFactura values (3,4,45,4500,450);
insert into DetFactura values (3,5,55,5500,550);
insert into DetFactura values (3,6,65,6500,650);
insert into DetFactura values (3,7,75,7500,750);

insert into DetFactura values (4,1,16,1600,160);
insert into DetFactura values (4,2,26,2600,260);
insert into DetFactura values (4,3,36,3600,360);
insert into DetFactura values (4,4,46,4600,460);
insert into DetFactura values (4,5,56,5600,560);
insert into DetFactura values (4,6,66,6600,660);
insert into DetFactura values (4,7,76,7600,760);

insert into DetFactura values (5,1,17,1700,170);
insert into DetFactura values (5,2,27,2700,270);
insert into DetFactura values (5,3,37,3700,370);
insert into DetFactura values (5,4,47,4700,470);
insert into DetFactura values (5,5,57,5700,570);
insert into DetFactura values (5,6,67,6700,670);
insert into DetFactura values (5,7,77,7700,770);

insert into CXC values (1,1,Getdate()-5,7700,770);
insert into CXC values (2,2,Getdate()-4,7700,770);
insert into CXC values (3,3,Getdate()-3,7700,770);
insert into CXC values (4,4,Getdate()-2,7700,770);
insert into CXC values (5,5,Getdate()-1,7700,770);
insert into CXC values (6,6,Getdate()+1,7700,770);
insert into CXC values (7,7,Getdate()+2,7700,770);
insert into CXC values (8,8,Getdate()+3,7700,770);
insert into CXC values (9,9,Getdate()+4,7700,770);



-------------------------------------------------------------
-- Ejercicios a Resolver.
-------------------------------------------------------------

-- Lea detalladamente y cuidadosamente el planteamiento de los ejercicios
-- y cualquier consulta hágasela saber al profesor para que esta sea aclarada. 

--.............................................................
-- 1. Ejercicio #1 
/*Diseñe un procedimiento almacenado llamado SPReordenProducto.
Este procedimiento debe recibir como parámetro de entrada el códio de un
producto y un número.  Si el producto existe debe reemplazar el valor del
campo reorden por el número que se recibe*/

-- Aquí la solución del Ejercicio.

CREATE PROCEDURE SPReordenProducto
    @IDProducto INT,
    @NuevoReorden INT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Producto WHERE ID = @IDProducto)
    BEGIN
        UPDATE Producto
        SET Reorden = @NuevoReorden
        WHERE ID = @IDProducto

        PRINT 'Reorden actualizado exitosamente para el producto ID: ' + CAST(@IDProducto AS VARCHAR)
    END
    ELSE
    BEGIN
        PRINT 'El producto con ID ' + CAST(@IDProducto AS VARCHAR) + ' no existe.'
    END
END
GO

--ejemplo   
EXEC SPReordenProducto 1, 75
EXEC SPReordenProducto 99, 50
 
 --verificacion
SELECT ID, Nombre, Reorden FROM Producto WHERE ID = 1
--......................................................

--  2. Ejercicio #2
/*Diseñe un procedimiento almacenado llamado SPControlCuenta
Esta función debe recibir como parámetro de entrada un número de factura
Debe comparar el monto de dicha factura con el monto de la cuenta por cobrar
que tiene el mismo número.  Si ambos montos son diferentes, entonces debe
actualizar el monto de la cuenta al monto de la factura*/

--  Aquí la solución del Ejercicio..

CREATE PROCEDURE SPControlCuenta
    @IDEncFactura INT
AS
BEGIN
    DECLARE @MontoFactura FLOAT
    DECLARE @MontoCXC FLOAT

    --  Se verifica si la factura existe
    IF EXISTS (SELECT 1 FROM EncFactura WHERE ID = @IDEncFactura)
    BEGIN
        -- Se obtiene el monto de la factura
        SELECT @MontoFactura = Monto
        FROM EncFactura
        WHERE ID = @IDEncFactura

        -- Se verifica si existe la cuenta por cobrar con ese número
        IF EXISTS (SELECT 1 FROM CXC WHERE IDEncFactura = @IDEncFactura)
        BEGIN
            -- Se obtiene el monto de la cuenta por cobrar
            SELECT @MontoCXC = Monto
            FROM CXC
            WHERE IDEncFactura = @IDEncFactura

            -- se comparan ambos montos
            IF @MontoFactura <> @MontoCXC
            BEGIN
                -- Se actualiza el monto de CXC al monto de la factura
                UPDATE CXC
                SET Monto = @MontoFactura
                WHERE IDEncFactura = @IDEncFactura

                PRINT 'Monto actualizado: CXC ajustada de ' + CAST(@MontoCXC AS VARCHAR) + 
                      ' a ' + CAST(@MontoFactura AS VARCHAR)
            END
            ELSE
            BEGIN
                PRINT 'Los montos son iguales. No se realizó ningún cambio.'
            END
        END
        ELSE
        BEGIN
            PRINT 'No existe una cuenta por cobrar para la factura ID: ' + CAST(@IDEncFactura AS VARCHAR)
        END
    END
    ELSE
    BEGIN
        PRINT 'La factura con ID ' + CAST(@IDEncFactura AS VARCHAR) + ' no existe.'
    END
END
GO

--ejemplo
EXEC SPControlCuenta 1
SELECT IDEncFactura, Monto FROM CXC WHERE IDEncFactura = 1
EXEC SPControlCuenta 1

--......................................................

--  3. Ejercicio #3
/*Diseñe una función llamada fCuentasVencidas.
Esta función no recibe parámetros y  debe retornar la cantidad de cuentas por cobrar
que están vencidas a la fecha de hoy*/

--  Aquí la solución del Ejercicio.

CREATE FUNCTION fCuentasVencidas()
RETURNS INT
AS
BEGIN
    DECLARE @CantidadVencidas INT

    -- Contar las cuentas cuyo vencimiento es anterior a la fecha de hoy
    SELECT @CantidadVencidas = COUNT(*)
    FROM CXC
    WHERE Vencimiento < GETDATE()

    RETURN @CantidadVencidas
END
GO

--ejemplo
SELECT dbo.fCuentasVencidas() AS CuentasVencidas

--.........................................................
--  4. Ejercicio #4
/*Diseñe una función llamada fControlCliente.
Esta función recibe como parámetro el código de un cliente
y retorna el total que tiene dicho cliente en cuentas por cobrar.*/

--  Aquí la solución del Ejercicio.

CREATE FUNCTION fControlCliente(@IDCliente INT)
RETURNS FLOAT
AS
BEGIN
    DECLARE @TotalCXC FLOAT

    -- Sumar todos los montos de CXC para el cliente indicado
    SELECT @TotalCXC = SUM(Monto)
    FROM CXC
    WHERE IDCliente = @IDCliente

    -- Si el cliente no tiene cuentas, retornar 0
    IF @TotalCXC IS NULL
        SET @TotalCXC = 0

    RETURN @TotalCXC
END
GO

--ejemplo 
SELECT dbo.fControlCliente(1) AS TotalCuentasPorCobrar

SELECT dbo.fControlCliente(5) AS TotalCuentasPorCobrar

SELECT dbo.fControlCliente(99) AS TotalCuentasPorCobrar


--........................................................
--5.Ejercicio #5
/*Diseñe un trigger llamado TRControlaVenta.
Cuando se realiza un insert en la tabla EncFactura, este trigger
modifica el campo TotalVenta en la tabla Cliente de manera que 
le sume al total de ventas el monto de la nueva factura
a dicho cliente*/

--  Aquí la solución del Ejercicio.

CREATE TRIGGER TRControlaVenta
ON EncFactura
AFTER INSERT
AS
BEGIN
    -- Actualizar el TotalVenta del cliente sumando el monto de la nueva factura
    UPDATE Cliente
    SET TotalVenta = TotalVenta + inserted.Monto
    FROM Cliente
    INNER JOIN inserted ON Cliente.ID = inserted.IDCliente
END
GO

--ejemplo
SELECT ID, Nombre, TotalVenta FROM Cliente WHERE ID = 1

INSERT INTO EncFactura VALUES (10, 1, 100, 10, 5000)

SELECT ID, Nombre, TotalVenta FROM Cliente WHERE ID = 1

--........................................................
--6.Ejercicio #6
/*Diseñe un trigger llamado TRDescuento.
Este trigger se dispara al realizar un insert en la tabla cliente.
Si el monto es diferente de cero y el descuento es diferente de 0.10
No debe permitir que se realice la operación.*/

--Aquí la solución del Ejercicio

CREATE TRIGGER TRDescuento
ON Cliente
INSTEAD OF INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM inserted
        WHERE TotalVenta <> 0 AND PorcDescuento <> 0.10
    )
    BEGIN
        PRINT 'Operación no permitida: el monto es diferente de cero y el descuento es diferente de 0.10'
    END
    ELSE
    BEGIN
        INSERT INTO Cliente (ID, Nombre, Direccion, TotalVenta, PorcDescuento)
        SELECT ID, Nombre, Direccion, TotalVenta, PorcDescuento
        FROM inserted
    END
END
GO

--ejemplo 
INSERT INTO Cliente VALUES (10, 'Cliente #10', 'Dirección #10', 500, 0.20)

INSERT INTO Cliente VALUES (11, 'Cliente #11', 'Dirección #11', 0, 0.20)

INSERT INTO Cliente VALUES (12, 'Cliente #12', 'Dirección #12', 500, 0.10)

INSERT INTO Cliente VALUES (13, 'Cliente #13', 'Dirección #13', 0, 0.10)

--........................................................
--7.Ejercicio #7
/*Diseñe una vista llamada InfoCobro.
Esta vista debe contener la siguiente información
Nombre del cliente, Dirección del Cliente, Número de Cuenta por cobrar,
Monto de la cuenta y Saldo Pendiente.*/

CREATE VIEW InfoCobro
AS
    SELECT 
        C.Nombre        AS NombreCliente,
        C.Direccion     AS DireccionCliente,
        CXC.IDEncFactura AS NumeroCuenta,
        CXC.Monto       AS MontoCuenta,
        CXC.Saldo       AS SaldoPendiente
    FROM CXC
    INNER JOIN Cliente C ON CXC.IDCliente = C.ID
GO

--ejemplo 
SELECT * FROM InfoCobro

SELECT * FROM InfoCobro WHERE NombreCliente = 'Cliente #1'

SELECT * FROM InfoCobro WHERE SaldoPendiente > 500


