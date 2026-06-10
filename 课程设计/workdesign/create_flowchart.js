/**
 * 电话通话记录查询系统 —— 流程图生成器 (Visio .vsdx 格式)
 * 根据 main.cpp / phone.c / phone.h 的代码逻辑生成多页流程图。
 */

const AdmZip = require('adm-zip');
const path = require('path');

const OUTPUT = path.join(__dirname, '电话查询系统_流程图.vsdx');

// ========== XML 命名空间 ==========
const NS_R = 'http://schemas.openxmlformats.org/package/2006/relationships';
const NS_V = 'http://schemas.microsoft.com/office/visio/2012/main';
const NS_CT = 'http://schemas.openxmlformats.org/package/2006/content-types';

// ========== XML 构建工具 ==========
function xmlDecl() {
  return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n';
}

function tag(name, attrs, content) {
  const attrStr = attrs ? ' ' + Object.entries(attrs).map(([k, v]) => `${k}="${v}"`).join(' ') : '';
  if (content === undefined || content === null) {
    return `<${name}${attrStr}/>`;
  }
  return `<${name}${attrStr}>${content}</${name}>`;
}

// ========== [Content_Types].xml ==========
function makeContentTypes() {
  let xml = xmlDecl();
  xml += `<Types xmlns="${NS_CT}">\n`;
  const overrides = [
    ['/visio/document.xml', 'application/vnd.ms-visio.document.main+xml'],
    ['/visio/pages/page1.xml', 'application/vnd.ms-visio.page+xml'],
    ['/visio/pages/page2.xml', 'application/vnd.ms-visio.page+xml'],
  ];
  for (const [pn, ct] of overrides) {
    xml += `  <Override PartName="${pn}" ContentType="${ct}"/>\n`;
  }
  xml += `  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>\n`;
  xml += `  <Default Extension="xml" ContentType="application/xml"/>\n`;
  xml += `</Types>`;
  return xml;
}

// ========== _rels/.rels ==========
function makeRootRels() {
  let xml = xmlDecl();
  xml += `<Relationships xmlns="${NS_R}">\n`;
  xml += `  <Relationship Id="rId1" Type="http://schemas.microsoft.com/visio/2010/relationships/document" Target="/visio/document.xml"/>\n`;
  xml += `</Relationships>`;
  return xml;
}

// ========== visio/document.xml ==========
function makeDocument() {
  let xml = xmlDecl();
  xml += `<VisioDocument xmlns="${NS_V}" xmlns:r="${NS_R}">\n`;
  xml += `  <DocumentSettings DefaultFillStyle="1" DefaultLineStyle="1" DefaultTextStyle="1"/>\n`;
  xml += `  <Pages>\n`;
  xml += `    <Page ID="0" Name="主程序流程图" NameU="主程序流程图"/>\n`;
  xml += `    <Page ID="1" Name="核心算法详图" NameU="核心算法详图"/>\n`;
  xml += `  </Pages>\n`;
  xml += `</VisioDocument>`;
  return xml;
}

// ========== visio/_rels/document.xml.rels ==========
function makeDocRels() {
  let xml = xmlDecl();
  xml += `<Relationships xmlns="${NS_R}">\n`;
  xml += `  <Relationship Id="rId1" Type="http://schemas.microsoft.com/visio/2010/relationships/pages" Target="pages/pages.xml"/>\n`;
  xml += `</Relationships>`;
  return xml;
}

// ========== visio/pages/pages.xml ==========
function makePages() {
  let xml = xmlDecl();
  xml += `<Pages xmlns="${NS_V}" xmlns:r="${NS_R}">\n`;
  xml += `  <Page ID="0" Name="主程序流程图" NameU="主程序流程图"/>\n`;
  xml += `  <Page ID="1" Name="核心算法详图" NameU="核心算法详图"/>\n`;
  xml += `</Pages>`;
  return xml;
}

