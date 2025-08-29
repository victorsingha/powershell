$from_connectionString = 'Data source=SERVER_IP;Database=DB_NAME;Uid=USERNAME;Pwd=PASSWORD;Pooling=true;Min Pool Size=2;Max Pool Size=1000;MultipleActiveResultSets=true;'
$to_connectionString = 'Data source=SERVER_IP;Database=DB_NAME;Uid=USERNAME;Pwd=PASSWORD;Pooling=true;Min Pool Size=2;Max Pool Size=1000;MultipleActiveResultSets=true;'

$sqlQuery = @"
    SELECT tt.name AS TableTypeName
    FROM sys.table_types tt
    WHERE tt.is_user_defined = 1
    AND tt.schema_id = SCHEMA_ID('dbo')
    AND tt.name NOT LIKE '%2024%'
    AND tt.name NOT LIKE '%2025%'
    AND tt.name NOT LIKE '%Backup%'
    ORDER BY tt.name;
"@

$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = $from_connectionString
$connection.Open()
$command = $connection.CreateCommand()
$command.CommandText = $sqlQuery
$reader = $command.ExecuteReader()
$tables = @()
while ($reader.Read()) {
    $tables += $reader["TableTypeName"]
}
$connection.Close()

foreach ($table in $tables) {

$sqlQuery = @"
    
    DECLARE @TypeName SYSNAME = N'$table'
    DECLARE @SchemaName SYSNAME = (SELECT SCHEMA_NAME(schema_id) 
                                   FROM sys.table_types WHERE name = @TypeName);

    DECLARE @SQL NVARCHAR(MAX) = '';
    SET @SQL = 'CREATE TYPE [' + @SchemaName + '].[' + N'$table' + '] AS TABLE(' + CHAR(13);

    SELECT @SQL = @SQL +
        '    [' + c.name + '] ' +
        t.name +
        CASE 
            WHEN t.name IN ('varchar', 'char', 'varbinary', 'binary', 'nvarchar', 'nchar') 
                THEN '(' + CASE WHEN c.max_length = -1 THEN 'MAX' 
                                ELSE CAST(
                                    CASE 
                                        WHEN t.name IN ('nchar', 'nvarchar') 
                                            THEN c.max_length / 2 
                                        ELSE c.max_length 
                                    END AS VARCHAR) END + ')'
            WHEN t.name IN ('decimal', 'numeric') 
                THEN '(' + CAST(c.precision AS VARCHAR) + ',' + CAST(c.scale AS VARCHAR) + ')'
            ELSE ''
        END + 
        CASE WHEN c.is_nullable = 1 THEN ' NULL' ELSE ' NOT NULL' END + ',' + CHAR(13)
    FROM sys.table_types tt
    JOIN sys.columns c ON tt.type_table_object_id = c.object_id
    JOIN sys.types t ON c.user_type_id = t.user_type_id
    WHERE tt.name = @TypeName
    ORDER BY c.column_id;

    -- Remove trailing comma and newline
    SET @SQL = LEFT(@SQL, LEN(@SQL) - 2) + CHAR(13) + ')';

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
