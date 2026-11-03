# 编译和下载

验证所用软件为 Gowin V1.9.12.04 x64、ModelSim Intel FPGA Starter Edition（日志记录实际运行结果）。加密 Gowin IP 需要相应工具支持。

先在包根目录运行 tools/setup.ps1，再打开 T:\cam2dvi\cam2dvi.gprj。命令行编译示例：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\build.ps1 -GowinExe "C:\Gowin\IDE\bin\gw_sh.exe"
```

示例中的安装路径需换成室友电脑上的实际路径。完整回归示例：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\run_tests.ps1 -VsimExe "C:\ModelSim\vsim.exe"
```

下载已验证码流时，器件选择 GW5AST-138B，选择 SRAM Program，加载 bitstreams/final_74C3.fs。既有最终文件 UserCode 为 0x000074C3、SHA256 为 2fa396094d2c0737e52dcf0e03bc4271e8655359fd78f2b6ca32e448a35b8f1b；最后下载状态为 0x00026230。重新编译产生的 UserCode 可能变化，不能把新构建当作同一文件。

本包不自动编程，也没有 Flash 写入脚本。SRAM 下载断电不保留；最终脱机演示需要保留供电，或在确认最终版本后单独完成 Flash 配置。

T: 映射的目的仅是保持验证过的源文件字节不变并解决绝对 include 路径；如果 T: 已被占用，setup.ps1 会停止，不会移除其他映射。IP 头部 D:/、E:/ 路径只是历史注释，不需要复原那些目录。