// ========== visio/pages/_rels/pages.xml.rels ==========
function makePagesRels() {
  let xml = xmlDecl();
  xml += `<Relationships xmlns="${NS_R}">\n`;
  xml += `  <Relationship Id="rId1" Type="http://schemas.microsoft.com/visio/2010/relationships/page" Target="page1.xml"/>\n`;
  xml += `  <Relationship Id="rId2" Type="http://schemas.microsoft.com/visio/2010/relationships/page" Target="page2.xml"/>\n`;
  xml += `</Relationships>`;
  return xml;
}

// ========== 页面常量 ==========
const PAGE_W = 8.5;   // 页面宽度 (英寸) - US Letter
const PAGE_H = 11.0;  // 页面高度 (英寸) - US Letter

// ========== Shape 辅助函数 ==========
/**
 * 创建一个形状 XML 字符串
 * Visio 坐标系: X 从左到右, Y 从下到上 (0 = 页面底部)
 * 这里传入的 y 是”从上到下”的逻辑坐标 (0 = 页面顶部)
 * 会自动转换为 Visio 的 Y 坐标
 *
 * @param {number} id - 形状 ID
 * @param {number} x  - 逻辑 X (英寸, 从左到右)
 * @param {number} y  - 逻辑 Y (英寸, 从上到下, 0=顶部)
 * @param {number} w  - 宽度 (英寸)
 * @param {number} h  - 高度 (英寸)
 * @param {string} text - 文本内容, \n 换行
 * @param {string} type - 'process' | 'decision' | 'startend'
 */
