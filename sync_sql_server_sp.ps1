
$from_connectionString = 'Data source=SERVER_IP;Database=DB_NAME;Uid=USERNAME;Pwd=PASSWORD;Pooling=true;Min Pool Size=2;Max Pool Size=1000;MultipleActiveResultSets=true;'
$to_connectionString = 'Data source=SERVER_IP;Database=DB_NAME;Uid=USERNAME;Pwd=PASSWORD;Pooling=true;Min Pool Size=2;Max Pool Size=1000;MultipleActiveResultSets=true;'

$storedProceduresAndFunctions = @(
'SP_TEST1',
'SP_TEST2',
'SP_TEST3',
)


$dateStr = Get-Date -Format "yyyy-MM-dd"
$folderPath = "E:\BACKUP_SPs\$dateStr\"


foreach ($sp in $storedProceduresAndFunctions) {
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
  $spDefinition = $result2


  if ([string]::IsNullOrWhiteSpace($result0)) {

    $targetConnection = New-Object System.Data.SqlClient.SqlConnection($to_connectionString)
    $targetConnection.Open()
    $targetCommand = $targetConnection.CreateCommand()
    $targetCommand.CommandText = $spDefinition
    $result3 = $targetCommand.ExecuteNonQuery()
    $targetConnection.Close()

    Write-Host "💹💹💹💹💹 $sp Created."
        
  }
  else {

    $targetConnection = New-Object System.Data.SqlClient.SqlConnection($to_connectionString)
    $targetConnection.Open()
    $targetCommand = $targetConnection.CreateCommand()
    $targetCommand.CommandText = $query
    $result1 = $targetCommand.ExecuteScalar()
    $targetConnection.Close()

    if ($result1 -ne $result2) {

      if (-not (Test-Path $folderPath)) {
        New-Item -ItemType Directory -Path $folderPath | Out-Null
      }
      $timestamp = Get-Date -Format "yyyy_MM_dd_HH_mm_ss"
      $result1 | Out-File -FilePath "$folderPath$($sp)_$timestamp.txt" -Encoding UTF8


      $spDefinition = $spDefinition -replace 'CREATE\s+PROCEDURE', 'ALTER PROCEDURE'
      $spDefinition = $spDefinition -replace 'CREATE\s+PROC', 'ALTER PROCEDURE'
      $spDefinition = $spDefinition -replace 'CREATE\s+FUNCTION', 'ALTER FUNCTION'

      $targetConnection = New-Object System.Data.SqlClient.SqlConnection($to_connectionString)
      $targetConnection.Open()
      $targetCommand = $targetConnection.CreateCommand()
      $targetCommand.CommandText = $spDefinition
      $result3 = $targetCommand.ExecuteNonQuery()
      $targetConnection.Close()

      Write-Host "✅✅✅✅✅ $sp Altered."
    }
    else {

      Write-Host "⛔⛔⛔⛔⛔ $sp Already Synced."
    }
      
  }
}
