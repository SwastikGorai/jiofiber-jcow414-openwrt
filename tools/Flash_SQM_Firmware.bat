@echo off
REM ============================================================
REM  JCOW414 SQM Firmware Installer (Windows wrapper)
REM  Downloads the 1.1-sqm image, verifies it, and flashes the
REM  router over the root Telnet shell unlocked earlier.
REM  Requires Python 3 (py launcher) or python on PATH.
REM ============================================================
where py >nul 2>nul
if %errorlevel%==0 (
    py -3 "%~dp0Flash_SQM_Firmware.py" %*
    goto :eof
)
where python >nul 2>nul
if %errorlevel%==0 (
    python "%~dp0Flash_SQM_Firmware.py" %*
    goto :eof
)
echo Python 3 not found. Install it from https://www.python.org/downloads/
echo or run tools\Flash_SQM_Firmware.py on any machine with Python 3.
pause
