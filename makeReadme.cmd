@echo off

echo # NetLogo-models > README.md
echo. >> README.md
for %%i in (*.nlogo) do echo * [http://netlogoweb.org/web?https://raw.githubusercontent.com/rikblok/NetLogo-models/master/%%~nxi](%%~nxi) >> README.md
:: To run brown2009 use this link: http://netlogoweb.org/web?https://raw.githubusercontent.com/rikblok/NetLogo-models/master/brown2009-web.nlogo