function makeShape(id, x, y, w, h, text, type) {
  const lines = text.split('\n');

  // Visio 内部坐标: PinY 从页面底部算起
  // 逻辑 Y 从顶部算起, 形状中心在 y + h/2
  const centerY = y + h / 2;
  const visioY = PAGE_H - centerY;

  // 计算颜色
  let fillHex;
  switch (type) {
    case 'startend':
      fillHex = '#D5E8D4'; // 绿色圆角矩形
      break;
    case 'decision':
      fillHex = '#FFE6CC'; // 橙色菱形
      break;
    default: // process
      fillHex = '#DAE8FC'; // 蓝色矩形
      break;
  }

  let shapeXml = '';
  shapeXml += `    <Shape ID=”${id}” Type=”Shape” LineStyle=”1” FillStyle=”1” TextStyle=”1”>\n`;
  shapeXml += `      <XForm>\n`;
  shapeXml += `        <PinX>${x + w / 2}</PinX>\n`;
  shapeXml += `        <PinY>${visioY}</PinY>\n`;
  shapeXml += `        <Width>${w}</Width>\n`;
  shapeXml += `        <Height>${h}</Height>\n`;
  shapeXml += `        <LocPinX F=”(Width*0.5)”>${(w / 2).toFixed(4)}</LocPinX>\n`;
  shapeXml += `        <LocPinY F=”(Height*0.5)”>${(h / 2).toFixed(4)}</LocPinY>\n`;
  shapeXml += `        <Angle>0</Angle>\n`;
  shapeXml += `      </XForm>\n`;

  // 填充属性
  shapeXml += `      <Fill>\n`;
  shapeXml += `        <FillForegnd>${fillHex}</FillForegnd>\n`;
  shapeXml += `        <FillBkgnd>${fillHex}</FillBkgnd>\n`;
  shapeXml += `        <FillPattern>1</FillPattern>\n`;
  shapeXml += `      </Fill>\n`;

  // 线条属性
  shapeXml += `      <Line>\n`;
  shapeXml += `        <LineWeight>0.01</LineWeight>\n`;
  shapeXml += `        <LineColor>#808080</LineColor>\n`;
  shapeXml += `        <LinePattern>1</LinePattern>\n`;
  shapeXml += `      </Line>\n`;

  // Geometry (根据类型不同)
  if (type === 'decision') {
    // 菱形: 4 个顶点
    shapeXml += `      <Geom IX="0">\n`;
    shapeXml += `        <NoFill>0</NoFill>\n`;
    shapeXml += `        <NoLine>0</NoLine>\n`;
    shapeXml += `        <NoShow>0</NoShow>\n`;
    shapeXml += `        <MoveTo IX="1">\n`;
    shapeXml += `          <X F="(Width*0.5)">${(w / 2).toFixed(4)}</X>\n`;
    shapeXml += `          <Y>0</Y>\n`;
    shapeXml += `        </MoveTo>\n`;
    shapeXml += `        <LineTo IX="2">\n`;
    shapeXml += `          <X F="(Width*1)">${w.toFixed(4)}</X>\n`;
    shapeXml += `          <Y F="(Height*0.5)">${(h / 2).toFixed(4)}</Y>\n`;
    shapeXml += `        </LineTo>\n`;
    shapeXml += `        <LineTo IX="3">\n`;
    shapeXml += `          <X F="(Width*0.5)">${(w / 2).toFixed(4)}</X>\n`;
    shapeXml += `          <Y F="(Height*1)">${h.toFixed(4)}</Y>\n`;
    shapeXml += `        </LineTo>\n`;
    shapeXml += `        <LineTo IX="4">\n`;
    shapeXml += `          <X>0</X>\n`;
    shapeXml += `          <Y F="(Height*0.5)">${(h / 2).toFixed(4)}</Y>\n`;
    shapeXml += `        </LineTo>\n`;
    shapeXml += `        <LineTo IX="5">\n`;
    shapeXml += `          <X F="(Width*0.5)">${(w / 2).toFixed(4)}</X>\n`;
    shapeXml += `          <Y>0</Y>\n`;
    shapeXml += `        </LineTo>\n`;
    shapeXml += `      </Geom>\n`;
  } else if (type === 'startend') {
    // 圆角矩形 (使用标准矩形近似)
    shapeXml += `      <Geom IX="0">\n`;
    shapeXml += `        <NoFill>0</NoFill>\n`;
    shapeXml += `        <NoLine>0</NoLine>\n`;
    shapeXml += `        <NoShow>0</NoShow>\n`;
    shapeXml += `        <MoveTo IX="1"><X>0</X><Y>0</Y></MoveTo>\n`;
    shapeXml += `        <LineTo IX="2"><X F="(Width*1)">${w.toFixed(4)}</X><Y>0</Y></LineTo>\n`;
    shapeXml += `        <LineTo IX="3"><X F="(Width*1)">${w.toFixed(4)}</X><Y F="(Height*1)">${h.toFixed(4)}</Y></LineTo>\n`;
    shapeXml += `        <LineTo IX="4"><X>0</X><Y F="(Height*1)">${h.toFixed(4)}</Y></LineTo>\n`;
    shapeXml += `        <LineTo IX="5"><X>0</X><Y>0</Y></LineTo>\n`;
    shapeXml += `      </Geom>\n`;
  } else {
    // 矩形
    shapeXml += `      <Geom IX="0">\n`;
    shapeXml += `        <NoFill>0</NoFill>\n`;
    shapeXml += `        <NoLine>0</NoLine>\n`;
    shapeXml += `        <NoShow>0</NoShow>\n`;
    shapeXml += `        <MoveTo IX="1"><X>0</X><Y>0</Y></MoveTo>\n`;
    shapeXml += `        <LineTo IX="2"><X F="(Width*1)">${w.toFixed(4)}</X><Y>0</Y></LineTo>\n`;
    shapeXml += `        <LineTo IX="3"><X F="(Width*1)">${w.toFixed(4)}</X><Y F="(Height*1)">${h.toFixed(4)}</Y></LineTo>\n`;
    shapeXml += `        <LineTo IX="4"><X>0</X><Y F="(Height*1)">${h.toFixed(4)}</Y></LineTo>\n`;
    shapeXml += `        <LineTo IX="5"><X>0</X><Y>0</Y></LineTo>\n`;
    shapeXml += `      </Geom>\n`;
  }

  // 文本
  shapeXml += `      <Text>\n`;
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    // 对 XML 敏感字符进行转义
    const escapedLine = line
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
    shapeXml += `        <cp IX="${i}" PP="0"><Style>0</Style></cp>\n`;
    shapeXml += `        <pp IX="${i}" PP="0"/>\n`;
    shapeXml += `        <tp IX="${i}">${escapedLine}</tp>\n`;
  }
  shapeXml += `      </Text>\n`;
  shapeXml += `    </Shape>\n`;
  return shapeXml;
}

