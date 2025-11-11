@echo off
chcp 65001 > nul 2>&1
setlocal enabledelayedexpansion

rem Verificar permisos de administrador
set "IS_ADMIN=0"
net session >nul 2>&1
if %errorLevel% equ 0 (
    set "IS_ADMIN=1"
) else (
    echo.
    echo ADVERTENCIA: No se detectaron permisos de administrador
    echo Algunas funciones pueden no estar disponibles
    echo.
    timeout /t 3 >nul 2>&1
)

cls
echo ================================================================
echo            RECOPILACION DE INFORMACION DEL SISTEMA              
echo ================================================================
echo.

rem Obtener el nombre de la máquina
for /f "delims=" %%A in ('hostname') do set machine_name=%%A

rem Obtener la fecha y hora actual (compatible sin wmic)
for /f %%A in ('powershell -NoProfile -Command "Get-Date -Format \"yyyy-MM-dd_HHmmss\""') do set datetime=%%A

rem Separar fecha y hora
set current_date=%datetime:~0,10%
set current_time=%datetime:~11,6%

rem Crear carpeta de reportes si no existe (solo si NO es admin)
rem Si es admin, guardar en la carpeta actual del script
if !IS_ADMIN! equ 0 (
    if not exist "Reportes_Sistema" mkdir "Reportes_Sistema"
    set "OUTPUT_DIR=Reportes_Sistema"
) else (
    rem Obtener la ruta del directorio donde está el script
    set "OUTPUT_DIR=%~dp0"
    rem Remover la barra final si existe
    if "!OUTPUT_DIR:~-1!" == "\" set "OUTPUT_DIR=!OUTPUT_DIR:~0,-1!"
)

rem Nombre del archivo de salida con fecha y hora
if !IS_ADMIN! equ 0 (
    set output_file=!OUTPUT_DIR!\%machine_name%_%current_date%_%current_time%.txt.txt
) else (
    set output_file=!OUTPUT_DIR!\%machine_name%_%current_date%_%current_time%.txt.txt
)

echo Maquina: %machine_name%
if !IS_ADMIN! equ 1 (
    echo Modo: ADMINISTRADOR - Guardando en carpeta actual
) else (
    echo Modo: USUARIO - Guardando en Reportes_Sistema\
)
echo Archivo: %output_file%
echo Iniciando recopilacion...
echo.

rem ===== ENCABEZADO DEL REPORTE =====
echo ================================================================ > %output_file%
echo           REPORTE DE INFORMACION DEL SISTEMA            >> %output_file%
echo ================================================================ >> %output_file%
echo. >> %output_file%
echo Fecha de generacion: %current_date% %current_time% >> %output_file%
echo Maquina: %machine_name% >> %output_file%
echo Usuario: %USERNAME% >> %output_file%
echo. >> %output_file%
echo ================================================================ >> %output_file%
echo. >> %output_file%

rem Detectar versión de PowerShell
set "PS_AVAILABLE=0"
powershell -command "exit 0" >nul 2>&1
if !errorlevel! equ 0 set "PS_AVAILABLE=1"

rem ===== RESUMEN EJECUTIVO =====
echo [1/10] Generando resumen ejecutivo...
echo --- RESUMEN EJECUTIVO ----------------------------------------- >> %output_file%
if !PS_AVAILABLE! equ 1 (
    powershell -command "try { $os = Get-WmiObject Win32_OperatingSystem; $cpu = Get-WmiObject Win32_Processor | Select-Object -First 1; $ramBytes = (Get-WmiObject Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum; $ram = [math]::Round($ramBytes / 1GB, 2); $disk = Get-WmiObject Win32_LogicalDisk -Filter 'DriveType=3' | Select-Object -First 1; $gpu = Get-WmiObject Win32_VideoController | Select-Object -First 1; Write-Output ('Sistema Operativo: ' + $os.Caption + ' ' + $os.Version); Write-Output ('Procesador: ' + $cpu.Name); Write-Output ('Memoria RAM: ' + $ram + ' GB'); Write-Output ('Disco Principal: ' + [math]::Round($disk.Size / 1GB, 2) + ' GB (' + [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 2) + '%% libre)'); Write-Output ('Tarjeta Grafica: ' + $gpu.Name) } catch { Write-Output 'Error al obtener resumen' }" >> %output_file%
) else (
    echo Sistema: >> %output_file%
    systeminfo | findstr /C:"OS Name" /C:"OS Version" >> %output_file%
)
echo --------------------------------------------------------------- >> %output_file%
echo. >> %output_file%

