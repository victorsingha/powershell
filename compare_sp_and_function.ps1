$from_connectionString = 'Data source=SERVER_IP;Database=DB_NAME;Uid=USERNAME;Pwd=PASSWORD;Pooling=true;Min Pool Size=2;Max Pool Size=1000;MultipleActiveResultSets=true;'
$to_connectionString = 'Data source=SERVER_IP;Database=DB_NAME;Uid=USERNAME;Pwd=PASSWORD;Pooling=true;Min Pool Size=2;Max Pool Size=1000;MultipleActiveResultSets=true;'

# SQL query to fetch SPs and Functions
$sqlQuery = @"

SELECT ROUTINE_NAME AS ObjectName
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_TYPE IN ('PROCEDURE', 'FUNCTION')
And ROUTINE_NAME not like '%Backup%'
And ROUTINE_NAME not like '%_RD%'
And ROUTINE_NAME not like '%Test%'
And ROUTINE_NAME not like '%2025%'
And ROUTINE_NAME not like '%2024%'
ORDER BY ROUTINE_TYPE, ROUTINE_NAME

"@

$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = $from_connectionString
$connection.Open()
$command = $connection.CreateCommand()
$command.CommandText = $sqlQuery
$reader = $command.ExecuteReader()
$storedProceduresAndFunctions = @()
while ($reader.Read()) {
    $storedProceduresAndFunctions += $reader["ObjectName"]
}
$connection.Close()


foreach ($sp in $storedProceduresAndFunctions) {

  #Write-Host "💭💭💭💭💭 CHECKING --> $sp"   

  $query = "SELECT OBJECT_DEFINITION(OBJECT_ID('$sp'))"
  $checkQuery = "SELECT OBJECT_ID('$sp')"

  $targetConnection = New-Object System.Data.SqlClient.SqlConnection($to_connectionString)
  $targetConnection.Open()
  $targetCommand = $targetConnection.CreateCommand()
  $targetCommand.CommandText = $checkQuery
  $result0 = $targetCommand.ExecuteScalar()
  $targetConnection.Close()

  $connection = New-Object System.Data.SqlClient.SqlConnection($from_connectionString)
  $connection.Open()
  $command = $connection.CreateCommand()
  $command.CommandText = $query
  $result2 = $command.ExecuteScalar()
  $connection.Close()


  if ([string]::IsNullOrWhiteSpace($result0)) {
    #MISSING SP & FNC
    Write-Host "⚠⚠⚠⚠⚠ $sp"    
  }
  else {

    $targetConnection = New-Object System.Data.SqlClient.SqlConnection($to_connectionString)
    $targetConnection.Open()
    $targetCommand = $targetConnection.CreateCommand()
    $targetCommand.CommandText = $query
    $result1 = $targetCommand.ExecuteScalar()
    $targetConnection.Close()

    if ($result1 -ne $result2) {
      #MODIFIED SP & FNC
      Write-Host "🧱🧱🧱🧱🧱 $sp"
    }
    else {

      #Write-Host "✔✔✔✔✔ SAME --> $sp SAME"
    }
      
  }
}