/**
 * 创建连线形状 (1-D connector)
 */
/**
 * 创建连线 (1-D connector)
 * 传入的 Y 是逻辑 Y (从上到下)
 */
function makeConnector(id, fromX, fromY, toX, toY, label) {
  // 转换为 Visio 坐标 (Y 从下到上)
  const vy1 = PAGE_H - fromY;
  const vy2 = PAGE_H - toY;

  let connXml = '';
  connXml += `    <Shape ID="${id}" Type="Shape" LineStyle="1" FillStyle="1" TextStyle="1">\n`;
  connXml += `      <XForm>\n`;
  connXml += `        <PinX>${((fromX + toX) / 2).toFixed(4)}</PinX>\n`;
  connXml += `        <PinY>${((vy1 + vy2) / 2).toFixed(4)}</PinY>\n`;
  connXml += `        <Width>0.01</Width>\n`;
  connXml += `        <Height>0.01</Height>\n`;
  connXml += `      </XForm>\n`;
  connXml += `      <XForm1D>\n`;
  connXml += `        <BeginX>${fromX.toFixed(4)}</BeginX>\n`;
  connXml += `        <BeginY>${vy1.toFixed(4)}</BeginY>\n`;
  connXml += `        <EndX>${toX.toFixed(4)}</EndX>\n`;
  connXml += `        <EndY>${vy2.toFixed(4)}</EndY>\n`;
  connXml += `      </XForm1D>\n`;
  connXml += `      <Line>\n`;
  connXml += `        <LineWeight>0.005</LineWeight>\n`;
  connXml += `        <LineColor>#808080</LineColor>\n`;
  connXml += `        <LinePattern>1</LinePattern>\n`;
  connXml += `        <BeginArrow>0</BeginArrow>\n`;
  connXml += `        <EndArrow>5</EndArrow>\n`;
  connXml += `      </Line>\n`;
  if (label) {
    const escapedLabel = label.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
    connXml += `      <Text>\n`;
    connXml += `        <cp IX="0" PP="0"><Style>0</Style></cp>\n`;
    connXml += `        <pp IX="0" PP="0"/>\n`;
    connXml += `        <tp IX="0">${escapedLabel}</tp>\n`;
    connXml += `      </Text>\n`;
  }
  connXml += `    </Shape>\n`;
  return connXml;
}