rem ===== INFORMACIÓN DEL SISTEMA OPERATIVO =====
echo [2/10] Recopilando informacion del sistema operativo...
echo --- SISTEMA OPERATIVO ----------------------------------------- >> "%output_file%"
systeminfo | findstr /C:"OS Name" /C:"OS Version" /C:"Original Install Date" /C:"System Boot Time" /C:"System Manufacturer" /C:"System Model" /C:"System Type" /C:"BIOS Version" >> "%output_file%"
echo. >> "%output_file%"
if !PS_AVAILABLE! equ 1 (
    powershell -command "try { $os = Get-WmiObject Win32_OperatingSystem; $uptime = (Get-Date) - [Management.ManagementDateTimeConverter]::ToDateTime($os.LastBootUpTime); Write-Output ('Tiempo de actividad: ' + $uptime.Days + ' dias, ' + $uptime.Hours + ' horas, ' + $uptime.Minutes + ' minutos') } catch { Write-Output 'No disponible' }" >> "%output_file%"
)
echo --------------------------------------------------------------- >> "%output_file%"
echo. >> "%output_file%"

rem ===== INFORMACIÓN DE LA PLACA BASE =====
echo [3/10] Recopilando informacion de la placa base...
echo --- PLACA BASE ------------------------------------------------ >> "%output_file%"
if !PS_AVAILABLE! equ 1 (
    powershell -command "try { Get-WmiObject Win32_BaseBoard | ForEach-Object { Write-Output ('Fabricante: ' + $_.Manufacturer); Write-Output ('Modelo: ' + $_.Product); Write-Output ('Version: ' + $_.Version); Write-Output ('Numero de serie: ' + $_.SerialNumber) } } catch { Write-Output 'Error al obtener informacion de placa base' }" >> "%output_file%"
) else (
    echo Fabricante: >> "%output_file%"
    wmic baseboard get manufacturer 2>nul | findstr /V "Manufacturer" | findstr /R /V "^$" >> "%output_file%"
    echo Modelo: >> "%output_file%"
    wmic baseboard get product 2>nul | findstr /V "Product" | findstr /R /V "^$" >> "%output_file%"
    echo Numero de serie: >> "%output_file%"
    wmic baseboard get serialnumber 2>nul | findstr /V "SerialNumber" | findstr /R /V "^$" >> "%output_file%"
)
echo --------------------------------------------------------------- >> "%output_file%"
echo. >> "%output_file%"

