#!/usr/bin/env python3
"""生成 3 位格雷码计数器的 Logisim .circ 文件"""

import os

output_path = os.path.expanduser("~/Desktop/new.circ")

# === 元件位置 ===
# D触发器 at (x,y): Q@(x+50, y+10), D@(x, y+10), EN@(x, y+30), CLK@(x, y+50), CLR@(x, y+70)
D2 = {"x": 460, "y": 40}
D1 = {"x": 460, "y": 180}
D0 = {"x": 460, "y": 320}

# 门电路: NOT(30x30) IN@(x,y+15) OUT@(x+30,y+15)
#         AND/OR/XOR(40x30) IN1@(x,y+10) IN2@(x,y+20) OUT@(x+40,y+15)
XOR  = {"x": 320, "y": 50}
NOT1 = {"x": 180, "y": 210}   # Q0 ─→ NOT ─→ AND1, AND3
NOT2 = {"x": 180, "y": 280}   # Q2 ─→ NOT ─→ AND2, AND3 (共享)
NOT3 = {"x": 180, "y": 380}   # Q1 ─→ NOT ─→ AND4
AND1 = {"x": 280, "y": 210}   # Q1·¬Q0
AND2 = {"x": 280, "y": 270}   # Q0·¬Q2
AND3 = {"x": 280, "y": 340}   # Q0·¬Q2
AND4 = {"x": 280, "y": 410}   # Q2·¬Q1
OR1  = {"x": 380, "y": 230}   # AND1 + AND2 → D1.D
OR2  = {"x": 380, "y": 380}   # AND3 + AND4 → D0.D

# Clock/Constant: 输出在元件位置
CLOCK  = {"x": 80, "y": 240}
CONST0 = {"x": 60, "y": 40}    # 移到 x=60 避免与 Clock 总线短路
CONST1 = {"x": 410, "y": 10}   # 移到 x=410 避免与信号交叉

# 输出引脚 (facing=west): 输入在元件位置
G2 = {"x": 560, "y": 40}
G1 = {"x": 560, "y": 180}
G0 = {"x": 560, "y": 320}

# === 收集连线 ===
wires = []

def W(x1, y1, x2, y2):
    if (x1, y1) != (x2, y2):
        wires.append(((x1, y1), (x2, y2)))

# ===== 1. 时钟 (x=80 垂直总线) =====
# 总线从最上面 CLK(y=90) 到最下面 CLK(y=370)
W(80, 90, 80, 370)
W(80, 90, 460, 90)      # → D2.CLK(460,90)
W(80, 230, 460, 230)    # → D1.CLK(460,230)
W(80, 370, 460, 370)    # → D0.CLK(460,370)

# ===== 2. 复位 Const0 (x=60 垂直总线) =====
W(60, 40, 60, 390)      # 总线
W(60, 110, 460, 110)    # → D2.CLR(460,110)
W(60, 250, 460, 250)    # → D1.CLR(460,250)
W(60, 390, 460, 390)    # → D0.CLR(460,390)

# ===== 3. 使能 Const1 (x=410 垂直总线) =====
W(410, 10, 410, 350)    # 总线
W(410, 70, 460, 70)     # → D2.EN(460,70)
W(410, 210, 460, 210)   # → D1.EN(460,210)
W(410, 350, 460, 350)   # → D0.EN(460,350)

# ===== 4. D2 = Q2 ⊕ Q1 =====
# D2.Q(510,50) → XOR.IN1(320,60)
W(510, 50, 320, 50)
W(320, 50, 320, 60)
# D1.Q(510,190) → XOR.IN2(320,70)
W(510, 190, 350, 190)
W(350, 190, 350, 70)
W(350, 70, 320, 70)
# XOR.OUT(360,65) → D2.D(460,50) [从上方绕行避免与其他总线冲突]
W(360, 65, 360, 5)
W(360, 5, 460, 5)
W(460, 5, 460, 50)

# ===== 5. D1 = Q1·¬Q0 + Q0·¬Q2 =====
# --- NOT1: Q0 → ¬Q0 ---
W(510, 330, 180, 330)   # D0.Q 水平拉线
W(180, 330, 180, 225)   # ↓ 到 NOT1.IN(180,225)
# NOT1.OUT(210,225) → AND1.IN2(280,230)
W(210, 225, 280, 225)
W(280, 225, 280, 230)

# --- NOT2: Q2 → ¬Q2 (共享给 D1 和 D0) ---
W(510, 50, 160, 50)     # D2.Q 水平到 x=160
W(160, 50, 160, 295)    # ↓ 到 NOT2.IN 水平位置
W(160, 295, 180, 295)   # → NOT2.IN(180,295)
# NOT2.OUT(210,295) → AND2.IN2(280,290)
W(210, 295, 280, 295)
W(280, 295, 280, 290)