// ========== Page 1: 主程序流程图 ==========
function makePage1() {
  const shapes = [];
  const connectors = [];
  const cx = 4.25;  // 页面中心 X (8.5in 宽)
  let nextId = 1;

  function S(x, y, w, h, text, type) {
    const id = nextId++;
    shapes.push({ id, x, y, w, h, text, type });
    return { id, x, y, w, h };
  }

  function C(from, to, label) {
    const id = nextId++;
    const fx = from.x + from.w / 2;
    const fy = from.y + from.h;
    const tx = to.x + to.w / 2;
    const ty = to.y;
    connectors.push({ id, fromX: fx, fromY: fy, toX: tx, toY: ty, label: label || '' });
  }

  function CR(from, to, label) { // right-angle connector
    const id = nextId++;
    connectors.push({
      id, fromX: from.x + from.w, fromY: from.y + from.h / 2,
      toX: to.x, toY: to.y + to.h / 2, label: label || ''
    });
  }

  // ---- 主流程 ----
  const s1  = S(cx - 1.0, 0.3, 2.0, 0.45, '程序开始', 'startend');

  const s2  = S(cx - 1.4, 1.0, 2.8, 0.65, '加载客户数据\nload_customers("customers.txt")', 'process');
  C(s1, s2);

  const s3  = S(cx - 0.7, 1.95, 1.4, 0.5, '加载成功?', 'decision');
  C(s2, s3);

  const s4  = S(cx + 1.5, 1.95, 1.6, 0.45, '输出错误, 退出', 'startend');
  CR(s3, s4, '否');

  const s5  = S(cx - 1.4, 2.75, 2.8, 0.65, '加载通话记录\nload_calls("calls.txt")', 'process');
  C(s3, s5, '是');

  const s6  = S(cx - 0.7, 3.7, 1.4, 0.5, '加载成功?', 'decision');
  C(s5, s6);

  const s7  = S(cx + 1.5, 3.7, 1.6, 0.45, '输出错误, 退出', 'startend');
  CR(s6, s7, '否');

  const s8  = S(cx - 1.3, 4.5, 2.6, 0.55, '统计通话次数 count_calls()', 'process');
  C(s6, s8, '是');

  const s9  = S(cx - 1.4, 5.35, 2.8, 0.65, '初始化哈希表\nch_init(phone_ch) / ch_init(name_ch)', 'process');
  C(s8, s9);

  const s10 = S(cx - 1.5, 6.3, 3.0, 0.65, '遍历所有客户, 插入哈希表\nch_insert_phone() / ch_insert_name()', 'process');
  C(s9, s10);

  const s11 = S(cx - 1.0, 7.25, 2.0, 0.55, '显示菜单 print_menu()', 'process');
  C(s10, s11);

  const s12 = S(cx - 0.9, 8.1, 1.8, 0.5, '读取用户选择 choice', 'process');
  C(s11, s12);

  const s13 = S(cx - 0.8, 8.85, 1.6, 0.55, 'choice = ?', 'decision');
  C(s12, s13);

  // ---- Switch 各分支 (Y=10.0) ----
  const branchY = 10.0;
  const branches = [];
  const branchDefs = [
    { text: 'find_maniac()\n查找通话狂人', label: 'case 1' },
    { text: 'find_by_name()\n按姓名查询', label: 'case 2' },
    { text: 'find_by_phone()\n按手机号查询', label: 'case 3' },
    { text: 'compare_hash_\nfunctions()', label: 'case 4' },
    { text: 'compare_collision_\nmethods()', label: 'case 5' },
  ];

  // 分支均匀分布在 6.25in 宽度内 (cx-3.125 到 cx+3.125)
  const branchStartX = cx - 3.1;
  const branchSpacing = 1.55;
  for (let i = 0; i < branchDefs.length; i++) {
    const bx = branchStartX + i * branchSpacing;
    const bs = S(bx, branchY, 1.4, 0.85, branchDefs[i].text, 'process');
    branches.push(bs);
    C(s13, bs, branchDefs[i].label);
  }

  // case 0: 退出
  const sExit = S(cx + 3.8, 8.6, 1.6, 0.55, 'ch_free() 释放资源\n程序退出', 'startend');
  connectors.push({
    id: nextId++, fromX: s13.x - 0.3, fromY: s13.y,
    toX: sExit.x + sExit.w / 2, toY: sExit.y + sExit.h / 2, label: 'case 0'
  });

  // default
  const sDefault = S(cx + 3.8, 9.45, 1.4, 0.5, '无效输入提示', 'process');
  CR(s13, sDefault, 'default');

  // 汇聚回菜单
  const sLoop = S(cx + 3.2, 10.6, 1.8, 0.45, '循环回菜单', 'process');
  for (const bs of branches) {
    C(bs, sLoop, '');
  }
  C(sDefault, sLoop, '');

  // 回到 print_menu (画线)
  connectors.push({
    id: nextId++, fromX: sLoop.x, fromY: sLoop.y + sLoop.h / 2,
    toX: s11.x + s11.w, toY: s11.y + s11.h / 2, label: ''
  });

  // 组装 XML
  let xml = xmlDecl();
  xml += `<PageContents xmlns="${NS_V}" xmlns:r="${NS_R}">\n`;
  xml += `  <Shapes>\n`;
  for (const s of shapes) {
    xml += makeShape(s.id, s.x, s.y, s.w, s.h, s.text, s.type);
  }
  for (const c of connectors) {
    xml += makeConnector(c.id, c.fromX, c.fromY, c.toX, c.toY, c.label || '');
  }
  xml += `  </Shapes>\n`;
  xml += `</PageContents>`;
  return xml;
}


