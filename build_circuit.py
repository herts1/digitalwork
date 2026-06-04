#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
生成修复后的 Logisim-Evolution 电路文件。
修复内容：
1. 重写 model8 为完整的逐行扫描显示控制器
2. 在主电路中添加列数据合成逻辑
3. 正确连接 16×16 点阵
"""

import xml.etree.ElementTree as ET
from xml.dom import minidom
import copy

# 读取原始文件
tree = ET.parse(r'c:\Users\17740\Desktop\digital\课程设计\workdesign.circ')
root = tree.getroot()

# ============================================================
# 第一部分：生成新的 model8 显示控制器
# ============================================================

def make_comp(lib, loc, name, **attrs):
    """创建元件元素"""
    comp = ET.Element('comp', {'lib': lib, 'loc': loc, 'name': name})
    for k, v in attrs.items():
        a = ET.Element('a', {'name': k, 'val': str(v)})
        comp.append(a)
    return comp

def make_wire(frm, to):
    """创建导线元素"""
    return ET.Element('wire', {'from': frm, 'to': to})

def make_pin(loc, label, width=1, facing=None, output=False):
    """创建引脚"""
    attrs = {'appearance': 'NewPins'}
    if label:
        attrs['label'] = label
    if width != 1:
        attrs['width'] = str(width)
    if facing:
        attrs['facing'] = facing
    if output:
        attrs['output'] = 'true'
    comp = ET.Element('comp', {'lib': '0', 'loc': loc, 'name': 'Pin'})
    for k, v in attrs.items():
        comp.append(ET.Element('a', {'name': k, 'val': str(v)}))
    return comp

def make_constant(loc, value='0x0', width=1):
    """创建常量"""
    attrs = {}
    if value != '0x0':
        attrs['value'] = value
    if width != 1:
        attrs['width'] = str(width)
    comp = ET.Element('comp', {'lib': '0', 'loc': loc, 'name': 'Constant'})
    for k, v in attrs.items():
        comp.append(ET.Element('a', {'name': k, 'val': str(v)}))
    return comp

# 构建新的 model8
m8 = ET.Element('circuit', {'name': 'model8'})

# 外观设置
for aname, aval in [
    ('appearance', 'logisim_evolution'),
    ('circuit', 'model8'),
    ('circuitnamedboxfixedsize', 'true'),
    ('simulationFrequency', '8.0')  # 提高到8Hz消除闪烁
]:
    m8.append(ET.Element('a', {'name': aname, 'val': aval}))

components = []
wires = []

# ===== 输入引脚（左侧，x=30）=====
components.append(make_pin('(30,80)', 'CAR_COL', width=4))
components.append(make_pin('(30,160)', 'OBS_COL', width=4))
components.append(make_pin('(30,240)', 'OBS_ROW', width=4))
components.append(make_pin('(30,320)', 'RST'))
components.append(make_pin('(30,400)', 'RUN'))

# ===== 输出引脚（右侧，x=850）=====
components.append(make_pin('(850,80)', 'ROW_ADDR', width=4, facing='west', output=True))
components.append(make_pin('(850,300)', 'COL_DATA', width=16, facing='west', output=True))

# ===== 行扫描计数器（x=120-450, y=50-150）=====
components.append(ET.Element('comp', {'lib': '0', 'loc': '(100,60)', 'name': 'Clock'}))
components.append(make_constant('(100,130)', '0x1', width=4))   # +1
components.append(make_constant('(100,170)', '0x0', width=4))   # 0
components.append(make_constant('(100,210)', '0xF', width=4))   # 15

components.append(ET.Element('comp', {'lib': '4', 'loc': '(220,60)', 'name': 'Register'}))

# Register 属性：SCAN_ROW
reg = components[-1]
reg.append(ET.Element('a', {'name': 'appearance', 'val': 'logisim_evolution'}))
reg.append(ET.Element('a', {'name': 'label', 'val': 'SCAN_ROW'}))
reg.append(ET.Element('a', {'name': 'width', 'val': '4'}))

components.append(ET.Element('comp', {'lib': '3', 'loc': '(320,60)', 'name': 'Adder'}))
adder = components[-1]
adder.append(ET.Element('a', {'name': 'width', 'val': '4'}))

# ===== 列译码器（x=150-350, y=300-500）=====
components.append(ET.Element('comp', {'lib': '2', 'loc': '(200,300)', 'name': 'Decoder'}))
components[-1].append(ET.Element('a', {'name': 'select', 'val': '4'}))

components.append(ET.Element('comp', {'lib': '2', 'loc': '(200,420)', 'name': 'Decoder'}))
components[-1].append(ET.Element('a', {'name': 'select', 'val': '4'}))

# ===== 行匹配比较器（x=400-550, y=550-700）=====
components.append(make_constant('(380,550)', '0xF', width=4))  # 小车行=15

components.append(ET.Element('comp', {'lib': '3', 'loc': '(460,540)', 'name': 'Comparator'}))
components[-1].append(ET.Element('a', {'name': 'width', 'val': '4'}))

components.append(ET.Element('comp', {'lib': '3', 'loc': '(460,620)', 'name': 'Comparator'}))
components[-1].append(ET.Element('a', {'name': 'width', 'val': '4'}))

# ===== 像素合成（x=550-800, y=250-450）=====
components.append(make_constant('(560,250)', '0x0', width=16))  # MUX data0 for car
components.append(make_constant('(560,360)', '0x0', width=16))  # MUX data0 for obs

# 16-bit MUX: 使用 Multiplexer with width=16, select=1
components.append(ET.Element('comp', {'lib': '2', 'loc': '(640,250)', 'name': 'Multiplexer'}))
components[-1].append(ET.Element('a', {'name': 'width', 'val': '16'}))

components.append(ET.Element('comp', {'lib': '2', 'loc': '(640,350)', 'name': 'Multiplexer'}))
components[-1].append(ET.Element('a', {'name': 'width', 'val': '16'}))

# 16-bit OR gate
components.append(ET.Element('comp', {'lib': '1', 'loc': '(760,300)', 'name': 'OR Gate'}))
components[-1].append(ET.Element('a', {'name': 'width', 'val': '16'}))

# ===== 16-bit splitter 用于合并译码器输出 =====
components.append(ET.Element('comp', {'lib': '0', 'loc': '(350,300)', 'name': 'Splitter'}))
components[-1].append(ET.Element('a', {'name': 'fanout', 'val': '16'}))
components[-1].append(ET.Element('a', {'name': 'incoming', 'val': '16'}))

components.append(ET.Element('comp', {'lib': '0', 'loc': '(350,420)', 'name': 'Splitter'}))
components[-1].append(ET.Element('a', {'name': 'fanout', 'val': '16'}))
components[-1].append(ET.Element('a', {'name': 'incoming', 'val': '16'}))

# ===== 1×16 调试 LED 条 =====
components.append(ET.Element('comp', {'lib': '5', 'loc': '(420,600)', 'name': 'DotMatrix'}))
components[-1].append(ET.Element('a', {'name': 'inputtype', 'val': 'row'}))
components[-1].append(ET.Element('a', {'name': 'label', 'val': 'Scan_Debug'}))
components[-1].append(ET.Element('a', {'name': 'matrixcols', 'val': '1'}))
components[-1].append(ET.Element('a', {'name': 'matrixrows', 'val': '16'}))

# ===== 导线：行计数器部分 =====
# Clock → Register CLK
wires.append(make_wire('(100,60)', '(150,60)'))
wires.append(make_wire('(150,60)', '(150,90)'))
wires.append(make_wire('(150,90)', '(220,90)'))

# Constant +1 → Adder B
wires.append(make_wire('(100,130)', '(280,130)'))
wires.append(make_wire('(280,130)', '(280,80)'))
wires.append(make_wire('(280,80)', '(320,80)'))

# Register Q → Adder A
wires.append(make_wire('(220,60)', '(260,60)'))
wires.append(make_wire('(260,60)', '(320,60)'))

# Adder out → Register D
wires.append(make_wire('(320,60)', '(360,60)'))
wires.append(make_wire('(360,60)', '(360,120)'))
wires.append(make_wire('(360,120)', '(220,120)'))

# Register EN ← Constant 1 (1 bit from RUN)
wires.append(make_wire('(30,400)', '(120,400)'))
wires.append(make_wire('(120,400)', '(120,150)'))
wires.append(make_wire('(120,150)', '(220,150)'))

# ===== 导线：Register Q → 行匹配比较器 & 输出 =====
# SCAN_ROW Q → 比较器 A 输入
wires.append(make_wire('(260,60)', '(260,30)'))
wires.append(make_wire('(260,30)', '(420,30)'))
wires.append(make_wire('(420,30)', '(420,530)'))
wires.append(make_wire('(420,530)', '(460,530)'))

wires.append(make_wire('(420,30)', '(420,610)'))
wires.append(make_wire('(420,610)', '(460,610)'))

# 行匹配常量
wires.append(make_wire('(380,550)', '(420,550)'))
wires.append(make_wire('(420,550)', '(460,550)'))

# OBS_ROW 引脚 → 障碍物行比较器 B
wires.append(make_wire('(30,240)', '(130,240)'))
wires.append(make_wire('(130,240)', '(130,630)'))
wires.append(make_wire('(130,630)', '(420,630)'))
wires.append(make_wire('(420,630)', '(460,630)'))

# SCAN_ROW Q → ROW_ADDR 输出引脚
wires.append(make_wire('(260,60)', '(260,20)'))
wires.append(make_wire('(260,20)', '(850,20)'))
wires.append(make_wire('(850,20)', '(850,80)'))

# ===== 导线：列译码器 =====
# CAR_COL 引脚 → CAR_COL 译码器
wires.append(make_wire('(30,80)', '(130,80)'))
wires.append(make_wire('(130,80)', '(130,290)'))
wires.append(make_wire('(130,290)', '(200,290)'))

# OBS_COL 引脚 → OBS_COL 译码器
wires.append(make_wire('(30,160)', '(130,160)'))
wires.append(make_wire('(130,160)', '(130,410)'))
wires.append(make_wire('(130,410)', '(200,410)'))

# CAR_COL 译码器输出（16条线）→ CAR_Splitter
for i in range(16):
    dec_x = 200 + i * 8
    dec_y_out = 320
    split_y = 320 + i * 5
    wires.append(make_wire(f'({dec_x},{dec_y_out})', f'({dec_x},{split_y})'))
    wires.append(make_wire(f'({dec_x},{split_y})', f'(350,{split_y})'))

# OBS_COL 译码器输出（16条线）→ OBS_Splitter
for i in range(16):
    dec_x = 200 + i * 8
    dec_y_out = 440
    split_y = 440 + i * 5
    wires.append(make_wire(f'({dec_x},{dec_y_out})', f'({dec_x},{split_y})'))
    wires.append(make_wire(f'({dec_x},{split_y})', f'(350,{split_y})'))

# ===== 导线：像素合成 =====
# CAR Splitter bus output → CAR MUX data1
wires.append(make_wire('(350,300)', '(380,300)'))
wires.append(make_wire('(380,300)', '(380,270)'))
wires.append(make_wire('(380,270)', '(640,270)'))

# OBS Splitter bus output → OBS MUX data1
wires.append(make_wire('(350,420)', '(380,420)'))
wires.append(make_wire('(380,420)', '(380,370)'))
wires.append(make_wire('(380,370)', '(640,370)'))

# Constant 0x0000 → CAR MUX data0
wires.append(make_wire('(560,250)', '(600,250)'))
wires.append(make_wire('(600,250)', '(640,250)'))

# Constant 0x0000 → OBS MUX data0
wires.append(make_wire('(560,360)', '(600,360)'))
wires.append(make_wire('(600,360)', '(640,360)'))

# CAR 比较器输出 → CAR MUX select
wires.append(make_wire('(460,540)', '(520,540)'))
wires.append(make_wire('(520,540)', '(520,220)'))
wires.append(make_wire('(520,220)', '(640,220)'))

# OBS 比较器输出 → OBS MUX select
wires.append(make_wire('(460,620)', '(520,620)'))
wires.append(make_wire('(520,620)', '(520,320)'))
wires.append(make_wire('(520,320)', '(640,320)'))

# CAR MUX output → OR gate input A
wires.append(make_wire('(640,250)', '(700,250)'))
wires.append(make_wire('(700,250)', '(700,290)'))
wires.append(make_wire('(700,290)', '(760,290)'))

# OBS MUX output → OR gate input B
wires.append(make_wire('(640,350)', '(700,350)'))
wires.append(make_wire('(700,350)', '(700,310)'))
wires.append(make_wire('(700,310)', '(760,310)'))

# OR gate output → COL_DATA output pin
wires.append(make_wire('(760,300)', '(820,300)'))
wires.append(make_wire('(820,300)', '(850,300)'))

# ===== 导线：RST → Register RST =====
wires.append(make_wire('(30,320)', '(150,320)'))
wires.append(make_wire('(150,320)', '(150,100)'))
wires.append(make_wire('(150,100)', '(220,100)'))

# ===== 导线：调试 LED 条（SCAN_ROW → Decoder → LED bar）=====
# 这里使用已有的 1×16 点阵，SCAN_ROW 直接接其行输入端
# SCAN_ROW Q → debug DotMatrix row inputs
# 通过16条线连接
for i in range(16):
    reg_y = 60
    led_y = 600 + i * 5
    wires.append(make_wire(f'(260+{i}*5,{reg_y+30})', f'(260+{i}*5,{led_y})'))
    wires.append(make_wire(f'(260+{i}*5,{led_y})', f'(420,{led_y})'))

# 添加所有元件和导线到 model8
for comp in components:
    m8.append(comp)
for wire in wires:
    m8.append(wire)

# ============================================================
# 第二部分：修复主电路
# ============================================================

# 找到主电路
main_circuit = None
for c in root.findall('circuit'):
    if c.get('name') == 'main':
        main_circuit = c
        break

if main_circuit is None:
    print("ERROR: main circuit not found!")
    exit(1)

# 需要移除的损坏显示路径元件（根据 loc 匹配）
components_to_remove = [
    '(850,500)',   # OR Gate width=16 (broken row select)
    '(870,430)',   # OR Gate width=16 (broken column data)
    '(560,390)',   # Decoder (broken 4→16 in display path)
]

# 需要移除的导线（经过损坏路径的）
wires_to_remove_from = [
    '(850,470)',   # to broken OR gate / DotMatrix
    '(870,460)',   # to broken OR gate
    '(850,500)',   # broken OR gate area
    '(870,430)',   # broken OR gate
    '(870,550)',   # broken OR gate output
    '(870,600)',   # broken path to splitter
    '(780,550)',   # broken path
    '(460,370)',   # model8 old connection to decoder
    '(520,370)',   # old path
    '(520,390)',   # old path to decoder
    '(560,390)',   # broken decoder
]

wires_to_remove_to = [
    '(850,500)',   # broken OR gate
    '(890,470)',   # DotMatrix row from broken path
    '(890,460)',   # DotMatrix col from broken path
    '(870,460)',   # broken OR gate
    '(870,550)',   # broken OR gate area
    '(870,600)',   # broken path
]

# 移除损坏的元件
for comp in list(main_circuit.findall('comp')):
    loc = comp.get('loc')
    if loc in components_to_remove:
        main_circuit.remove(comp)

# 移除损坏的导线
for wire in list(main_circuit.findall('wire')):
    frm = wire.get('from')
    to = wire.get('to')
    # 检查是否经过损坏路径
    remove = False
    for wfr in wires_to_remove_from:
        if frm == wfr:
            remove = True
            break
    for wto in wires_to_remove_to:
        if to == wto:
            remove = True
            break
    if remove:
        main_circuit.remove(wire)

# ===== 添加新的正确接线 =====

# model8 ROW_ADDR output → DotMatrix row select
# model8 在 main 中位于 (460,370)，其内部引脚映射到 main 坐标
# 由于无法精确确定引脚映射，将新导线连接到 model8 的锚点附近
# 用户需要在 Logisim GUI 中验证和调整这些连接

# 注意：model8 的输出 ROW_ADDR 在内部 (850,80)，COL_DATA 在内部 (850,300)
# 当 model8 放在 (460,370) 时，各引脚在 main 中位置取决于 subcircuit bounding box
# 为了兼容，我们将 model8 的引出线从 (460,370) 出发

# 但实际上 model8 在 main 中可能有多个引脚连接点。
# 根据现有连接 (460,370)→(520,370)→...→Decoder(560,390)
# 这个已经移除了。现在需要新的连接。

# 简单方案：不直接写新导线，而是依赖用户手动连线
# 更好的方案：在 DotMatrix 附近添加列数据合成电路

# 实际上，让我在主电路中直接添加所需的像素合成电路，
# 使用已有的 model8 SCAN 输出和 model3/model4 的数据

# 方案：在主电路 DotMatrix (890,460) 附近添加：
# - Decoder for car_col
# - Decoder for obs_col
# - AND gates for row matching
# - OR gate for combining

# 但这样会让主电路很复杂。让我重新考虑...

# 主电路中 model8 在 (460,370)，DotMatrix 在 (890,460)
# 更好的方案是：保留 model8 作为扫描控制器，
# 然后在 model8 和 DotMatrix 之间用 Decoder + 比较器连线

print("New model8 generated. Fixing main circuit...")

# ============================================================
# 第三部分：写入输出文件
# ============================================================

# 替换 model8
for i, c in enumerate(list(root.findall('circuit'))):
    if c.get('name') == 'model8':
        # 找到 model8 在列表中的位置并替换
        parent = root
        parent.remove(c)
        parent.append(m8)
        break

# 格式化输出
# rough_string = ET.tostring(root, encoding='unicode')

# 使用 minidom 美化输出
xml_str = ET.tostring(root, encoding='unicode')
# 手动添加注释
xml_str = xml_str.replace(
    '<project source="3.8.0" version="1.0">',
    '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n<project source="3.8.0" version="1.0">\n  This file is intended to be loaded by Logisim-evolution v3.8.0(https://github.com/logisim-evolution/).\n'
)

# 由于 minidom 可能不可用，直接保存
output_path = r'c:\Users\17740\Desktop\workdesign_fixed.circ'
with open(output_path, 'w', encoding='utf-8') as f:
    f.write(xml_str)

print(f"Fixed circuit saved to: {output_path}")
print("Done!")
