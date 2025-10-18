@echo off 
chcp 936 > nul 
setlocal enabledelayedexpansion 
 
set /p tbName="请输入要生成的Testbench名称 (例如: my_testbench): " 
 
if "%tbName%"=="" ( 
    echo 错误：Testbench名称不能为空！ 
    pause 
    exit /b 1 
) 
echo 正在生成 tb_%tbName%.v ... 
 
echo `timescale 1ns / 1ps > "%tbName%.v" 
echo. >> "%tbName%.v" 
echo module tb_%tbName%^( >> "%tbName%.v" 
echo ); >> "%tbName%.v" 
echo. >> "%tbName%.v" 
echo // Add your testbench code here >> "%tbName%.v" 
echo. >> "%tbName%.v" 
echo initial begin >> "%tbName%.v" 
echo     // Initial stimulus >> "%tbName%.v" 
echo     #100 $finish; >> "%tbName%.v" 
echo end >> "%tbName%.v" 
echo. >> "%tbName%.v" 
echo endmodule >> "%tbName%.v" 
 
echo tb_%tbName%.v 已生成在当前目录。 
endlocal 