// ========== Page 2: 核心算法详图 ==========
function makePage2() {
  const shapes = [];
  const connectors = [];
  let nextId = 100;

  function S(x, y, w, h, text, type) {
    const id = nextId++;
    shapes.push({ id, x, y, w, h, text, type });
    return { id, x, y, w, h };
  }

  function C(from, to, label) {
    const id = nextId++;
    connectors.push({
      id, fromX: from.x + from.w / 2, fromY: from.y + from.h,
      toX: to.x + to.w / 2, toY: to.y, label: label || ''
    });
  }

  function CR(from, to, label) {
    const id = nextId++;
    connectors.push({
      id, fromX: from.x + from.w, fromY: from.y + from.h / 2,
      toX: to.x, toY: to.y + to.h / 2, label: label || ''
    });
  }

  // ====== 左列: find_maniac() ======
  const lx = 1.3;
  S(lx - 0.8, 0.2, 1.6, 0.4, 'find_maniac()', 'startend');
  const a1 = S(lx - 1.0, 0.85, 2.0, 0.5, 'count_calls()\n重新统计通话次数', 'process');
  const a2 = S(lx - 1.0, 1.6, 2.0, 0.5, '遍历customers[]数组\n找最大call_count', 'process');
  const a3 = S(lx - 0.95, 2.35, 1.9, 0.55, '输出: 手机号 / 姓名\n通话次数', 'process');
  const a4 = S(lx - 0.5, 3.15, 1.0, 0.4, '返回', 'startend');
  C(a1, a2); C(a2, a3); C(a3, a4);

  // ====== 中列: find_by_name() ======
  const mx = 4.25;
  S(mx - 0.8, 0.2, 1.6, 0.4, 'find_by_name()', 'startend');
  const b1 = S(mx - 1.1, 0.85, 2.2, 0.5, 'ch_find_name()\n链地址哈希表查找', 'process');
  const b2 = S(mx - 0.5, 1.6, 1.0, 0.4, '找到?', 'decision');
  const b3 = S(mx + 1.2, 1.6, 1.0, 0.4, '输出"No Info"', 'process');
  const b4 = S(mx - 1.25, 2.3, 2.5, 0.7,
    '输出客户信息:\n姓名 / 身份证号 / 手机号\n遍历calls[]打印通话明细', 'process');
  S(mx + 1.2, 2.3, 1.0, 0.4, '返回', 'startend');
  const b6 = S(mx - 0.5, 3.15, 1.0, 0.4, '返回', 'startend');
  C(b1, b2); CR(b2, b3, '否'); C(b2, b4, '是');
  C(b3, { id: 0, x: mx + 1.2, y: 2.3, w: 1.0, h: 0.4 }, '');
  C(b4, b6);

  // ====== 右列: compare_hash_functions() ======
  const rx = 7.0;
  S(rx - 1.0, 0.2, 2.0, 0.4, 'compare_hash_functions()', 'startend');
  const c1 = S(rx - 1.3, 0.85, 2.6, 0.7,
    'build_phone_oa()\n分别用除留余数法(HASH_DIV)\n和折叠法(HASH_FOLD)\n构建手机号开放寻址哈希表', 'process');
  const c2 = S(rx - 1.2, 1.8, 2.4, 0.65,
    '输出手机号哈希对比:\n两种方法的冲突数和冲突率', 'process');
  const c3 = S(rx - 1.3, 2.7, 2.6, 0.7,
    'build_name_oa()\n分别用两种哈希函数\n构建姓名开放寻址哈希表', 'process');
  const c4 = S(rx - 1.2, 3.65, 2.4, 0.65,
    '输出姓名哈希对比:\n两种方法的冲突数和冲突率', 'process');
  S(rx - 0.7, 4.5, 1.4, 0.4, '返回', 'startend');
  C(c1, c2); C(c2, c3); C(c3, c4);

  // ====== 下半: compare_collision_methods() ======
  const dy = 5.3;
  S(mx - 1.1, dy, 2.2, 0.45, 'compare_collision_methods()', 'startend');
  const d1 = S(mx - 1.4, dy + 0.7, 2.8, 0.75,
    'build_phone_oa() +\nbuild_phone_ch()\n分别用开放寻址(线性探测)\n和链地址构建手机号哈希表', 'process');
  const d2 = S(mx - 1.3, dy + 1.7, 2.6, 0.7,
    '输出手机号哈希对比:\n线性探测 vs 链地址\n总探测数 / ASL值', 'process');
  const d3 = S(mx - 1.4, dy + 2.65, 2.8, 0.75,
    'build_name_oa() +\nbuild_name_ch()\n分别用两种冲突处理法\n构建姓名哈希表', 'process');
  const d4 = S(mx - 1.3, dy + 3.65, 2.6, 0.7,
    '输出姓名哈希对比:\n线性探测 vs 链地址\n总探测数 / ASL值', 'process');
  const d5 = S(mx - 1.0, dy + 4.55, 2.0, 0.55, 'ch_free() 释放链地址表\n(开放寻址用栈自动释放)', 'process');
  S(mx - 0.5, dy + 5.3, 1.0, 0.4, '返回', 'startend');
  C(d1, d2); C(d2, d3); C(d3, d4); C(d4, d5);

  // ====== 数据结构说明框 (右侧) ======
  S(rx - 1.4, 5.8, 2.8, 2.4,
    '【核心数据结构】\n\n'
    + 'Customer 结构体:\n'
    + '  char name[32]\n'
    + '  char id[19]\n'
    + '  char phone[12]\n'
    + '  int  call_count\n\n'
    + '哈希表 (2种):\n'
    + '  ① OASlot[] 开放寻址\n'
    + '     (线性探测法)\n'
    + '  ② ChainNode*[] 链地址\n'
    + '     (单链表)', 'process');

  S(rx - 1.4, 8.5, 2.8, 2.3,
    '【哈希函数 (2种)】\n\n'
    + 'HASH_DIV (除留余数):\n'
    + '  h(key) = key % size\n\n'
    + 'HASH_FOLD (折叠法):\n'
    + '  手机号→分3段相加取模\n'
    + '  姓名→每4字节分块取模', 'process');

  // 组装 XML
  let xml = xmlDecl();
  xml += `<PageContents xmlns="${NS_V}" xmlns:r="${NS_R}">\n`;
  xml += `  <Shapes>\n`;
  for (const s of shapes) {
    xml += makeShape(s.id, s.x, s.y, s.w, s.h, s.text, s.type);
  }
  for (const c of connectors) {
    xml += makeConnector(c.id, c.fromX, c.fromY, c.toX, c.toY, c.label || '');
  }
  xml += `  </Shapes>\n`;
  xml += `</PageContents>`;
  return xml;
}