rem ===== INFORMACIÓN DEL PROCESADOR =====
echo [4/10] Recopilando informacion del procesador...
echo --- PROCESADOR ------------------------------------------------ >> "%output_file%"
if !PS_AVAILABLE! equ 1 (
    powershell -command "try { Get-WmiObject Win32_Processor | ForEach-Object { Write-Output ('Nombre: ' + $_.Name); Write-Output ('Fabricante: ' + $_.Manufacturer); Write-Output ('Velocidad maxima: ' + $_.MaxClockSpeed + ' MHz'); Write-Output ('Velocidad actual: ' + $_.CurrentClockSpeed + ' MHz'); Write-Output ('Nucleos fisicos: ' + $_.NumberOfCores); Write-Output ('Nucleos logicos: ' + $_.NumberOfLogicalProcessors); Write-Output ('Arquitectura: ' + $(if($_.AddressWidth -eq 64){'64-bit'}else{'32-bit'})) } } catch { Write-Output 'Error al obtener informacion del procesador' }" >> "%output_file%"
) else (
    echo Nombre: >> "%output_file%"
    wmic cpu get name 2>nul | findstr /V "Name" | findstr /R /V "^$" >> "%output_file%"
    echo Fabricante: >> "%output_file%"
    wmic cpu get manufacturer 2>nul | findstr /V "Manufacturer" | findstr /R /V "^$" >> "%output_file%"
    echo Velocidad maxima: >> "%output_file%"
    wmic cpu get maxclockspeed 2>nul | findstr /V "MaxClockSpeed" | findstr /R /V "^$" >> "%output_file%"
    echo Nucleos: >> "%output_file%"
    wmic cpu get numberofcores 2>nul | findstr /V "NumberOfCores" | findstr /R /V "^$" >> "%output_file%"
)
echo --------------------------------------------------------------- >> "%output_file%"
echo. >> "%output_file%"

rem ===== INFORMACIÓN DE LA MEMORIA =====
echo [5/10] Recopilando informacion de la memoria...
echo --- MEMORIA RAM ----------------------------------------------- >> "%output_file%"
if !PS_AVAILABLE! equ 1 (
    powershell -command "try { $totalRAM = (Get-WmiObject Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1GB; $os = Get-WmiObject Win32_OperatingSystem; $usedRAM = ($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB; $freeRAM = $os.FreePhysicalMemory / 1MB; Write-Output ('Memoria total instalada: ' + [math]::Round($totalRAM, 2) + ' GB'); Write-Output ('Memoria en uso: ' + [math]::Round($usedRAM, 2) + ' GB'); Write-Output ('Memoria libre: ' + [math]::Round($freeRAM, 2) + ' GB'); Write-Output ''; Write-Output 'Modulos instalados:'; Get-WmiObject Win32_PhysicalMemory | ForEach-Object { $capGB = [math]::Round($_.Capacity / 1GB, 2); Write-Output ('  - ' + $capGB + ' GB @ ' + $_.Speed + ' MHz (' + $_.Manufacturer + ')') } } catch { Write-Output 'Error al obtener informacion de memoria' }" >> "%output_file%"
) else (
    echo Capacidad: >> "%output_file%"
    wmic memorychip get capacity 2>nul | findstr /V "Capacity" | findstr /R /V "^$" >> "%output_file%"
    echo Velocidad: >> "%output_file%"
    wmic memorychip get speed 2>nul | findstr /V "Speed" | findstr /R /V "^$" >> "%output_file%"
)
echo --------------------------------------------------------------- >> "%output_file%"
echo. >> "%output_file%"

