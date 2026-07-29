@echo off
echo ====================================================
echo INICIANDO O SERVIDOR DO OUTLET DO CELULAR...
echo ====================================================
cd /d "%~dp0\checklist-server"
node index.js
pause
