# Skrypt: Automatyczne przetwarzanie danych klientów - PowerShell
# Autor: Teresa Holerek
# Data: 2025-01-26

# Parametry konfiguracji
$Index = "415457"
$CurrentDate = Get-Date -Format "yyyyMMdd"
$ZipUrl = "https://home.agh.edu.pl/~wsarlej/Customers_Nov2024.zip"
$OldDataUrl = "https://home.agh.edu.pl/~wsarlej/Customers_old.csv"
$DbServer = "localhost"
$DbUsername = "postgres"
$DbDatabase = "cw_10"
$MailTo = "holerek@student.agh.edu.pl"
$LogDir = "PROCESSED"
$LogFile = "$LogDir\script_log_${CurrentDate}.log"
$ProcessedPrefix = "PROCESSED_${CurrentDate}"

# Tworzenie folderu na przetworzone pliki
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir | Out-Null
}

# Funkcja logowania
function Log-Message {
    param (
        [string]$Message
    )
    $Timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    "$Timestamp - $Message" | Tee-Object -FilePath $LogFile -Append
}

# Funkcja obsługi błędów
function Handle-Error {
    param (
        [string]$ErrorMessage
    )
    Log-Message "BLAD: $ErrorMessage"
    exit 1
}

# Sprawdzenie wymaganych narzędzi
$RequiredTools = @("Invoke-WebRequest", "Expand-Archive", "psql", "Compress-Archive")
foreach ($Tool in $RequiredTools) {
    if (-not (Get-Command $Tool -ErrorAction SilentlyContinue)) {
        Handle-Error "$Tool nie jest dostepny."
    }
}

# Pobranie plików
Log-Message "Pobieranie plikow z internetu..."
try {
    Invoke-WebRequest -Uri $ZipUrl -OutFile "Customers_Nov2024.zip"
    Invoke-WebRequest -Uri $OldDataUrl -OutFile "Customers_old.csv"
} catch {
    Handle-Error "Nie udalo sie pobrac plikow."
}

# Rozpakowanie pliku ZIP
Log-Message "Rozpakowywanie pliku ZIP..."
try {
    Expand-Archive -Path "Customers_Nov2024.zip" -DestinationPath "." -Force
} catch {
    Handle-Error "Nie udalo sie rozpakowac pliku ZIP."
}

# Walidacja i deduplikacja danych
Log-Message "Walidacja i deduplikacja danych..."
$Header = (Get-Content Customers_Nov2024.csv | Select-Object -First 1)
$CleanedData = @()
Get-Content Customers_Nov2024.csv | ForEach-Object {
    if ($_ -match ",.+@.+" -and $_ -ne $Header) {
        $CleanedData += $_
    }
}
$CleanedData = $CleanedData | Sort-Object | Get-Unique
$CleanedData = @($Header) + $CleanedData
$CleanedData | Set-Content -Path "Customers_Nov2024.cleaned"

# Porównanie z wcześniejszymi danymi
Log-Message "Usuwanie duplikatow w porownaniu z plikiem poprzednim..."
$OldData = Get-Content Customers_old.csv
$FinalData = $CleanedData | Where-Object { $_ -notin $OldData }
$FinalData | Set-Content -Path "Customers_Nov2024.final"

# Tworzenie tabeli w bazie danych
Log-Message "Tworzenie tabeli w PostgreSQL..."
try {
    psql -h $DbServer -U $DbUsername -d $DbDatabase -c 'CREATE TABLE IF NOT EXISTS CUSTOMERS_' + $Index + ' (imie TEXT, nazwisko TEXT, email TEXT, lat NUMERIC, lon NUMERIC, geoloc GEOGRAPHY(POINT, 4326));'
} catch {
    Handle-Error "Nie udalo sie stworzyc tabeli."
}

# Załadowanie danych do bazy danych
Log-Message "Ladowanie danych do tabeli w PostgreSQL..."
try {
    psql -h $DbServer -U $DbUsername -d $DbDatabase -c "\copy CUSTOMERS_$Index FROM 'Customers_Nov2024.final' WITH CSV HEADER;"
} catch {
    Handle-Error "Nie udalo sie zaladowac danych."
}

# Generowanie raportu
Log-Message "Generowanie raportu..."
$TotalRows = (Get-Content Customers_Nov2024.csv).Count
$CleanedRows = $FinalData.Count
$Duplicates = $TotalRows - $CleanedRows
$Report = @(
    "Liczba wierszy w pliku: $TotalRows",
    "Liczba po walidacji: $CleanedRows",
    "Duplikaty: $Duplicates"
)
$Report | Set-Content -Path "CUSTOMERS_LOAD_${CurrentDate}.dat"

# Znalezienie najlepszych klientów
Log-Message "Wyszukiwanie najlepszych klientow..."
try {
    psql -h $DbServer -U $DbUsername -d $DbDatabase -c 'CREATE TABLE IF NOT EXISTS BEST_CUSTOMERS_' + $Index + ' AS SELECT imie, nazwisko FROM CUSTOMERS_' + $Index + ' WHERE ST_Distance(geoloc, ST_SetSRID(ST_MakePoint(-75.67329768604034, 41.39988501005976), 4326)) <= 50000;'
} catch {
    Handle-Error "Zapytanie SQL nie powiodlo sie."
}

# Eksport wyników do CSV
Log-Message "Eksportowanie najlepszych klientow do CSV..."
try {
    psql -h $DbServer -U $DbUsername -d $DbDatabase -c "\copy BEST_CUSTOMERS_$Index TO 'BEST_CUSTOMERS_$Index.csv' WITH CSV HEADER;"
} catch {
    Handle-Error "Nie udalo sie wyeksportowac danych."
}

# Kompresja pliku
Log-Message "Kompresja pliku CSV..."
try {
    Compress-Archive -Path "BEST_CUSTOMERS_$Index.csv" -DestinationPath "BEST_CUSTOMERS_$Index.zip" -Force
} catch {
    Handle-Error "Nie udalo sie skompresowac pliku."
}

# Podsumowanie
Log-Message "Skrypt zakonczony pomyslnie. Wszystkie kroki zostaly wykonane poprawnie."