# --- AND1: Q1·¬Q0 ---
W(510, 190, 280, 190)   # D1.Q → AND1.IN1 水平位置
W(280, 190, 280, 220)   # ↓ 到 AND1.IN1(280,220)

# --- AND2: Q0·¬Q2 ---
W(510, 330, 280, 330)   # D0.Q 水平拉线 → AND2.IN1 水平位置
W(280, 330, 280, 280)   # ↑ 到 AND2.IN1(280,280)

# --- OR1: AND1.OUT + AND2.OUT → D1.D ---
W(320, 225, 380, 225)   # AND1.OUT → OR1.IN1 水平位置
W(380, 225, 380, 240)   # ↓ 到 OR1.IN1(380,240)
W(320, 285, 380, 285)   # AND2.OUT → OR1.IN2 水平位置
W(380, 285, 380, 250)   # ↓ 到 OR1.IN2(380,250)
W(420, 245, 460, 245)   # OR1.OUT 水平到 D1.D 水平位置
W(460, 245, 460, 190)   # ↑ 到 D1.D(460,190)

# ===== 6. D0 = Q0·¬Q2 + Q2·¬Q1 =====
# --- NOT3: Q1 → ¬Q1 ---
W(510, 190, 140, 190)   # D1.Q 水平到 x=140
W(140, 190, 140, 395)   # ↓ 到 NOT3.IN 水平位置
W(140, 395, 180, 395)   # → NOT3.IN(180,395)
# NOT3.OUT(210,395) → AND4.IN2(280,430)
W(210, 395, 280, 395)
W(280, 395, 280, 430)

# --- AND3: Q0·¬Q2 ---
# D0.Q → AND3.IN1 (与 AND2.IN1 共用 x=280 垂直线，都是 D0.Q 信号)
W(280, 330, 280, 350)   # ↓ 到 AND3.IN1(280,350)
# NOT2.OUT(210,295) → AND3.IN2(280,360)
W(210, 295, 210, 360)   # ↓ 到 AND3.IN2 水平位置
W(210, 360, 280, 360)   # → AND3.IN2(280,360)

# --- AND4: Q2·¬Q1 ---
# D2.Q → AND4.IN1 (从右侧绕行，避免与任何信号交叉)
W(510, 50, 530, 50)     # 先向右
W(530, 50, 530, 460)    # 向下到底部
W(530, 460, 280, 460)   # 向左到 AND4 下方
W(280, 460, 280, 420)   # ↑ 到 AND4.IN1(280,420)

# --- OR2: AND3.OUT + AND4.OUT → D0.D ---
W(320, 355, 380, 355)   # AND3.OUT → OR2.IN1 水平位置
W(380, 355, 380, 390)   # ↓ 到 OR2.IN1(380,390)
W(320, 425, 380, 425)   # AND4.OUT → OR2.IN2 水平位置
W(380, 425, 380, 400)   # ↓ 到 OR2.IN2(380,400)
W(420, 395, 460, 395)   # OR2.OUT → D0.D 水平位置
W(460, 395, 460, 330)   # ↑ 到 D0.D(460,330)

# ===== 7. 输出引脚 =====
W(510, 50, 560, 50)     # D2.Q → G2 水平位置
W(560, 50, 560, 40)     # ↑ 到 G2(560,40)
W(510, 190, 560, 190)   # D1.Q → G1 水平位置
W(560, 190, 560, 180)   # ↑ 到 G1(560,180)
W(510, 330, 560, 330)   # D0.Q → G0 水平位置
W(560, 330, 560, 320)   # ↑ 到 G0(560,320)

# === 去重 ===
wires_unique = list(set(wires))

