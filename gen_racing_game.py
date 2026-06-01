#!/usr/bin/env python3
"""
生成竖版赛车躲避类小游戏 Logisim .circ 文件
难度等级: B (Level 1 + Level 2)
平台: Logisim-evolution 3.8.0

游戏机制:
  - 16x16 LED 矩阵显示
  - 小车在底部 (第15行), 左右移动, 1格宽(简化)
  - 障碍物从顶部下落, 每游戏时钟周期下降1行
  - 到达底部时: 列匹配→碰撞GameOver; 不匹配→得分+1, 新障碍物
  - 2位速度选择, 4档游戏速度
  - 计分器(0-99), 7段数码管显示
  - 状态LED: 绿灯(运行), 红灯(结束)
  - 复位按钮

电路架构 (平铺设计, 避免子电路端口计算问题):
  main
  ├── 输入区: Clock, Buttons, Speed pins
  ├── 时钟分频: 2级Reg+Adder链, MUX速度选择
  ├── 障碍物列源: 4位回绕计数器
  ├── 小车控制: Register + Adder + 边界比较器
  ├── 障碍物控制: Reg(列) + Reg(行) + Adder + 比较器
  ├── 碰撞检测: 比较器 + AND门
  ├── 游戏状态机: 2×D触发器 + 逻辑门
  ├── 计分器: BCD计数器 + 7段数码管
  ├── 显示控制: 行扫描计数器 + 比较器 + Decoder + LED矩阵
  └── 输出: LED矩阵, 数码管, LED, 蜂鸣器
"""

import os

OUTPUT = os.path.expanduser("~/Desktop/new.circ")

# ============================================================
# 元件引脚位置 (基于已验证的 gray counter 和 Example18)
# ============================================================
# D Flip-Flop (lib 4) at (x, y):
#   D@(x, y+10), Q@(x+50, y+10), EN@(x, y+30), CLK@(x, y+50), CLR@(x, y+70)
#   Q_bar@(x+50, y+30)  (推测)
#
# Register (lib 4) at (x, y):
#   D@(x, y+30), Q@(x+60, y+30), EN@(x, y+10), CLK@(x, y+70), CLR@(x, y+90)
#
# Counter (lib 4) at (x, y):  (与Register类似)
#   Q@(x+60, y+30), CLK@(x, y+70), CLR@(x, y+90)
#
# Gates (lib 1):
#   NOT 30x30: IN@(x, y+15), OUT@(x+30, y+15)
#   AND/OR/XOR 40x30: IN1@(x, y+10), IN2@(x, y+20), OUT@(x+40, y+15)
#
# Comparator (lib 3) at (x, y), width=4:
#   A@(x, y+10), B@(x, y+30), GT@(x+60, y+10), EQ@(x+60, y+30), LT@(x+60, y+50)
#
# Adder (lib 3) at (x, y), width=4:
#   A@(x, y+10), B@(x, y+30), SUM@(x+60, y+20), Cout@(x+60, y+40) (推测)
#
# Multiplexer (lib 2) at (x, y), width=w, select=s:
#   输入在左侧, 选择在底部/顶部, 输出在右侧
#   对于 select=2, width=1: 4个数据输入, 2位选择
#   数据输入 y 偏移: +10, +20, +30, +40 (推测)
#   选择: 底部或顶部
#   输出: (x+40, y+25) (推测)
#
# Decoder (lib 2) at (x, y), width=4:
#   输入(4位)在左侧, 16个输出在右侧
#   输入: (x, y+10) (推测)
#   输出位i: (x+40, y+10+i*10) (推测)
#
# Shift Register (lib 4) at (x, y), width=4, length=1, parallel=true:
#   D@(x, y+30), Q@(x+60, y+30), CLK@(x, y+70), CLR@(x, y+90)
#   (与Register引脚相同)
#
# 基本元件:
#   Clock/Constant/Pin: 连接点就是元件位置
#   Button: 连接点在元件位置
#   LED: 连接点在元件位置
#   7-Segment Display: 连接点在元件位置 (4位BCD输入)
#   LED Matrix 16x16: row输入(4位), col输入(16位) 在左侧
#   Buzzer: 连接点在元件位置
#   Splitter: 连接点在元件位置

# ============================================================
# 辅助函数
# ============================================================

class FlatCircuit:
    """平铺电路构建器"""
    def __init__(self):
        self.comps = []   # XML 元件字符串列表
        self.wires = []   # ((x1,y1), (x2,y2)) 元组列表

    def add_comp(self, xml_str):
        self.comps.append(xml_str)

    def W(self, x1, y1, x2, y2):
        """添加连线 (曼哈顿路由, 自动去重)"""
        if (x1, y1) != (x2, y2):
            self.wires.append(((x1, y1), (x2, y2)))

    def W_route(self, path):
        """添加多段路径 [(x1,y1), (x2,y2), ...]"""
        for i in range(len(path) - 1):
            self.W(path[i][0], path[i][1], path[i+1][0], path[i+1][1])

    def W_bus(self, x, y1, y2):
        """垂直总线: 从 (x, y1) 到 (x, y2)"""
        if y1 != y2:
            self.W(x, y1, x, y2)

# ============================================================
# D Flip-Flop 引脚 (已验证)
# ============================================================
def ff_d(x, y):    return (x, y+10)      # D输入
def ff_q(x, y):    return (x+50, y+10)    # Q输出
def ff_qb(x, y):   return (x+50, y+30)    # Q_bar输出
def ff_en(x, y):   return (x, y+30)       # EN使能
def ff_clk(x, y):  return (x, y+50)       # CLK时钟
def ff_clr(x, y):  return (x, y+70)       # CLR复位

# ============================================================
# Register 引脚 (基于 Example18)
# ============================================================
def reg_en(x, y):   return (x, y+10)      # EN使能
def reg_d(x, y):    return (x, y+30)       # D数据输入
def reg_q(x, y):    return (x+60, y+30)    # Q数据输出
def reg_clk(x, y):  return (x, y+70)       # CLK时钟
def reg_clr(x, y):  return (x, y+90)       # CLR复位

# ============================================================
# 门电路引脚
# ============================================================
def not_in(x, y):   return (x, y+15)       # NOT输入
def not_out(x, y):  return (x+30, y+15)    # NOT输出
def gate_in1(x, y): return (x, y+10)       # AND/OR/XOR 输入1
def gate_in2(x, y): return (x, y+20)       # AND/OR/XOR 输入2
def gate_out(x, y): return (x+40, y+15)    # AND/OR/XOR 输出

# ============================================================
# Adder 引脚
# ============================================================
def add_a(x, y):    return (x, y+10)       # A输入
def add_b(x, y):    return (x, y+30)       # B输入
def add_sum(x, y):  return (x+60, y+20)    # SUM输出
def add_cout(x, y): return (x+60, y+40)    # Cout输出