rem ===== INFORMACIÓN DE DISCOS =====
echo [5/10] Recopilando informacion de discos...
echo --- DISCOS Y ALMACENAMIENTO ----------------------------------- >> %output_file%
echo ** Discos fisicos ** >> %output_file%
if !PS_AVAILABLE! equ 1 (
    powershell -command "try { Get-WmiObject Win32_DiskDrive | ForEach-Object { $sizeGB = [math]::Round($_.Size / 1GB, 2); Write-Output ('  Disco: ' + $_.DeviceID); Write-Output ('  Modelo: ' + $_.Model); Write-Output ('  Tamano: ' + $sizeGB + ' GB'); Write-Output ('  Tipo: ' + $_.MediaType); Write-Output ('  Estado: ' + $_.Status); Write-Output ('  Particiones: ' + $_.Partitions); Write-Output '' } } catch { Write-Output 'Error al obtener informacion de discos' }" >> %output_file%
) else (
    wmic diskdrive get deviceid,model,size,mediatype | findstr /V "DeviceID" | findstr /V "^$" >> %output_file%
)
echo. >> %output_file%
echo ** Particiones logicas ** >> %output_file%
if !PS_AVAILABLE! equ 1 (
    powershell -command "try { Get-WmiObject Win32_LogicalDisk -Filter 'DriveType=3' | ForEach-Object { $freeGB = [math]::Round($_.FreeSpace / 1GB, 2); $sizeGB = [math]::Round($_.Size / 1GB, 2); $usedGB = $sizeGB - $freeGB; $percentFree = [math]::Round(($_.FreeSpace / $_.Size) * 100, 2); $percentUsed = 100 - $percentFree; Write-Output ('  Unidad ' + $_.DeviceID); Write-Output ('  Tamano total: ' + $sizeGB + ' GB'); Write-Output ('  Espacio usado: ' + $usedGB + ' GB (' + $percentUsed + '%%)'); Write-Output ('  Espacio libre: ' + $freeGB + ' GB (' + $percentFree + '%%)'); Write-Output ('  Sistema de archivos: ' + $_.FileSystem); Write-Output ('  Etiqueta: ' + $_.VolumeName); Write-Output '' } } catch { Write-Output 'Error al obtener informacion de particiones' }" >> %output_file%
) else (
    wmic logicaldisk where drivetype=3 get deviceid,filesystem,size,freespace,volumename | findstr /V "DeviceID" | findstr /V "^$" >> %output_file%
)
echo --------------------------------------------------------------- >> %output_file%
echo. >> %output_file%

rem ===== INFORMACIÓN DE TARJETA GRÁFICA =====
echo [6/10] Recopilando informacion de tarjeta grafica...
echo --- TARJETA GRAFICA ------------------------------------------- >> %output_file%
if !PS_AVAILABLE! equ 1 (
    powershell -command "try { Get-WmiObject Win32_VideoController | ForEach-Object { $ramGB = if ($_.AdapterRAM) { [math]::Round($_.AdapterRAM / 1GB, 2) } else { 'N/A' }; Write-Output ('Nombre: ' + $_.Name); Write-Output ('Memoria dedicada: ' + $ramGB + ' GB'); Write-Output ('Procesador: ' + $_.VideoProcessor); Write-Output ('Driver: ' + $_.DriverVersion); if ($_.CurrentHorizontalResolution) { Write-Output ('Resolucion actual: ' + $_.CurrentHorizontalResolution + ' x ' + $_.CurrentVerticalResolution) }; if ($_.CurrentRefreshRate) { Write-Output ('Tasa de refresco: ' + $_.CurrentRefreshRate + ' Hz') }; Write-Output ('Estado: ' + $_.Status); Write-Output '' } } catch { Write-Output 'Error al obtener informacion de GPU' }" >> %output_file%
) else (
    wmic path win32_videocontroller get name,adapterram,videoprocessor,driverversion | findstr /V "Name" | findstr /V "^$" >> %output_file%
)
echo --------------------------------------------------------------- >> %output_file%
echo. >> %output_file%

rem ===== NÚMEROS DE SERIE Y LICENCIAS =====
echo [7/10] Recopilando numeros de serie y licencias...
echo --- NUMEROS DE SERIE Y LICENCIAS ------------------------------ >> %output_file%
echo ** BIOS/UEFI ** >> %output_file%
	powershell -Command "(Get-CimInstance Win32_BIOS | Select-Object SerialNumber) | ForEach-Object { $_.SerialNumber }" >> "%output_file%"
	powershell -Command "(Get-CimInstance Win32_BIOS | Select-Object Manufacturer, SMBIOSBIOSVersion, ReleaseDate | ForEach-Object { $_.Manufacturer + ' ' + $_.SMBIOSBIOSVersion + ' ' + $_.ReleaseDate })" >> "%output_file%"
echo. >> %output_file%
echo ** Windows ** >> %output_file%
	powershell -Command "(Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version, BuildNumber, SerialNumber | ForEach-Object { $_.Caption + ' ' + $_.Version + ' ' + $_.BuildNumber + ' ' + $_.SerialNumber })" >> "%output_file%"

