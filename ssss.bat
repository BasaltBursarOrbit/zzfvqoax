@echo off
title WORM CLEANUP - svchost32
cd /d "%~dp0"
echo ============================================
echo   WORM CLEANUP (svchost32 + aabvv.exe)
echo ============================================
echo.

:: ==================== 1. УБИТЬ ПРОЦЕССЫ ====================
echo [1/8] Killing processes...
taskkill /f /im aabvv.exe >nul 2>&1
taskkill /f /im svchost.exe >nul 2>&1
:: Убиваем только наш svchost.exe (не системный) через wmic
wmic process where "name='svchost.exe' and (CommandLine like '%%svchost32%%' or ExecutablePath like '%%Program Files%%svchost32%%' or ExecutablePath like '%%System32%%svchost.exe%%')" call terminate >nul 2>&1
timeout /t 2 /nobreak >nul
echo       Done.

:: ==================== 2. УДАЛИТЬ СЕРВИС ====================
echo [2/8] Removing service svchost32...
sc stop svchost32 >nul 2>&1
sc delete svchost32 >nul 2>&1
echo       Done.

:: ==================== 3. УДАЛИТЬ ЗАДАЧУ ПЛАНИРОВЩИКА ====================
echo [3/8] Removing scheduled task...
schtasks /delete /tn "svchost32" /f >nul 2>&1
echo       Done.

:: ==================== 4. УДАЛИТЬ WMIC ПОДПИСКИ ====================
echo [4/8] Removing WMIC subscriptions...
wmic /namespace:\\root\\subscription path **FilterToConsumerBinding where "Filter='__EventFilter.Name=\"F_svchost32\"'" delete >nul 2>&1
wmic /namespace:\\root\\subscription path __CommandLineEventConsumer where "Name='C_svchost32'" delete >nul 2>&1
wmic /namespace:\\root\\subscription path __EventFilter where "Name='F_svchost32'" delete >nul 2>&1
echo       Done.

:: ==================== 5. ОЧИСТИТЬ РЕЕСТР ====================
echo [5/8] Cleaning registry...
reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v svchost32 /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v svchost32 /f >nul 2>&1
reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v svchost32 /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v svchost32 /f >nul 2>&1
reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v svchost32upd /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v svchost32upd /f >nul 2>&1
echo       Done.

:: ==================== 6. ВОССТАНОВИТЬ EXPLORER ====================
echo [6/8] Restoring explorer.exe...
if exist "C:\Windows\system32\explorer.bak" (
    taskkill /f /im explorer.exe >nul 2>&1
    timeout /t 1 /nobreak >nul
    move /y "C:\Windows\system32\explorer.bak" "C:\Windows\system32\explorer.exe" >nul 2>&1
    start explorer.exe
    echo       Restored from backup.
) else (
    echo       No backup found (explorer was not replaced).
)

:: ==================== 7. УДАЛИТЬ ФАЙЛЫ ====================
echo [7/8] Removing files...
:: Стилллер
if exist "C:\Program Files\svchost32" (
    attrib -h -s "C:\Program Files\svchost32\aabvv.exe" >nul 2>&1
    del /f /q "C:\Program Files\svchost32\aabvv.exe" >nul 2>&1
    rmdir "C:\Program Files\svchost32" >nul 2>&1
)
:: Temp
del /f /q "%TEMP%\aabvv.exe" >nul 2>&1
del /f /q "%TEMP%\svchost32.log" >nul 2>&1
:: Startup (общий)
del /f /q "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\svchost.exe" >nul 2>&1
:: Startup (пользователь)
del /f /q "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\svchost.exe" >nul 2>&1
:: System32 (наш svchost.exe, не системный)
if exist "C:\Windows\system32\svchost.exe" (
    :: Проверяем что это НЕ оригинальный системный svchost.exe
    for %%F in ("C:\Windows\system32\svchost.exe") do (
        if %%~zF LSS 500000 (
            attrib -h -s "C:\Windows\system32\svchost.exe" >nul 2>&1
            del /f /q "C:\Windows\system32\svchost.exe" >nul 2>&1
        )
    )
)
echo       Done.

:: ==================== 8. ОЧИСТИТЬ СМЕННЫЕ НОСИТЕЛИ ====================
echo [8/8] Cleaning removable drives...
for %%D in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist "%%D:\" (
        for /f "delims=" %%T in ('wmic logicaldisk where "DeviceID='%%D:'" get DriveType /value 2^>nul ^| findstr "="') do (
            set "DT=%%T"
            set "DT=!DT:DriveType=!"
            if "!DT!"=="2" (
                attrib -h -s "%%D:\svchost.tmp" >nul 2>&1
                del /f /q "%%D:\svchost.tmp" >nul 2>&1
                attrib -h "%%D:\autorun.inf" >nul 2>&1
                del /f /q "%%D:\autorun.inf" >nul 2>&1
                attrib -h -s "%%D:\aabvv.exe" >nul 2>&1
                del /f /q "%%D:\aabvv.exe" >nul 2>&1
                echo       Drive %%D: cleaned.
            )
        )
    )
)
echo       Done.

:: ==================== ИТОГ ====================
echo.
echo ============================================
echo   CLEANUP COMPLETE
echo ============================================
echo.
echo Проверь вручную:
echo   1. tasklist ^| findstr /i "aabvv svchost"
echo   2. reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v svchost32
echo   3. sc query svchost32
echo   4. schtasks /query /tn "svchost32"
echo.
echo Рекомендуется перезагрузка.
echo.
pause