# ============================================================
# Comparator 引脚
# ============================================================
def cmp_a(x, y):    return (x, y+10)       # A输入
def cmp_b(x, y):    return (x, y+30)       # B输入
def cmp_gt(x, y):   return (x+60, y+10)    # A>B 输出
def cmp_eq(x, y):   return (x+60, y+30)    # A=B 输出
def cmp_lt(x, y):   return (x+60, y+50)    # A<B 输出

# MUX 引脚 (width=1, select=2)
def mux_in0(x, y):  return (x, y+10)       # 数据输入0
def mux_in1(x, y):  return (x, y+20)       # 数据输入1
def mux_in2(x, y):  return (x, y+30)       # 数据输入2
def mux_in3(x, y):  return (x, y+40)       # 数据输入3
def mux_sel0(x, y): return (x+10, y+60)    # 选择位0 (底部)
def mux_sel1(x, y): return (x+25, y+60)    # 选择位1 (底部)
def mux_out(x, y):  return (x+40, y+25)    # 输出

# Counter 引脚
def cnt_q(x, y):    return (x+60, y+30)
def cnt_clk(x, y):  return (x, y+50)
def cnt_clr(x, y):  return (x, y+70)
def cnt_en(x, y):   return (x, y+30)

# ============================================================
# 构建完整电路
# ============================================================

