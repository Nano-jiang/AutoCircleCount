# AutoCircleCount

[![MATLAB](https://img.shields.io/badge/MATLAB-R2021a%20or%20higher-blue.svg)](https://www.mathworks.com/products/matlab.html)
[![Field](https://img.shields.io/badge/Field-Behavioral%20Neuroscience-green.svg)]()

**AutoCircleCount** 是一套基于 MATLAB 开发的全流程行为学分析方案，专门用于环形迷宫（Circular Maze）场景下的动态目标追踪与自动化圈数识别。系统通过整合轨迹几何特征与运动学参数，实现对小鼠顺时针跑圈行为的高精度量化。

---

## 📖 范式描述 (Paradigm Description)
在 **30 cm × 30 cm** 的环形迷宫中，系统利用小鼠运动轨迹的累计像素长度，结合起始/终点区域（如右下角固定食盒位置）的**角度突变特征（Angular Spike Feature）**，自动识别并统计完整的顺时针（Clockwise）运动圈数。

---

## 🚀 快速开始 (Quick Start)

### 1. 环境要求
* **MATLAB**: 推荐使用 R2021a 或更高版本。
* **工具箱依赖**: 
    * Image Processing Toolbox

### 2. 标准操作流程
1. **启动程序**: 下载并解压仓库，在 MATLAB 命令窗口运行主入口脚本：
   ```matlab
   AutoCircleCount_CF_main.m
2. **数据交互**: 在弹出的对话框中选择包含原始视频序列的文件夹（建议初次使用时选择 `Demos/` 文件夹进行测试）。
3. **ROI 划定**: 根据交互提示，框选环形迷宫的整体边界 (**Region of Interest**)。
<div align="center">
  <img width="266" height="270" alt="image" src="https://github.com/user-attachments/assets/b4edaf3e-48b0-4fad-a599-d81065e48710" />
</div>

4. **信号校准**: 在命令行提示下，定位至头部红色 LED 信号清晰的帧，并手动框选 **LED 特征区域**。系统将以此作为模板进行全时段坐标重心追踪。

---

## 📊 数据输出 (Output & Visualization)
分析完成后，系统将在自动创建的 `FrameCount2/` 目录下生成以下分析结果：

1. **FrameCount.xlsx**: 核心数据表，记录每一圈顺时针运动的起始帧（Start Frame）与结束帧（End Frame）。
2. **Figure 1**: **角度突变特征 - 速率曲线**。用于验证跑圈逻辑，通过角度突变点判断计数是否准确。
3. **Figure 2 & 3**: **路径可视化**。分别呈现“合格跑圈”与“剔除跑圈”的运动轨迹及其对应的瞬时速率空间分布。
4. **Figure 4**: **平均速率曲线**。反映整个 Session 期间小鼠的运动速率趋势。

---

## 📥 示例数据 (Demo Data)
为了方便初次使用者快速上手，提供了预置的 Demo 数据集（包含示例视频及配置文件）：

* **下载链接**: [Quark 网盘 (夸克)](https://pan.quark.cn/s/e7581e1e486b)
* **使用说明**: 
    1. 下载并解压 Demos 压缩包。
    2. 运行主程序后，在弹出的文件夹选择窗口中选中解压后的文件夹即可。
