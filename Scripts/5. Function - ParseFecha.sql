CREATE FUNCTION dbo.ParseFecha (@inFecha VARCHAR(25))
RETURNS DATETIME
AS
BEGIN
    DECLARE @outResult DATETIME;
    
    -- Construir la fecha como DD/MM/YYYY
    SET @outResult = CONVERT(DATETIME, '01/' + @inFecha, 103);
    
    RETURN @outResult;
END