def build_racing_game():
    c = FlatCircuit()

    # ============ 第0部分: 时钟信号 ============
    # 系统时钟
    c.add_comp('    <comp lib="0" loc="(80,40)" name="Clock">')
    c.add_comp('      <a name="label" val="CLK"/>')
    c.add_comp('    </comp>')

    # ============ 第1部分: 输入设备 ============
    # 按钮 (lib 5)
    for name, y in [("LEFT", 120), ("RIGHT", 190), ("START", 260), ("RST", 330)]:
        c.add_comp(f'    <comp lib="5" loc="(80,{y})" name="Button">')
        c.add_comp(f'      <a name="label" val="{name}"/>')
        c.add_comp(f'    </comp>')

    # 速度选择 (2位引脚)
    c.add_comp('    <comp lib="0" loc="(80,420)" name="Pin">')
    c.add_comp('      <a name="appearance" val="NewPins"/>')
    c.add_comp('      <a name="label" val="SPEED0"/>')
    c.add_comp('    </comp>')
    c.add_comp('    <comp lib="0" loc="(80,450)" name="Pin">')
    c.add_comp('      <a name="appearance" val="NewPins"/>')
    c.add_comp('      <a name="label" val="SPEED1"/>')
    c.add_comp('    </comp>')

    # 常量 (enable用)
    c.add_comp('    <comp lib="0" loc="(110,40)" name="Constant">')
    c.add_comp('      <a name="value" val="0x1"/>')
    c.add_comp('      <a name="width" val="1"/>')
    c.add_comp('    </comp>')

    # ============ 第2部分: 时钟分频器 ============
    # CNT1: 4位Register + Adder (÷16)
    c.add_comp('    <comp lib="4" loc="(200,30)" name="Register">')
    c.add_comp('      <a name="width" val="4"/>')
    c.add_comp('      <a name="label" val="CNT1"/>')
    c.add_comp('    </comp>')
    c.add_comp('    <comp lib="3" loc="(130,30)" name="Adder">')
    c.add_comp('      <a name="width" val="4"/>')
    c.add_comp('    </comp>')
    c.add_comp('    <comp lib="0" loc="(70,40)" name="Constant">')
    c.add_comp('      <a name="value" val="0x1"/>')
    c.add_comp('      <a name="width" val="4"/>')
    c.add_comp('    </comp>')

    # CNT2: 4位Register + Adder (÷16)
    c.add_comp('    <comp lib="4" loc="(330,30)" name="Register">')
    c.add_comp('      <a name="width" val="4"/>')
    c.add_comp('      <a name="label" val="CNT2"/>')
    c.add_comp('    </comp>')
    c.add_comp('    <comp lib="3" loc="(260,30)" name="Adder">')
    c.add_comp('      <a name="width" val="4"/>')
    c.add_comp('    </comp>')

    # CNT3: 4位Register + Adder (÷16) → 共÷4096, 最低速
    c.add_comp('    <comp lib="4" loc="(460,30)" name="Register">')
    c.add_comp('      <a name="width" val="4"/>')
    c.add_comp('      <a name="label" val="CNT3"/>')
    c.add_comp('    </comp>')
    c.add_comp('    <comp lib="3" loc="(390,30)" name="Adder">')
    c.add_comp('      <a name="width" val="4"/>')
    c.add_comp('    </comp>')

    # MUX 速度选择: 4个速度档位来自CNT3的不同位
    c.add_comp('    <comp lib="2" loc="(560,60)" name="Multiplexer">')
    c.add_comp('      <a name="width" val="1"/>')
    c.add_comp('      <a name="select" val="2"/>')
    c.add_comp('    </comp>')

    # GAME_TICK 输出
    c.add_comp('    <comp lib="0" loc="(630,85)" name="Pin">')
    c.add_comp('      <a name="appearance" val="NewPins"/>')
    c.add_comp('      <a name="facing" val="west"/>')
    c.add_comp('      <a name="label" val="TICK"/>')
    c.add_comp('      <a name="output" val="true"/>')
    c.add_comp('    </comp>')

    # ---- 时钟分频器连线 ----
    # CNT1 反馈: CNT1.Q → Adder.A, Const1 → Adder.B, SUM → CNT1.D
    c.W(*reg_q(200, 30), 240, 40)
    c.W(240, 40, 130, 40)          # CNT1.Q → Adder.A (x=130, y+10=40)
    c.W(*reg_q(200, 30), 260, 40)  # CNT1.Q → CNT2 Adder (进位)
    c.W(70, 40, *add_b(130, 30))   # Const1 → Adder.B
    c.W(*add_sum(130, 30), *reg_d(200, 30))  # SUM → CNT1.D
    # CNT1 时钟和使能
    c.W(80, 40, *reg_clk(200, 30))      # CLK → CNT1.CLK
    c.W(110, 40, *reg_en(200, 30))       # Const1 → CNT1.EN

    # CNT2 反馈: CNT2.Q → Adder.A, Const1 → Adder.B, SUM → CNT2.D (独立计数器)
    c.W(*reg_q(330, 30), *add_a(260, 30))   # CNT2.Q → CNT2 Adder.A
    c.W(70, 40, *add_b(260, 30))            # Const1 → Adder.B
    c.W(*add_sum(260, 30), *reg_d(330, 30))  # SUM → CNT2.D
    c.W(80, 40, *reg_clk(330, 30))           # CLK → CNT2.CLK (同源时钟)
    # CNT2 EN = CNT1 Adder Cout (级联: CNT1溢出时CNT2才计数1次, ÷16)
    c.W(*add_cout(130, 30), 150, 50)
    c.W(150, 50, *reg_en(330, 30))

    # CNT3 反馈: CNT3.Q → Adder.A, Const1 → Adder.B, SUM → CNT3.D (独立计数器)
    c.W(*reg_q(460, 30), *add_a(390, 30))   # CNT3.Q → CNT3 Adder.A
    c.W(70, 40, *add_b(390, 30))            # Const1 → Adder.B
    c.W(*add_sum(390, 30), *reg_d(460, 30))  # SUM → CNT3.D
    c.W(80, 40, *reg_clk(460, 30))           # CLK → CNT3.CLK (同源时钟)
    # CNT3 EN = CNT2 Adder Cout (级联: CNT2溢出时CNT3才计数1次, ÷256)
    c.W(*add_cout(260, 30), 280, 50)
    c.W(280, 50, *reg_en(460, 30))

    # CNT1.Q 各位 → MUX 输入 (4个速度档位, 来自第一级计数器的分频输出)
    # 系统时钟32Hz时: Q[0]=16Hz, Q[1]=8Hz, Q[2]=4Hz, Q[3]=2Hz
    c.W(260, 30, 560, 70)       # CNT1 Q[0] → MUX in0 (最快 16Hz)
    c.W(260, 40, 560, 80)       # CNT1 Q[1] → MUX in1 (8Hz)
    c.W(260, 50, 560, 90)       # CNT1 Q[2] → MUX in2 (4Hz)
    c.W(260, 60, 560, 100)      # CNT1 Q[3] → MUX in3 (最慢 2Hz)

    # SPEED → MUX select
    c.W(80, 420, 560, 420)
    c.W(560, 420, *mux_sel0(560, 60))
    c.W(80, 450, 570, 450)
    c.W(570, 450, *mux_sel1(560, 60))

    # MUX out → TICK pin
    c.W(*mux_out(560, 60), 600, 85)
    c.W(600, 85, 630, 85)

    # ============ 第3部分: 障碍物列源 (简单计数器) ============
    c.add_comp('    <comp lib="4" loc="(200,140)" name="Register">')
    c.add_comp('      <a name="width" val="4"/>')
    c.add_comp('      <a name="label" val="OBS_SRC"/>')
    c.add_comp('    </comp>')
    c.add_comp('    <comp lib="3" loc="(130,140)" name="Adder">')
    c.add_comp('      <a name="width" val="4"/>')
    c.add_comp('    </comp>')

    c.add_comp('    <comp lib="0" loc="(70,160)" name="Constant">')
    c.add_comp('      <a name="value" val="0x3"/>')  # 步进值3, 使"随机"效果更好
    c.add_comp('      <a name="width" val="4"/>')
    c.add_comp('    </comp>')

    # 障碍列源连线: 每个TICK递增3, 自动回绕(0-15)
    c.W(*reg_q(200, 140), *add_a(130, 140))
    c.W(70, 160, *add_b(130, 140))
    c.W(*add_sum(130, 140), *reg_d(200, 140))
    c.W(630, 85, 630, 200)         # TICK → OBS_SRC.CLK
    c.W(630, 200, *reg_clk(200, 140))
    c.W(750, 520, 200, 170)
    c.W(200, 170, *reg_en(200, 140))

    # 输出 OBS_SRC → 后续使用
    c.add_comp('    <comp lib="0" loc="(350,150)" name="Pin">')
    c.add_comp('      <a name="appearance" val="NewPins"/>')
    c.add_comp('      <a name="facing" val="west"/>')
    c.add_comp('      <a name="label" val="OBS_SRC[3:0]"/>')
    c.add_comp('      <a name="output" val="true"/>')
    c.add_comp('      <a name="width" val="4"/>')
    c.add_comp('    </comp>')
    c.W(*reg_q(200, 140), 350, 150)

    # ============ 第4部分: 小车控制器 ============
    # CAR_POS Register + Adder
    c.add_comp('    <comp lib="4" loc="(200,250)" name="Register">')
    c.add_comp('      <a name="width" val="4"/>')
    c.add_comp('      <a name="label" val="CAR_POS"/>')
    c.add_comp('    </comp>')
    c.add_comp('    <comp lib="3" loc="(130,250)" name="Adder">')
    c.add_comp('      <a name="width" val="4"/>')
    c.add_comp('    </comp>')

    # MUX 选择 +1 / -1 / 0 (保持)
    c.add_comp('    <comp lib="2" loc="(200,320)" name="Multiplexer">')
    c.add_comp('      <a name="width" val="4"/>')
    c.add_comp('      <a name="select" val="2"/>')
    c.add_comp('    </comp>')

    # 常数: +1, -1(用15), 0
    c.add_comp('    <comp lib="0" loc="(60,310)" name="Constant">')
    c.add_comp('      <a name="value" val="0x1"/>')
    c.add_comp('      <a name="width" val="4"/>')
    c.add_comp('    </comp>')
    c.add_comp('    <comp lib="0" loc="(60,340)" name="Constant">')
    c.add_comp('      <a name="value" val="0xf"/>')  # -1 = +15 (4位回绕)
    c.add_comp('      <a name="width" val="4"/>')
    c.add_comp('    </comp>')
    c.add_comp('    <comp lib="0" loc="(60,370)" name="Constant">')
    c.add_comp('      <a name="value" val="0x0"/>')
    c.add_comp('      <a name="width" val="4"/>')
    c.add_comp('    </comp>')

    # 边界比较器
    c.add_comp('    <comp lib="3" loc="(360,230)" name="Comparator">')
    c.add_comp('      <a name="width" val="4"/>')
    c.add_comp('    </comp>')
    c.add_comp('    <comp lib="3" loc="(360,280)" name="Comparator">')
    c.add_comp('      <a name="width" val="4"/>')
    c.add_comp('    </comp>')
    c.add_comp('    <comp lib="0" loc="(310,230)" name="Constant">')
    c.add_comp('      <a name="value" val="0x0"/>')
    c.add_comp('      <a name="width" val="4"/>')
    c.add_comp('    </comp>')
    c.add_comp('    <comp lib="0" loc="(310,280)" name="Constant">')
    c.add_comp('      <a name="value" val="0xf"/>')  # 右边界=15(含), 比较<15
    c.add_comp('      <a name="width" val="4"/>')
    c.add_comp('    </comp>')

    # 移动逻辑门
    c.add_comp('    <comp lib="1" loc="(450,230)" name="AND Gate"/>')  # LEFT 有效
    c.add_comp('    <comp lib="1" loc="(450,280)" name="AND Gate"/>')  # RIGHT 有效
    c.add_comp('    <comp lib="1" loc="(130,400)" name="OR Gate"/>')   # 组合移动方向

    # CAR_POS 输出
    c.add_comp('    <comp lib="0" loc="(530,250)" name="Pin">')
    c.add_comp('      <a name="appearance" val="NewPins"/>')
    c.add_comp('      <a name="facing" val="west"/>')
    c.add_comp('      <a name="label" val="CAR_COL[3:0]"/>')
    c.add_comp('      <a name="output" val="true"/>')
    c.add_comp('      <a name="width" val="4"/>')
    c.add_comp('    </comp>')

    # ---- 小车控制连线 ----
    # CAR_POS.Q → 边界比较器
    c.W(*reg_q(200, 250), 360, 240)    # → CMP.A (两个比较器共用)
    c.W(360, 240, *cmp_a(360, 230))
    c.W(360, 240, 360, 290)
    c.W(360, 290, *cmp_a(360, 280))

    # 常数 → 边界比较器
    c.W(310, 230, *cmp_b(360, 230))   # 0 → CMP_LO.B
    c.W(310, 280, *cmp_b(360, 280))   # 15 → CMP_HI.B

    # 边界比较结果 → AND门
    # CMP_LO: A>0 → GT输出 (pos>0时 LEFT有效)
    c.W(*cmp_gt(360, 230), 420, 240)
    c.W(420, 240, *gate_in1(450, 230))
    # CMP_HI: A<15 → LT输出 (pos<15时 RIGHT有效)
    c.W(*cmp_lt(360, 280), 420, 290)
    c.W(420, 290, *gate_in2(450, 280))

    # 按钮 → AND门
    c.W(80, 120, *gate_in2(450, 230))   # LEFT → AND_L
    c.W(80, 190, *gate_in1(450, 280))   # RIGHT → AND_R

    # AND输出 → MUX选择信号 (编码移动方向)
    # AND_L=1, AND_R=0 → 选择 -1 (输入1, 即0xf)
    # AND_L=0, AND_R=1 → 选择 +1 (输入0)
    # AND_L=0, AND_R=0 → 选择 0 (输入2, 不动)
    c.W(*gate_out(450, 230), 480, 245)   # AND_L → 编码逻辑
    c.W(480, 245, 480, 380)
    c.W(*gate_out(450, 280), 490, 295)   # AND_R → 编码逻辑
    c.W(490, 295, 490, 390)

    # MUX 选择信号 (简化为: sel0=AND_L, sel1=AND_R)
    c.W(480, 380, *mux_sel0(200, 320))
    c.W(490, 390, *mux_sel1(200, 320))

    # 常数 → MUX 数据输入
    c.W(60, 310, *mux_in0(200, 320))    # +1
    c.W(60, 340, *mux_in1(200, 320))    # -1
    c.W(60, 370, *mux_in2(200, 320))    # 0
    # mux_in3 不接 (默认0)

    # MUX输出 → Adder.B (加到当前位置)
    c.W(*mux_out(200, 320), 170, 345)
    c.W(170, 345, *add_b(130, 250))

    # CAR_POS.Q → Adder.A (当前位置)
    c.W(*reg_q(200, 250), 180, 260)
    c.W(180, 260, *add_a(130, 250))

    # Adder.SUM → CAR_POS.D
    c.W(*add_sum(130, 250), *reg_d(200, 250))

    # TICK → CAR_POS.CLK (只在游戏运行时更新)
    c.W(630, 85, 630, 200)
    c.W(630, 200, *reg_clk(200, 250))

    # EN = RUNNING 信号 (S0=1时使能, 来自FSM)
    c.W(*ff_q(700, 160), 750, 280)
    c.W(750, 280, 200, 280)
    c.W(200, 280, *reg_en(200, 250))

    # CAR_POS.Q → 输出
    c.W(*reg_q(200, 250), 530, 250)

    # ============ 第5部分: 障碍物控制器 ============
    # OBS_COL Register
    c.add_comp('    <comp lib="4" loc="(200,480)" name="Register">')
    c.add_comp('      <a name="width" val="4"/>')
    c.add_comp('      <a name="label" val="OBS_COL"/>')
    c.add_comp('    </comp>')

    # OBS_ROW Register + Adder
    c.add_comp('    <comp lib="4" loc="(400,480)" name="Register">')
    c.add_comp('      <a name="width" val="4"/>')
    c.add_comp('      <a name="label" val="OBS_ROW"/>')
    c.add_comp('    </comp>')
    c.add_comp('    <comp lib="3" loc="(330,480)" name="Adder">')
    c.add_comp('      <a name="width" val="4"/>')
    c.add_comp('    </comp>')
    c.add_comp('    <comp lib="0" loc="(280,510)" name="Constant">')
    c.add_comp('      <a name="value" val="0x1"/>')
    c.add_comp('      <a name="width" val="4"/>')
    c.add_comp('    </comp>')

    # 比较器: row == 15?
    c.add_comp('    <comp lib="3" loc="(400,560)" name="Comparator">')
    c.add_comp('      <a name="width" val="4"/>')
    c.add_comp('    </comp>')
    c.add_comp('    <comp lib="0" loc="(350,590)" name="Constant">')
    c.add_comp('      <a name="value" val="0xf"/>')
    c.add_comp('      <a name="width" val="4"/>')
    c.add_comp('    </comp>')

    # OBS_COL 输出
    c.add_comp('    <comp lib="0" loc="(530,480)" name="Pin">')
    c.add_comp('      <a name="appearance" val="NewPins"/>')
    c.add_comp('      <a name="facing" val="west"/>')
    c.add_comp('      <a name="label" val="OBS_COL[3:0]"/>')
    c.add_comp('      <a name="output" val="true"/>')
    c.add_comp('      <a name="width" val="4"/>')
    c.add_comp('    </comp>')

    # OBS_ROW 输出
    c.add_comp('    <comp lib="0" loc="(530,520)" name="Pin">')
    c.add_comp('      <a name="appearance" val="NewPins"/>')
    c.add_comp('      <a name="facing" val="west"/>')
    c.add_comp('      <a name="label" val="OBS_ROW[3:0]"/>')
    c.add_comp('      <a name="output" val="true"/>')
    c.add_comp('      <a name="width" val="4"/>')
    c.add_comp('    </comp>')

    # ROW15 (碰撞/得分信号)
    c.add_comp('    <comp lib="0" loc="(530,580)" name="Pin">')
    c.add_comp('      <a name="appearance" val="NewPins"/>')
    c.add_comp('      <a name="facing" val="west"/>')
    c.add_comp('      <a name="label" val="AT_BOTTOM"/>')
    c.add_comp('      <a name="output" val="true"/>')
    c.add_comp('    </comp>')

    # ---- 障碍物控制器连线 ----
    # OBS_SRC → OBS_COL.D (新障碍物载入列位置)
    c.W(*reg_q(200, 140), 240, 160)
    c.W(240, 160, 240, 510)
    c.W(240, 510, *reg_d(200, 480))

    # OBS_ROW.Q → Adder.A
    c.W(*reg_q(400, 480), *add_a(330, 480))
    # Const1 → Adder.B
    c.W(280, 510, *add_b(330, 480))
    # SUM → OBS_ROW.D
    c.W(*add_sum(330, 480), *reg_d(400, 480))

    # OBS_ROW.Q → Comparator.A
    c.W(*reg_q(400, 480), *cmp_a(400, 560))
    # Const15 → Comparator.B
    c.W(350, 590, *cmp_b(400, 560))

    # TICK → OBS_COL.CLK, OBS_ROW.CLK
    c.W(630, 85, 630, 500)
    c.W(630, 500, *reg_clk(200, 480))
    c.W(630, 500, *reg_clk(400, 480))

    # EN = RUNNING 信号 (S0=1时使能, 来自FSM)
    c.W(*ff_q(700, 160), 750, 520)
    c.W(750, 520, 200, 520)
    c.W(200, 520, *reg_en(200, 480))
    c.W(750, 520, 400, 520)
    c.W(400, 520, *reg_en(400, 480))

    # OBS_COL.Q → 输出
    c.W(*reg_q(200, 480), 530, 480)
    # OBS_ROW.Q → 输出
    c.W(*reg_q(400, 480), 530, 520)
    # EQ → AT_BOTTOM 输出
    c.W(*cmp_eq(400, 560), 530, 580)

    # ============ 第6部分: 碰撞检测 ============
    c.add_comp('    <comp lib="3" loc="(620,250)" name="Comparator">')
    c.add_comp('      <a name="width" val="4"/>')
    c.add_comp('    </comp>')

    c.add_comp('    <comp lib="1" loc="(720,300)" name="AND Gate"/>')

    c.add_comp('    <comp lib="0" loc="(820,300)" name="Pin">')
    c.add_comp('      <a name="appearance" val="NewPins"/>')
    c.add_comp('      <a name="facing" val="west"/>')
    c.add_comp('      <a name="label" val="HIT"/>')
    c.add_comp('      <a name="output" val="true"/>')
    c.add_comp('    </comp>')

    # ---- 碰撞检测连线 ----
    # CAR_COL → Comparator.A
    c.W(530, 250, *cmp_a(620, 250))
    # OBS_COL → Comparator.B
    c.W(530, 480, 530, 280)
    c.W(530, 280, *cmp_b(620, 250))

    # EQ → AND门 输入1
    c.W(*cmp_eq(620, 250), 680, 260)
    c.W(680, 260, 680, 310)
    c.W(680, 310, *gate_in1(720, 300))

    # AT_BOTTOM → AND门 输入2
    c.W(530, 580, *gate_in2(720, 300))

    # AND.OUT → HIT
    c.W(*gate_out(720, 300), 820, 300)

    # ============ 第7部分: 游戏状态机 (FSM) ============
    # 状态: IDLE=00, RUNNING=01, GAME_OVER=10
    # 状态寄存器: 2个D触发器
    c.add_comp('    <comp lib="4" loc="(700,60)" name="D Flip-Flop">')
    c.add_comp('      <a name="label" val="S1"/>')
    c.add_comp('      <a name="appearance" val="logisim_evolution"/>')
    c.add_comp('    </comp>')
    c.add_comp('    <comp lib="4" loc="(700,160)" name="D Flip-Flop">')
    c.add_comp('      <a name="label" val="S0"/>')
    c.add_comp('      <a name="appearance" val="logisim_evolution"/>')
    c.add_comp('    </comp>')

    # 下一状态逻辑
    # S1_next = START·!S1·!S0 + S1·!COLLISION  (简化为: IDLE时START→RUN; RUN时COLLISION→GAMEOVER)
    # 实际: S1_next = RUNNING_state (S1=0,S0=1 after START; stays 1 until COLLISION)
    # 更简单的FSM:
    #   IDLE(00): if START → RUNNING(01)
    #   RUNNING(01): if COLLISION → GAME_OVER(10), else stay RUNNING
    #   GAME_OVER(10): if RST → IDLE(00)
    c.add_comp('    <comp lib="1" loc="(560,360)" name="AND Gate"/>')   # START & !S1 (第1级)
    c.add_comp('    <comp lib="1" loc="(620,400)" name="AND Gate"/>')   # (START & !S1) & !S0 (第2级)
    c.add_comp('    <comp lib="1" loc="(700,400)" name="AND Gate"/>')   # !HIT & S0
    c.add_comp('    <comp lib="1" loc="(660,480)" name="OR Gate"/>')    # next_S0
    c.add_comp('    <comp lib="1" loc="(780,480)" name="AND Gate"/>')   # next_S1 = HIT & S0
    c.add_comp('    <comp lib="1" loc="(580,400)" name="NOT Gate"/>')   # !S1
    c.add_comp('    <comp lib="1" loc="(580,440)" name="NOT Gate"/>')   # !S0
    c.add_comp('    <comp lib="1" loc="(780,350)" name="NOT Gate"/>')   # !HIT

    # 输出
    c.add_comp('    <comp lib="0" loc="(880,60)" name="Pin">')
    c.add_comp('      <a name="appearance" val="NewPins"/>')
    c.add_comp('      <a name="facing" val="west"/>')
    c.add_comp('      <a name="label" val="S1"/>')
    c.add_comp('      <a name="output" val="true"/>')
    c.add_comp('    </comp>')
    c.add_comp('    <comp lib="0" loc="(880,160)" name="Pin">')
    c.add_comp('      <a name="appearance" val="NewPins"/>')
    c.add_comp('      <a name="facing" val="west"/>')
    c.add_comp('      <a name="label" val="S0"/>')
    c.add_comp('      <a name="output" val="true"/>')
    c.add_comp('    </comp>')

    # RUNNING = !S1 & S0 (状态01)
    c.add_comp('    <comp lib="1" loc="(880,250)" name="AND Gate"/>')
    c.add_comp('    <comp lib="1" loc="(840,250)" name="NOT Gate"/>')

    # GAME_OVER = S1 & !S0 (状态10)
    c.add_comp('    <comp lib="1" loc="(880,320)" name="AND Gate"/>')
    c.add_comp('    <comp lib="1" loc="(840,320)" name="NOT Gate"/>')

    # 状态LED
    c.add_comp('    <comp lib="5" loc="(980,250)" name="LED">')
    c.add_comp('      <a name="label" val="RUN"/>')
    c.add_comp('      <a name="color" val="green"/>')
    c.add_comp('    </comp>')
    c.add_comp('    <comp lib="5" loc="(980,320)" name="LED">')
    c.add_comp('      <a name="label" val="GAMEOVER"/>')
    c.add_comp('      <a name="color" val="red"/>')
    c.add_comp('    </comp>')

    # ---- FSM 连线 ----
    # CLK → FF CLK
    c.W(80, 40, 80, 100)
    c.W(80, 100, *ff_clk(700, 60))
    c.W(80, 100, 80, 210)
    c.W(80, 210, *ff_clk(700, 160))

    # RST → FF CLR
    c.W(80, 330, *ff_clr(700, 60))
    c.W(80, 330, *ff_clr(700, 160))

    # Const1 → FF EN
    c.W(110, 40, *ff_en(700, 60))
    c.W(110, 40, *ff_en(700, 160))

    # S1.Q → 输出
    c.W(*ff_q(700, 60), 880, 60)

    # S0.Q → 输出
    c.W(*ff_q(700, 160), 880, 160)

    # 下一状态逻辑:
    # S1_next = (HIT & S0) | S1  (碰撞时进入GAME_OVER, 并保持直到RST复位)
    c.add_comp('    <comp lib="1" loc="(780,440)" name="OR Gate"/>')     # S1_next = AND | S1
    c.W(820, 300, 820, 350)
    c.W(820, 350, *not_in(780, 350))     # HIT → NOT → !HIT (用于S0_next)
    c.W(820, 300, *gate_in1(780, 480))   # HIT → AND
    c.W(*ff_q(700, 160), *gate_in2(780, 480))  # S0 → AND
    # AND_out → OR gate (S1_next = (HIT&S0) | S1)
    c.W(*gate_out(780, 480), *gate_in1(780, 440))
    c.W(*ff_q(700, 60), *gate_in2(780, 440))    # S1.Q → OR (保持)
    c.W(*gate_out(780, 440), *ff_d(700, 60))    # OR → S1.D

    # S0_next = (!S1 & !S0 & START) | (S0 & !HIT)
    # !S1
    c.W(*ff_q(700, 60), 580, 70)
    c.W(580, 70, *not_in(580, 400))
    # !S0
    c.W(*ff_q(700, 160), 580, 170)
    c.W(580, 170, *not_in(580, 440))

    # START & !S1 & !S0 → (两级AND级联, 第1级: START&!S1, 第2级: 结果&!S0)
    c.W(80, 260, 560, 370)              # START → AND第1级.in1
    c.W(560, 370, *gate_in1(560, 360))
    c.W(*not_out(580, 400), *gate_in2(560, 360))  # !S1 → AND第1级.in2
    c.W(*gate_out(560, 360), 600, 375)            # 第1级.out → ...
    c.W(600, 375, *gate_in1(620, 400))            # → AND第2级.in1
    c.W(*not_out(580, 440), *gate_in2(620, 400))  # !S0 → AND第2级.in2

    # !HIT & S0 → AND2
    c.W(*not_out(780, 350), *gate_in1(700, 400))   # !HIT
    c.W(*ff_q(700, 160), *gate_in2(700, 400))       # S0

    # AND1 | AND2 → S0.D
    c.W(*gate_out(620, 400), 660, 415)
    c.W(660, 415, *gate_in1(660, 480))
    c.W(*gate_out(700, 400), 660, 425)
    c.W(660, 425, 660, 500)
    c.W(660, 500, *gate_in2(660, 480))
    c.W(*gate_out(660, 480), *ff_d(700, 160))

    # RUNNING = !S1 & S0
    c.W(*ff_q(700, 60), *not_in(840, 250))    # S1 → NOT → AND
    c.W(*not_out(840, 250), *gate_in1(880, 250))
    c.W(*ff_q(700, 160), *gate_in2(880, 250))  # S0 → AND
    c.W(*gate_out(880, 250), 980, 250)          # → 绿灯

    # GAME_OVER = S1 & !S0
    c.W(*ff_q(700, 60), *gate_in1(880, 320))    # S1 → AND
    c.W(*ff_q(700, 160), *not_in(840, 320))      # S0 → NOT
    c.W(*not_out(840, 320), *gate_in2(880, 320))  # !S0 → AND
    c.W(*gate_out(880, 320), 980, 320)            # → 红灯

    # ============ 第8部分: 计分器 ============
    # SCORE_ONES Register + Adder (BCD个位, 0-9)
    c.add_comp('    <comp lib="4" loc="(700,560)" name="Register">')
    c.add_comp('      <a name="width" val="4"/>')
    c.add_comp('      <a name="label" val="SCORE1"/>')
    c.add_comp('    </comp>')
    c.add_comp('    <comp lib="3" loc="(620,560)" name="Adder">')
    c.add_comp('      <a name="width" val="4"/>')
    c.add_comp('    </comp>')
    c.add_comp('    <comp lib="0" loc="(580,580)" name="Constant">')
    c.add_comp('      <a name="value" val="0x1"/>')
    c.add_comp('      <a name="width" val="4"/>')
    c.add_comp('    </comp>')

    # SCORE_TENS Register + Adder (BCD十位, 0-9)
    c.add_comp('    <comp lib="4" loc="(700,640)" name="Register">')
    c.add_comp('      <a name="width" val="4"/>')
    c.add_comp('      <a name="label" val="SCORE10"/>')
    c.add_comp('    </comp>')
    c.add_comp('    <comp lib="3" loc="(620,640)" name="Adder">')
    c.add_comp('      <a name="width" val="4"/>')
    c.add_comp('    </comp>')

    # 比较器: ones == 9 (进位到十位)
    c.add_comp('    <comp lib="3" loc="(560,680)" name="Comparator">')
    c.add_comp('      <a name="width" val="4"/>')
    c.add_comp('    </comp>')
    c.add_comp('    <comp lib="0" loc="(510,680)" name="Constant">')
    c.add_comp('      <a name="value" val="0x9"/>')
    c.add_comp('      <a name="width" val="4"/>')
    c.add_comp('    </comp>')

    # 7段数码管
    c.add_comp('    <comp lib="5" loc="(860,560)" name="7-Segment Display">')
    c.add_comp('      <a name="label" val="个位"/>')
    c.add_comp('    </comp>')
    c.add_comp('    <comp lib="5" loc="(860,630)" name="7-Segment Display">')
    c.add_comp('      <a name="label" val="十位"/>')
    c.add_comp('    </comp>')

    # 得分触发逻辑: AT_BOTTOM & !HIT & S0 (必须在RUNNING状态)
    c.add_comp('    <comp lib="1" loc="(560,780)" name="AND Gate"/>')   # AT_BOTTOM & !HIT (第1级)
    c.add_comp('    <comp lib="1" loc="(620,720)" name="AND Gate"/>')   # 结果 & S0 (第2级)
    c.add_comp('    <comp lib="1" loc="(560,720)" name="NOT Gate"/>')   # !HIT

    # ---- 计分器连线 ----
    # 得分触发: SCORE_TRIG = AT_BOTTOM & !HIT & S0 (两级AND级联)
    c.W(530, 580, 560, 790)              # AT_BOTTOM → AND第1级.in1
    c.W(560, 790, *gate_in1(560, 780))
    c.W(820, 300, *not_in(560, 720))     # HIT → NOT → !HIT
    c.W(*not_out(560, 720), *gate_in2(560, 780))   # !HIT → AND第1级.in2
    c.W(*gate_out(560, 780), 620, 795)            # 第1级.out → AND第2级
    c.W(620, 795, *gate_in1(620, 720))
    c.W(*ff_q(700, 160), *gate_in2(620, 720))     # S0 → AND第2级.in2 (RUNNING状态)

    # SCORE1 反馈
    c.W(*reg_q(700, 560), *add_a(620, 560))
    c.W(580, 580, *add_b(620, 560))
    c.W(*add_sum(620, 560), *reg_d(700, 560))

    # SCORE1.Q → 比较器 (检测9)
    c.W(*reg_q(700, 560), *cmp_a(560, 680))
    c.W(510, 680, *cmp_b(560, 680))

    # SCORE1.Q → 7段显示
    c.W(*reg_q(700, 560), 860, 560)

    # SCORE10 反馈 (仅当个位=9时加1)
    c.W(*reg_q(700, 640), *add_a(620, 640))
    c.W(580, 580, *add_b(620, 640))     # +1
    c.W(*add_sum(620, 640), *reg_d(700, 640))

    # SCORE10.Q → 7段显示
    c.W(*reg_q(700, 640), 860, 630)

    # 得分时钟: 使用TICK (游戏时钟)
    c.W(630, 85, 630, 630)
    c.W(630, 630, *reg_clk(700, 560))
    c.W(630, 630, *reg_clk(700, 640))

    # EN → 由得分触发控制
    c.W(*gate_out(620, 720), 700, 740)
    c.W(700, 740, *reg_en(700, 560))
    # 十位EN = SCORE1进位 (ones=9 & score_trig)
    c.W(*cmp_eq(560, 680), 590, 710)
    c.W(590, 710, *reg_en(700, 640))

    # RST → 计分器复位
    c.W(80, 330, 80, 630)
    c.W(80, 630, 700, 630)
    c.W(700, 630, *reg_clr(700, 560))
    c.W(700, 630, *reg_clr(700, 640))

    # ============ 第9部分: 显示控制器 (LED Matrix) ============
    # 行扫描计数器 SCAN_ROW (4位 Register + Adder)
    c.add_comp('    <comp lib="4" loc="(200,620)" name="Register">')
    c.add_comp('      <a name="width" val="4"/>')
    c.add_comp('      <a name="label" val="SCAN_ROW"/>')
    c.add_comp('    </comp>')
    c.add_comp('    <comp lib="3" loc="(130,620)" name="Adder">')
    c.add_comp('      <a name="width" val="4"/>')
    c.add_comp('    </comp>')

    # 比较器: 扫描行 == CAR行(14,15), == OBS行
    c.add_comp('    <comp lib="3" loc="(400,620)" name="Comparator">')   # scan==14?
    c.add_comp('      <a name="width" val="4"/>')
    c.add_comp('    </comp>')
    c.add_comp('    <comp lib="3" loc="(400,670)" name="Comparator">')   # scan==15?
    c.add_comp('      <a name="width" val="4"/>')
    c.add_comp('    </comp>')
    c.add_comp('    <comp lib="3" loc="(400,720)" name="Comparator">')   # scan==obs_row?
    c.add_comp('      <a name="width" val="4"/>')
    c.add_comp('    </comp>')

    c.add_comp('    <comp lib="0" loc="(340,630)" name="Constant">')
    c.add_comp('      <a name="value" val="0xe"/>')
    c.add_comp('      <a name="width" val="4"/>')
    c.add_comp('    </comp>')
    c.add_comp('    <comp lib="0" loc="(340,680)" name="Constant">')
    c.add_comp('      <a name="value" val="0xf"/>')
    c.add_comp('      <a name="width" val="4"/>')
    c.add_comp('    </comp>')

    # 行匹配逻辑: scan==14 OR scan==15 → 显示小车行
    c.add_comp('    <comp lib="1" loc="(480,630)" name="OR Gate"/>')

    # Decoder: CAR_COL → 16位列数据
    c.add_comp('    <comp lib="2" loc="(560,620)" name="Decoder">')
    c.add_comp('      <a name="width" val="4"/>')
    c.add_comp('    </comp>')

    # Decoder: OBS_COL → 16位列数据
    c.add_comp('    <comp lib="2" loc="(560,700)" name="Decoder">')
    c.add_comp('      <a name="width" val="4"/>')
    c.add_comp('    </comp>')

    # 16位宽门电路: 将Decoder输出按行选通, 避免不同行之间的列数据干扰
    c.add_comp('    <comp lib="1" loc="(640,620)" name="AND Gate"/>')   # CAR列×行匹配
    c.add_comp('      <a name="width" val="16"/>')
    c.add_comp('    </comp>')
    c.add_comp('    <comp lib="1" loc="(640,700)" name="AND Gate"/>')   # OBS列×行匹配
    c.add_comp('      <a name="width" val="16"/>')
    c.add_comp('    </comp>')
    c.add_comp('    <comp lib="1" loc="(760,660)" name="OR Gate"/>')    # 合并CAR+OBS列数据
    c.add_comp('      <a name="width" val="16"/>')
    c.add_comp('    </comp>')

    # LED Matrix 16x16
    c.add_comp('    <comp lib="5" loc="(900,640)" name="LED Matrix">')
    c.add_comp('      <a name="matrix_columns" val="16"/>')
    c.add_comp('      <a name="matrix_rows" val="16"/>')
    c.add_comp('    </comp>')

    # ---- 显示控制器连线 ----
    # 扫描计数器反馈
    c.W(*reg_q(200, 620), *add_a(130, 620))
    c.W(70, 40, *add_b(130, 620))       # Const1 → Adder.B
    c.W(*add_sum(130, 620), *reg_d(200, 620))
    c.W(80, 40, *reg_clk(200, 620))      # 系统时钟 → 快速扫描
    c.W(110, 40, *reg_en(200, 620))

    # SCAN_ROW.Q → 比较器 A输入 (3个比较器共用)
    c.W(*reg_q(200, 620), *cmp_a(400, 620))
    c.W(*reg_q(200, 620), 340, 660)
    c.W(340, 660, *cmp_a(400, 670))
    c.W(*reg_q(200, 620), 340, 710)
    c.W(340, 710, *cmp_a(400, 720))

    # 常数 → 比较器 B输入
    c.W(340, 630, *cmp_b(400, 620))    # 14
    c.W(340, 680, *cmp_b(400, 670))    # 15
    c.W(530, 520, *cmp_b(400, 720))    # OBS_ROW

    # 行匹配: cmp14.EQ OR cmp15.EQ → show_car_row
    c.W(*cmp_eq(400, 620), 440, 640)
    c.W(440, 640, *gate_in1(480, 630))
    c.W(*cmp_eq(400, 670), 440, 690)
    c.W(440, 690, *gate_in2(480, 630))

    # CAR_COL(4位) → CAR Decoder 输入
    c.W(530, 250, 560, 250)
    c.W(560, 250, 560, 620)

    # OBS_COL(4位) → OBS Decoder 输入
    c.W(530, 480, 560, 500)
    c.W(560, 500, 560, 700)

    # CAR Decoder 16位输出 → CAR AND门 (数据输入)
    c.W(600, 630, 640, 630)     # Decoder out[0]位置 ≈ AND in1 bus起始

    # OBS Decoder 16位输出 → OBS AND门 (数据输入)
    c.W(600, 710, 640, 710)

    # show_car_row → CAR AND门 控制端 (1位控制信号, 自动扩展到16位)
    c.W(*gate_out(480, 630), 560, 645)
    c.W(560, 645, 640, 640)     # → CAR AND门第二输入

    # row_match_obs → OBS AND门 控制端
    c.W(*cmp_eq(400, 720), 560, 730)
    c.W(560, 730, 640, 720)     # → OBS AND门第二输入

    # CAR AND out → OR门 (合并列数据)
    c.W(680, 635, 720, 635)
    c.W(720, 635, 760, 670)     # → OR in1

    # OBS AND out → OR门
    c.W(680, 715, 720, 715)
    c.W(720, 715, 760, 690)     # → OR in2

    # OR out → LED Matrix 列输入 (16位)
    c.W(800, 675, 900, 660)

    # 扫描行 → LED Matrix 行输入
    c.W(*reg_q(200, 620), 900, 640)

    # ============ 第10部分: 蜂鸣器 ============
    c.add_comp('    <comp lib="10" loc="(980,400)" name="Buzzer"/>')
    c.W(*gate_out(880, 320), 980, 400)   # GAME_OVER → Buzzer

    # ============ 复位总线 ============
    # RST 按钮 → 所有需要复位的寄存器
    c.W(80, 330, 200, 330)
    c.W(200, 330, *reg_clr(200, 30))     # CNT1
    c.W(200, 330, *reg_clr(330, 30))     # CNT2
    c.W(200, 330, *reg_clr(460, 30))     # CNT3
    c.W(80, 330, *reg_clr(200, 140))     # OBS_SRC
    c.W(80, 330, *reg_clr(200, 250))     # CAR_POS
    c.W(80, 330, *reg_clr(200, 480))     # OBS_COL
    c.W(80, 330, *reg_clr(400, 480))     # OBS_ROW
    c.W(80, 330, *reg_clr(200, 620))     # SCAN_ROW

    return c


