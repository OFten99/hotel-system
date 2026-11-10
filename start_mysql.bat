@echo off
chcp 65001 >nul
rem ---- 按自己的环境改下面三个变量 ----
if "%MYSQL_HOME%"=="" set "MYSQL_HOME=C:\Program Files\MySQL\MySQL Server 8.4"
if "%MYSQL_DATA%"=="" set "MYSQL_DATA=D:\MySQLData"
if "%MYSQL_PORT%"=="" set "MYSQL_PORT=3306"
title 启动 MySQL

echo ============================================================
echo   启动 MySQL（免服务方式，数据目录 %MYSQL_DATA%）
echo ============================================================

netstat -ano | findstr ":%MYSQL_PORT%" | findstr "LISTENING" >nul
if not errorlevel 1 (
    echo.
    echo [提示] MySQL 已在运行（%MYSQL_PORT% 端口已监听），无需重复启动。
    pause
    exit /b 0
)

echo.
echo 正在启动 MySQL，请稍候...
start "" "%MYSQL_HOME%\bin\mysqld.exe" --no-defaults "--basedir=%MYSQL_HOME%" --datadir=%MYSQL_DATA% --port=%MYSQL_PORT% --character-set-server=utf8mb4 --max_connections=200

timeout /t 6 /nobreak >nul

netstat -ano | findstr ":%MYSQL_PORT%" | findstr "LISTENING" >nul
if errorlevel 1 (
    echo.
    echo [错误] MySQL 未能在 6 秒内就绪，请检查 %MYSQL_DATA% 是否正常。
) else (
    echo.
    echo [OK] MySQL 已就绪（端口 %MYSQL_PORT%）。
)
echo.
pause