# === 生成 XML ===
def gen():
    L = []
    L.append('<?xml version="1.0" encoding="UTF-8" standalone="no"?>')
    L.append('<project source="3.8.0" version="1.0">')
    L.append('  This file is intended to be loaded by Logisim-evolution v3.8.0(https://github.com/logisim-evolution/).')
    L.append('')
    L.append('  <lib desc="#Wiring" name="0">')
    L.append('    <tool name="Pin">')
    L.append('      <a name="appearance" val="classic"/>')
    L.append('    </tool>')
    L.append('  </lib>')
    L.append('  <lib desc="#Gates" name="1"/>')
    L.append('  <lib desc="#Plexers" name="2"/>')
    L.append('  <lib desc="#Arithmetic" name="3"/>')
    L.append('  <lib desc="#Memory" name="4"/>')
    L.append('  <lib desc="#I/O" name="5"/>')
    L.append('  <lib desc="#TTL" name="6"/>')
    L.append('  <lib desc="#TCL" name="7"/>')
    L.append('  <lib desc="#Base" name="8"/>')
    L.append('  <lib desc="#BFH-Praktika" name="9"/>')
    L.append('  <lib desc="#Input/Output-Extra" name="10"/>')
    L.append('  <lib desc="#Soc" name="11"/>')
    L.append('  <main name="main"/>')
    L.append('  <options>')
    L.append('    <a name="gateUndefined" val="ignore"/>')
    L.append('    <a name="simlimit" val="1000"/>')
    L.append('    <a name="simrand" val="0"/>')
    L.append('  </options>')
    L.append('  <mappings>')
    L.append('    <tool lib="8" map="Button2" name="Poke Tool"/>')
    L.append('    <tool lib="8" map="Button3" name="Menu Tool"/>')
    L.append('    <tool lib="8" map="Ctrl Button1" name="Menu Tool"/>')
    L.append('  </mappings>')
    L.append('  <toolbar>')
    L.append('    <tool lib="8" name="Poke Tool"/>')
    L.append('    <tool lib="8" name="Edit Tool"/>')
    L.append('    <tool lib="8" name="Wiring Tool"/>')
    L.append('    <tool lib="8" name="Text Tool"/>')
    L.append('    <sep/>')
    L.append('    <tool lib="0" name="Pin"/>')
    L.append('    <tool lib="0" name="Pin">')
    L.append('      <a name="facing" val="west"/>')
    L.append('      <a name="output" val="true"/>')
    L.append('    </tool>')
    L.append('    <sep/>')
    L.append('    <tool lib="1" name="NOT Gate"/>')
    L.append('    <tool lib="1" name="AND Gate"/>')
    L.append('    <tool lib="1" name="OR Gate"/>')
    L.append('    <tool lib="1" name="XOR Gate"/>')
    L.append('    <sep/>')
    L.append('    <tool lib="4" name="D Flip-Flop"/>')
    L.append('    <tool lib="4" name="Register"/>')
    L.append('  </toolbar>')
    L.append('  <circuit name="main">')
    L.append('    <a name="appearance" val="logisim_evolution"/>')
    L.append('    <a name="circuit" val="main"/>')
    L.append('    <a name="circuitnamedboxfixedsize" val="true"/>')
    L.append('    <a name="simulationFrequency" val="2.0"/>')

    # 元件定义
    L.append(f'    <comp lib="0" loc="({CLOCK["x"]},{CLOCK["y"]})" name="Clock">')
    L.append('      <a name="label" val="CLK"/>')
    L.append('    </comp>')
    L.append(f'    <comp lib="0" loc="({CONST0["x"]},{CONST0["y"]})" name="Constant">')
    L.append('      <a name="width" val="1"/>')
    L.append('    </comp>')
    L.append(f'    <comp lib="0" loc="({CONST1["x"]},{CONST1["y"]})" name="Constant">')
    L.append('      <a name="value" val="0x1"/>')
    L.append('      <a name="width" val="1"/>')
    L.append('    </comp>')
    for name, ff in [("D2", D2), ("D1", D1), ("D0", D0)]:
        L.append(f'    <comp lib="4" loc="({ff["x"]},{ff["y"]})" name="D Flip-Flop">')
        L.append(f'      <a name="label" val="{name}"/>')
        L.append('      <a name="appearance" val="logisim_evolution"/>')
        L.append('    </comp>')
    L.append(f'    <comp lib="1" loc="({XOR["x"]},{XOR["y"]})" name="XOR Gate"/>')
    for g in [NOT1, NOT2, NOT3]:
        L.append(f'    <comp lib="1" loc="({g["x"]},{g["y"]})" name="NOT Gate"/>')
    for g in [AND1, AND2, AND3, AND4]:
        L.append(f'    <comp lib="1" loc="({g["x"]},{g["y"]})" name="AND Gate"/>')
    L.append(f'    <comp lib="1" loc="({OR1["x"]},{OR1["y"]})" name="OR Gate"/>')
    L.append(f'    <comp lib="1" loc="({OR2["x"]},{OR2["y"]})" name="OR Gate"/>')
    for name, p in [("G2", G2), ("G1", G1), ("G0", G0)]:
        L.append(f'    <comp lib="0" loc="({p["x"]},{p["y"]})" name="Pin">')
        L.append('      <a name="appearance" val="NewPins"/>')
        L.append('      <a name="facing" val="west"/>')
        L.append(f'      <a name="label" val="{name}"/>')
        L.append('      <a name="output" val="true"/>')
        L.append('    </comp>')

    # 连线
    for (x1, y1), (x2, y2) in sorted(wires_unique):
        L.append(f'    <wire from="({x1},{y1})" to="({x2},{y2})"/>')

    L.append('  </circuit>')
    L.append('</project>')
    return '\n'.join(L) + '\n'

xml = gen()
with open(output_path, 'w', encoding='utf-8') as f:
    f.write(xml)

print(f"OK: {output_path}")
print(f"Wires: {len(wires_unique)}")