if !PS_AVAILABLE! equ 1 (
    powershell -command "try { $license = Get-WmiObject SoftwareLicensingProduct -Filter 'Name like ''Windows%%'' AND PartialProductKey IS NOT NULL' | Select-Object -First 1; if ($license) { $status = switch($license.LicenseStatus) { 0 {'Sin licencia'} 1 {'Licenciado'} 2 {'Periodo de gracia OOB'} 3 {'Periodo de gracia OOT'} 4 {'Periodo de gracia no genuino'} 5 {'Notificacion'} 6 {'Periodo de gracia extendido'} default {'Desconocido'} }; Write-Output ('Estado de activacion: ' + $status); if ($license.PartialProductKey) { Write-Output ('Clave parcial: ' + $license.PartialProductKey) } } } catch { Write-Output 'No se pudo obtener estado de licencia' }" >> %output_file%
)
echo --------------------------------------------------------------- >> %output_file%
echo. >> %output_file%

rem ===== INFORMACIÓN DE MICROSOFT OFFICE =====
echo [8/10] Buscando instalaciones de Microsoft Office...
echo --- MICROSOFT OFFICE ------------------------------------------ >> %output_file%
if !PS_AVAILABLE! equ 1 (
    powershell -command "try { $office = @(); $office += Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like '*Microsoft*Office*' -or $_.DisplayName -like '*Microsoft 365*' }; $office += Get-ItemProperty 'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like '*Microsoft*Office*' -or $_.DisplayName -like '*Microsoft 365*' }; if ($office) { $office | Select-Object DisplayName, DisplayVersion, InstallDate, InstallLocation -Unique | ForEach-Object { Write-Output ('Producto: ' + $_.DisplayName); Write-Output ('Version: ' + $_.DisplayVersion); if ($_.InstallDate) { Write-Output ('Fecha de instalacion: ' + $_.InstallDate) }; Write-Output ('Ubicacion: ' + $_.InstallLocation); Write-Output '' } } else { Write-Output 'Microsoft Office no esta instalado.' } } catch { Write-Output 'Error al buscar Office' }" >> %output_file%
) else (
    wmic product where "name like '%%Office%%'" get name,version /format:list >> %output_file% 2>nul
    if !errorlevel! neq 0 echo Microsoft Office no detectado. >> %output_file%
)
echo --------------------------------------------------------------- >> %output_file%
echo. >> %output_file%

rem ===== INFORMACIÓN DE RED =====
echo [9/10] Recopilando informacion de red...
echo --- CONFIGURACION DE RED -------------------------------------- >> %output_file%
if !PS_AVAILABLE! equ 1 (
    powershell -Command "try { $adapters = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }; foreach ($adapter in $adapters) { Write-Output (''); Write-Output ('=== ' + $adapter.Description + ' ==='); Write-Output ('MAC Address: ' + $adapter.MACAddress); if ($adapter.IPAddress) { Write-Output ('IPv4: ' + ($adapter.IPAddress | Where-Object { $_ -like '*.*.*.*' })) }; if ($adapter.DefaultIPGateway) { Write-Output ('Gateway: ' + $adapter.DefaultIPGateway[0]) }; if ($adapter.DNSServerSearchOrder) { Write-Output ('DNS: ' + ($adapter.DNSServerSearchOrder -join ', ')) }; Write-Output ('DHCP: ' + $(if($adapter.DHCPEnabled){'Habilitado'}else{'Deshabilitado'})) } } catch { Write-Output 'Error al obtener informacion de red' }" >> %output_file%
) else (
    ipconfig /all >> %output_file%
)
echo. >> %output_file%
echo ** Prueba de conectividad ** >> %output_file%
ping -n 4 8.8.8.8 | findstr "Average" >> %output_file% 2>nul
if !errorlevel! neq 0 echo Sin conectividad a Internet >> %output_file%
echo --------------------------------------------------------------- >> %output_file%
echo. >> %output_file%

