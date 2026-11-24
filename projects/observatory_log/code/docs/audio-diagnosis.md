# 网页版没声音：诊断与修复（已解决）

> 2026-11-17 03:00 结案。**根因：游戏在运行时才创建 `Music / SFX / Amb` 三条音频总线，Web 导出的音频驱动初始化时只认识 `Master`，之后新建的总线没有被接到输出上。**
> 修复：把总线布局写成工程自带的 `default_bus_layout.tres`（并在 `project.godot` 里显式注册）。

## 结论一行

桌面版正常、网页版只有画面没有声音，是因为网页版的所有声音都走「运行时新建的总线」，而那几条总线在浏览器里从来没有连到扬声器。

## 证据链

| # | 实验 | 结果 |
| --- | --- | --- |
| 1 | 页面里给「连着 `AudioContext.destination` 的 GainNode」挂 AnalyserNode，连续采样 30 秒 | 有信号：均值 RMS **0.128**、峰值 0.18，说明图里有声音 |
| 2 | **同时**从 Windows 音频会话（`IAudioMeterInformation`）读同一个 `msedge` 进程的峰值 | **0.0000**（64 次采样全 0） |
| 3 | 在**同一个 AudioContext** 里临时加一个 660 Hz、增益 0.3 的振荡器 | Windows 峰值 **0.30** —— 上下文、设备、混音器全都没问题 |
| 4 | 换 `--autoplay-policy=no-user-gesture-required`、纯键盘无点击、去 COOP/COEP、换线程模板 | 全部仍然是 0 |
| 5 | 读 `Sfx._ready()` | `for b in ["Music", "SFX", "Amb"]: AudioServer.add_bus()` —— 三条总线在**引擎启动之后**才出现 |
| 6 | 把 `Master/Music/SFX/Amb` 写进 `default_bus_layout.tres`，并在 `project.godot` 里注册，重新导出 | Windows 峰值 **0.306**（本地）/ **0.334**（线上），E2E 4/4，Godot 门禁 42 文件 0 失败 |

实验 2 与 3 是关键对照：同一时刻、同一浏览器、同一上下文，页面里测到 0.128，系统混音器测到 0；我把一段测试音塞进同一个上下文，系统立刻测到 0.3。所以「页面里有信号」不等于「声音到了扬声器」——那 0.128 走的是**没有连到输出**的总线。

## 为什么桌面版没事

原生音频服务器允许运行时增删总线并自动接好输出；Web 导出的音频驱动在初始化时按总线布局建好混音图，运行期 `add_bus()` 创建的总线在浏览器里拿不到输出节点。这是平台差异，不是游戏逻辑错。

## 修复

```text
default_bus_layout.tres        Master / Music / SFX / Amb，三条子总线都 send 到 Master
project.godot                  [audio] default_bus_layout="res://default_bus_layout.tres"
```

`Sfx._ready()` 里「找不到就创建」的兜底保留，桌面和容器环境照旧。

## 防回归

- `tests/unit/audio.test.js`（5 条）：布局文件存在、总线名/顺序正确、非 Master 总线都 send 到 Master、脚本里引用的总线都在布局里、`Sfx` 仍保留兜底创建。
- 线上验收：`GAME_URL=https://observation-log-9t9.pages.dev npx playwright test` → 4/4。
- 人工验收：正常启动 Edge 打开线上地址，Windows 音量合成器里 Edge 那条有电平（峰值 0.33）。

## 我走过的弯路（留给下次）

1. 第一版挂了 `AudioWorkletNode` 的出口，读到全 0，误判「引擎不混音」——其实 `godot-processor` 是输入采集那条路，播放走每采样一个 `AudioBufferSourceNode`。
2. 第二版只测了页面内部，看到 0.128 就以为通了——**页面内有信号 ≠ 出声**。
3. 最后靠「同时读 Windows 混音器」+「同一上下文里塞测试音」这两个对照才把范围压到「总线没接输出」。

教训：**验证声音要用系统级出口做基准**，页面内部的 AnalyserNode 只能证明「图里有数」，不能证明「你听得见」。