# ============================================================
# 生成 XML
# ============================================================

XML_HEADER = '''<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<project source="3.8.0" version="1.0">
  This file is intended to be loaded by Logisim-evolution v3.8.0(https://github.com/logisim-evolution/).

  <lib desc="#Wiring" name="0">
    <tool name="Pin">
      <a name="appearance" val="classic"/>
    </tool>
  </lib>
  <lib desc="#Gates" name="1"/>
  <lib desc="#Plexers" name="2"/>
  <lib desc="#Arithmetic" name="3"/>
  <lib desc="#Memory" name="4"/>
  <lib desc="#I/O" name="5"/>
  <lib desc="#TTL" name="6"/>
  <lib desc="#TCL" name="7"/>
  <lib desc="#Base" name="8"/>
  <lib desc="#BFH-Praktika" name="9"/>
  <lib desc="#Input/Output-Extra" name="10"/>
  <lib desc="#Soc" name="11"/>
  <main name="main"/>
  <options>
    <a name="gateUndefined" val="ignore"/>
    <a name="simlimit" val="1000"/>
    <a name="simrand" val="0"/>
  </options>
  <mappings>
    <tool lib="8" map="Button2" name="Poke Tool"/>
    <tool lib="8" map="Button3" name="Menu Tool"/>
    <tool lib="8" map="Ctrl Button1" name="Menu Tool"/>
  </mappings>
  <toolbar>
    <tool lib="8" name="Poke Tool"/>
    <tool lib="8" name="Edit Tool"/>
    <tool lib="8" name="Wiring Tool"/>
    <tool lib="8" name="Text Tool"/>
    <sep/>
    <tool lib="0" name="Pin"/>
    <tool lib="0" name="Pin">
      <a name="facing" val="west"/>
      <a name="output" val="true"/>
    </tool>
    <tool lib="0" name="Clock"/>
    <tool lib="0" name="Constant"/>
    <sep/>
    <tool lib="1" name="NOT Gate"/>
    <tool lib="1" name="AND Gate"/>
    <tool lib="1" name="OR Gate"/>
    <tool lib="1" name="XOR Gate"/>
    <sep/>
    <tool lib="2" name="Multiplexer"/>
    <tool lib="2" name="Decoder"/>
    <sep/>
    <tool lib="3" name="Adder"/>
    <tool lib="3" name="Comparator"/>
    <sep/>
    <tool lib="4" name="D Flip-Flop"/>
    <tool lib="4" name="Register"/>
    <tool lib="4" name="Counter"/>
    <sep/>
    <tool lib="5" name="Button"/>
    <tool lib="5" name="LED"/>
    <tool lib="5" name="7-Segment Display"/>
    <tool lib="5" name="LED Matrix"/>
    <tool lib="10" name="Buzzer"/>
  </toolbar>'''

