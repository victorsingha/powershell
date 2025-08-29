$from_connectionString = 'Data source=SERVER_IP;Database=DB_NAME;Uid=USERNAME;Pwd=PASSWORD;Pooling=true;Min Pool Size=2;Max Pool Size=1000;MultipleActiveResultSets=true;'
$to_connectionString = 'Data source=SERVER_IP;Database=DB_NAME;Uid=USERNAME;Pwd=PASSWORD;Pooling=true;Min Pool Size=2;Max Pool Size=1000;MultipleActiveResultSets=true;'

$sqlQuery = @"
    SELECT TABLE_NAME AS TableName
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE = 'BASE TABLE'
    and TABLE_SCHEMA='dbo'
    and TABLE_NAME not like '%2024%'
    and TABLE_NAME not like '%2025%'
    and TABLE_NAME not like '%Backup%'
    ORDER BY TABLE_SCHEMA, TABLE_NAME
"@

$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = $from_connectionString
$connection.Open()
$command = $connection.CreateCommand()
$command.CommandText = $sqlQuery
$reader = $command.ExecuteReader()
$tables = @()
while ($reader.Read()) {
    $tables += $reader["TableName"]
}
$connection.Close()

foreach ($table in $tables) {

$sqlQuery = @"

    DECLARE @TypeName SYSNAME = N'$table'
    DECLARE @SchemaName SYSNAME = (SELECT SCHEMA_NAME(schema_id)FROM sys.tables WHERE name = @TypeName);

    DECLARE @SQL NVARCHAR(MAX) = '',@CRLF CHAR(2) = CHAR(13) + CHAR(10)

    SELECT @SQL = 'CREATE TABLE [' + @SchemaName + '].[' + @TypeName + '] (' + @CRLF

    SELECT @SQL = @SQL + '    [' + c.name + '] ' +
        t.name +
        CASE 
            WHEN t.name IN ('varchar', 'char', 'varbinary', 'binary', 'nvarchar', 'nchar') 
                THEN '(' + 
                     CASE 
                         WHEN c.max_length = -1 THEN 'MAX'
                         WHEN t.name IN ('nchar', 'nvarchar') THEN CAST(c.max_length / 2 AS VARCHAR)
                         ELSE CAST(c.max_length AS VARCHAR)
                     END + ')'
            WHEN t.name IN ('decimal', 'numeric') 
                THEN '(' + CAST(c.precision AS VARCHAR) + ',' + CAST(c.scale AS VARCHAR) + ')'
            ELSE ''
        END + 
        CASE 
            WHEN dc.definition IS NOT NULL THEN ' DEFAULT ' + dc.definition 
            ELSE ''
        END + 
        CASE 
            WHEN c.is_nullable = 0 THEN ' NOT NULL' 
            ELSE ' NULL' 
        END + ',' + @CRLF
    FROM sys.columns c
    JOIN sys.types t ON c.user_type_id = t.user_type_id
    JOIN sys.tables tbl ON c.object_id = tbl.object_id
    JOIN sys.schemas s ON tbl.schema_id = s.schema_id
    LEFT JOIN sys.default_constraints dc ON c.default_object_id = dc.object_id
    WHERE tbl.name = @TypeName AND s.name = @SchemaName
    ORDER BY c.column_id

    -- Remove last comma
    SET @SQL = LEFT(@SQL, LEN(@SQL) - 2) + @CRLF + ')'

    SELECT @SQL SQL

"@


    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $from_connectionString
    $connection.Open()
    $command = $connection.CreateCommand()
    $command.CommandText = $sqlQuery
    $result1 = $command.ExecuteScalar()
    $connection.Close()

    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $to_connectionString
    $connection.Open()
    $command = $connection.CreateCommand()
    $command.CommandText = $sqlQuery
    $result2 = $command.ExecuteScalar()
    $connection.Close()

    if ($result1 -ne $result2) {
      #MODIFIED
      Write-Host "🧱🧱🧱🧱🧱 $table"
    }
    else {

    }

    
    
}