// ========== 打包 VSDX ==========
function buildVsdx() {
  const zip = new AdmZip();

  // [Content_Types].xml
  zip.addFile('[Content_Types].xml', Buffer.from(makeContentTypes(), 'utf-8'));

  // _rels/.rels
  zip.addFile('_rels/.rels', Buffer.from(makeRootRels(), 'utf-8'));

  // visio/document.xml
  zip.addFile('visio/document.xml', Buffer.from(makeDocument(), 'utf-8'));

  // visio/_rels/document.xml.rels
  zip.addFile('visio/_rels/document.xml.rels', Buffer.from(makeDocRels(), 'utf-8'));

  // visio/pages/pages.xml
  zip.addFile('visio/pages/pages.xml', Buffer.from(makePages(), 'utf-8'));

  // visio/pages/_rels/pages.xml.rels
  zip.addFile('visio/pages/_rels/pages.xml.rels', Buffer.from(makePagesRels(), 'utf-8'));

  // visio/pages/page1.xml (主程序流程图)
  zip.addFile('visio/pages/page1.xml', Buffer.from(makePage1(), 'utf-8'));

  // visio/pages/page2.xml (核心算法详图)
  zip.addFile('visio/pages/page2.xml', Buffer.from(makePage2(), 'utf-8'));

  // 写入文件
  zip.writeZip(OUTPUT);
  console.log(`✅ 流程图已生成: ${OUTPUT}`);
  console.log(`   文件大小: ${require('fs').statSync(OUTPUT).size} bytes`);
}

buildVsdx();
