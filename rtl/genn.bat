@echo off 
chcp 936 > nul 
setlocal enabledelayedexpansion 
 
set /p moduleName="请输入要生成的模块名称 (例如: my_module): " 
 
if "%moduleName%"=="" ( 
    echo 错误：模块名称不能为空！ 
    pause 
    exit /b 1 
) 
echo 正在生成 %moduleName%.v ... 
 
echo `timescale 1ns / 1ps > "%moduleName%.v" 
echo. >> "%moduleName%.v" 
echo module %moduleName%^( >> "%moduleName%.v" 
echo     // Add your ports here >> "%moduleName%.v" 
echo ); >> "%moduleName%.v" 
echo. >> "%moduleName%.v" 
echo // Your RTL code goes here >> "%moduleName%.v" 
echo. >> "%moduleName%.v" 
echo endmodule >> "%moduleName%.v" 
 
echo %moduleName%.v 已生成在当前目录。 
pause 
endlocal 
