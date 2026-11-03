# 模块与接口

| 文件 | 职责 |
|---|---|
| top.v、cmos_8_16bit.v、i2c_master、lut_ov5640_rgb565_1280_720.v | DVP1 接入、OV5640 配置、RGB565 拼接、DDR3 与显示连接 |
| dehaze_color_safe.v、gain_extra_rom.vh、dehaze_stream_top.v | 15×15 暗通道及受限公共 RGB 校正，16 周期流水线 |
| video_compare.v | 同一完整帧的原图/增强预览、存储仲裁、原图抓拍和计数 |
| sign_detector.v、sign_templates.vh | 黄色候选区域、16×16 掩码模板、四个方向与镜像模板、多帧确认；施工拒识 |
| demo_controls.v | S1 消抖、单击、双击、长按 |
| rgb_invert.v | 处理、识别、按键与 OSD 集成 |
| video_osd.v、osd_layout.vh、osd_font.hex | 原生像素域中文标签、操作提示、计数与隐藏调试区 |

检测从增强帧取样，证据抓拍保留原图。预览为320×144，抓拍为160×90 RGB565。内部类别编号继续使用2/3/4/5，不需要改成连续0~3；编号1用于拒识参考，不产生施工识别输出。

按键：S1→F15，S0→K16复位。双目转接板当前使用DVP1，cmos_scl=W23，sda=R25，vsync=P25，href=T25，pclk=U15，rst=R23，pwdn=U16；八位数据为T23/P24/P23/U17/P21/Y21/W21/V17。约束以138K_PRO_DOCK.cst为准。当前并非立体视觉处理。

工程文件还保留旧模式/未连接算法模块，以维持原工程依赖及可追溯性；报告应按顶层实际连接描述，不把未接通模块写成已实现功能。