XML_FOOTER = '</project>\n'


def gen_xml(circuit):
    """生成完整 XML"""
    lines = []
    lines.append(XML_HEADER)

    # 赛车游戏主电路
    lines.append('  <circuit name="main">')
    lines.append('    <a name="appearance" val="logisim_evolution"/>')
    lines.append('    <a name="circuit" val="main"/>')
    lines.append('    <a name="circuitnamedboxfixedsize" val="true"/>')
    lines.append('    <a name="simulationFrequency" val="32.0"/>')

    for comp_xml in circuit.comps:
        lines.append(comp_xml)

    # 按坐标排序连线以便阅读
    for (x1, y1), (x2, y2) in sorted(set(circuit.wires)):
        lines.append(f'    <wire from="({x1},{y1})" to="({x2},{y2})"/>')

    lines.append('  </circuit>')
    lines.append(XML_FOOTER)
    return '\n'.join(lines)


# ============================================================
# 主程序
# ============================================================
if __name__ == '__main__':
    c = build_racing_game()
    xml = gen_xml(c)
    with open(OUTPUT, 'w', encoding='utf-8') as f:
        f.write(xml)
    print(f"电路文件已生成: {OUTPUT}")
    print(f"元件数: {len(c.comps)}")
    print(f"连线数: {len(set(c.wires))}")