rem ===== LIMPIEZA DE ARCHIVOS TEMPORALES =====
echo [10/10] Limpiando archivos temporales...
echo --- LIMPIEZA DE ARCHIVOS TEMPORALES --------------------------- >> %output_file%

rem Calcular tamaño antes de la limpieza
echo    Analizando carpeta temporal...
if !PS_AVAILABLE! equ 1 (
    for /f %%A in ('powershell -command "try { $size = (Get-ChildItem -Path $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum; if ($size) { $size } else { 0 } } catch { 0 }"') do set size_before=%%A
    for /f %%A in ('powershell -command "try { $count = (Get-ChildItem -Path $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object).Count; if ($count) { $count } else { 0 } } catch { 0 }"') do set num_before=%%A
) else (
    set size_before=0
    set num_before=0
    for /f %%A in ('dir /s /b "%TEMP%" 2^>nul ^| find /c /v ""') do set num_before=%%A
)

echo    Archivos encontrados: !num_before!

rem Realizar limpieza segura
echo    Eliminando archivos...
if !PS_AVAILABLE! equ 1 (
    powershell -command "try { $cleaned = 0; $errors = 0; Get-ChildItem -Path $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object { try { Remove-Item $_.FullName -Force -Recurse -ErrorAction Stop; $cleaned++ } catch { $errors++ } }; Write-Output ('Elementos procesados: ' + $cleaned); Write-Output ('Errores (archivos en uso): ' + $errors) } catch { Write-Output 'Error durante la limpieza' }" >> %output_file%
) else (
    del /q /f /s "%TEMP%\*" >nul 2>&1
    for /d %%p in ("%TEMP%\*") do rmdir "%%p" /s /q >nul 2>&1
    echo Limpieza completada (metodo basico) >> %output_file%
)

rem Calcular después de la limpieza
if !PS_AVAILABLE! equ 1 (
    for /f %%A in ('powershell -command "try { $size = (Get-ChildItem -Path $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum; if ($size) { $size } else { 0 } } catch { 0 }"') do set size_after=%%A
    for /f %%A in ('powershell -command "try { $count = (Get-ChildItem -Path $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object).Count; if ($count) { $count } else { 0 } } catch { 0 }"') do set num_after=%%A
) else (
    set size_after=0
    set num_after=0
    for /f %%A in ('dir /s /b "%TEMP%" 2^>nul ^| find /c /v ""') do set num_after=%%A
)

rem Calcular diferencias
set /a num_deleted=!num_before! - !num_after!
set /a space_freed=!size_before! - !size_after!
set /a space_freed_mb=!space_freed! / 1048576

echo. >> %output_file%
echo Archivos/carpetas eliminados: !num_deleted! >> %output_file%
echo Espacio liberado: !space_freed_mb! MB (!space_freed! bytes) >> %output_file%
echo --------------------------------------------------------------- >> %output_file%
echo. >> %output_file%

rem ===== PIE DEL REPORTE =====
echo ================================================================ >> %output_file%
echo                    FIN DEL REPORTE >> %output_file%
echo ================================================================ >> %output_file%

rem ===== RESUMEN FINAL =====
cls
echo ================================================================
echo               PROCESO COMPLETADO                        
echo ================================================================
echo.
echo Reporte generado exitosamente
if !IS_ADMIN! equ 1 (
    echo Modo: ADMINISTRADOR
    echo Ubicacion: Carpeta actual del script
) else (
    echo Modo: USUARIO ESTANDAR
    echo Ubicacion: Carpeta Reportes_Sistema\
)
echo.
echo Estadisticas de limpieza:
echo    - Archivos eliminados: !num_deleted!
echo    - Espacio liberado: !space_freed_mb! MB
echo.
echo Archivo guardado en:
echo    %output_file%
echo.
echo Presiona cualquier tecla para abrir el reporte...
pause >nul

rem Abrir el archivo con el editor predeterminado
start "" "%output_file%"