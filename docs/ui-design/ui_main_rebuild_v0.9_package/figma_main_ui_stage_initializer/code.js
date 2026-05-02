// Xiuxian Main UI Stage Initializer v0.9
// Purpose: Create low-fidelity Figma pages and frames for main UI stage states.
// This is not a final visual design. It creates a stable skeleton for later manual refinement.

const W = 1920;
const H = 1080;
const TOP_H = 88;
const BOTTOM_H = 72;
const MAP_Y = TOP_H;
const MAP_H = H - TOP_H - BOTTOM_H;
const BOTTOM_Y = H - BOTTOM_H;

const COLORS = {
  bg: '#F3E6C8',
  panel: '#FFF7E4',
  panel2: '#F8ECD2',
  stroke: '#D2BE94',
  text: '#2B241A',
  subtext: '#5C5040',
  green: '#3D745F',
  greenLight: '#DCEADF',
  gold: '#B88A3B',
  warn: '#B87524',
  red: '#8C2F2F',
  muted: '#8D8270',
  map: '#E8D7B5',
  mapDark: '#CDBB91'
};

let FONT_REG = { family: 'Inter', style: 'Regular' };
let FONT_MED = { family: 'Inter', style: 'Medium' };
let FONT_BOLD = { family: 'Inter', style: 'Bold' };

async function loadFonts() {
  try {
    FONT_REG = { family: 'Noto Sans SC', style: 'Regular' };
    FONT_MED = { family: 'Noto Sans SC', style: 'Medium' };
    FONT_BOLD = { family: 'Noto Sans SC', style: 'Bold' };
    await figma.loadFontAsync(FONT_REG);
    await figma.loadFontAsync(FONT_MED);
    await figma.loadFontAsync(FONT_BOLD);
  } catch (e) {
    FONT_REG = { family: 'Inter', style: 'Regular' };
    FONT_MED = { family: 'Inter', style: 'Medium' };
    FONT_BOLD = { family: 'Inter', style: 'Bold' };
    await figma.loadFontAsync(FONT_REG);
    await figma.loadFontAsync(FONT_MED);
    await figma.loadFontAsync(FONT_BOLD);
  }
}

function rgb(hex) {
  const h = hex.replace('#', '');
  return {
    r: parseInt(h.substring(0, 2), 16) / 255,
    g: parseInt(h.substring(2, 4), 16) / 255,
    b: parseInt(h.substring(4, 6), 16) / 255
  };
}

function paint(hex, opacity = 1) {
  return [{ type: 'SOLID', color: rgb(hex), opacity }];
}

function stroke(hex, opacity = 1) {
  return [{ type: 'SOLID', color: rgb(hex), opacity }];
}

function makePage(name) {
  const page = figma.createPage();
  page.name = name;
  return page;
}

function frame(parent, name, x, y, w, h, fill = COLORS.panel, strokeColor = COLORS.stroke, radius = 0) {
  const f = figma.createFrame();
  f.name = name;
  f.x = x;
  f.y = y;
  f.resize(w, h);
  f.fills = paint(fill);
  if (strokeColor) {
    f.strokes = stroke(strokeColor);
    f.strokeWeight = 1;
  } else {
    f.strokes = [];
  }
  f.cornerRadius = radius;
  parent.appendChild(f);
  return f;
}

function rect(parent, name, x, y, w, h, fill = COLORS.panel2, strokeColor = COLORS.stroke, radius = 8) {
  const r = figma.createRectangle();
  r.name = name;
  r.x = x;
  r.y = y;
  r.resize(w, h);
  r.fills = paint(fill);
  if (strokeColor) {
    r.strokes = stroke(strokeColor);
    r.strokeWeight = 1;
  } else {
    r.strokes = [];
  }
  r.cornerRadius = radius;
  parent.appendChild(r);
  return r;
}

function ellipse(parent, name, x, y, w, h, fill = COLORS.green, strokeColor = null) {
  const e = figma.createEllipse();
  e.name = name;
  e.x = x;
  e.y = y;
  e.resize(w, h);
  e.fills = paint(fill);
  if (strokeColor) {
    e.strokes = stroke(strokeColor);
    e.strokeWeight = 1;
  } else {
    e.strokes = [];
  }
  parent.appendChild(e);
  return e;
}

function text(parent, name, content, x, y, w, h, size = 14, color = COLORS.text, font = FONT_REG) {
  const t = figma.createText();
  t.name = name;
  t.x = x;
  t.y = y;
  t.resize(w, h);
  t.fontName = font;
  t.fontSize = size;
  t.fills = paint(color);
  t.characters = content;
  parent.appendChild(t);
  return t;
}

function chip(parent, label, x, y, fill = COLORS.greenLight, color = COLORS.green, w = null) {
  const width = w || Math.max(48, label.length * 14 + 18);
  rect(parent, `Chip_${label}`, x, y, width, 24, fill, COLORS.stroke, 12);
  text(parent, `ChipLabel_${label}`, label, x + 8, y + 4, width - 16, 16, 11, color, FONT_MED);
  return width;
}

function createTopBar(parent, stateLabel) {
  const top = frame(parent, 'TopPhaseBar_Frozen_Reference', 0, 0, W, TOP_H, '#FFF7E4', COLORS.stroke, 0);
  rect(top, 'CharacterSummary_TopLeft_Frozen', 24, 10, 572, 68, COLORS.panel2, COLORS.stroke, 10);
  text(top, 'CharacterName', '陆青岚｜炼气七层', 88, 18, 180, 20, 15, COLORS.text, FONT_BOLD);
  text(top, 'CharacterRole', '云麓宗｜外门弟子', 88, 44, 180, 18, 12, COLORS.subtext, FONT_MED);
  rect(top, 'VitalsBarsPlaceholder', 252, 16, 300, 48, '#EAE0C7', COLORS.stroke, 6);
  rect(top, 'DecisionPhaseStepper_Frozen', 644, 8, 774, 72, COLORS.panel, COLORS.stroke, 10);
  text(top, 'StepperLabel', stateLabel, 680, 24, 420, 28, 16, COLORS.green, FONT_BOLD);
  rect(top, 'DeadlineBlock', 1240, 18, 160, 48, COLORS.text, COLORS.gold, 10);
  text(top, 'DeadlineText', '01:48｜已锁定 1/3', 1252, 32, 140, 18, 12, COLORS.panel, FONT_MED);
  rect(top, 'TimeBlock_Frozen', 1502, 10, 332, 68, COLORS.panel2, COLORS.stroke, 10);
  text(top, 'WorldTime', '玄元 128 年｜三月廿七｜辰时', 1524, 24, 280, 20, 13, COLORS.text, FONT_BOLD);
  text(top, 'TurnTime', '春末｜谷雨｜第 12 回合', 1524, 48, 280, 16, 11, COLORS.subtext, FONT_MED);
  rect(top, 'SettingsButton', 1858, 25, 38, 38, COLORS.panel, COLORS.stroke, 10);
  text(top, 'SettingsLabel', '设', 1870, 34, 16, 16, 13, COLORS.text, FONT_MED);
}

function createMap(parent) {
  const map = frame(parent, 'MapViewport_FullWidth', 0, MAP_Y, W, MAP_H, COLORS.map, COLORS.stroke, 0);
  // Simple terrain shapes
  rect(map, 'Region_RiverValley', 90, 560, 660, 180, '#DCEADF', null, 80);
  rect(map, 'Region_SectBelly', 560, 220, 620, 250, '#E6DFBC', null, 80);
  rect(map, 'Region_BorderWild', 760, 420, 880, 320, '#E9CFA7', null, 80);
  rect(map, 'Region_NorthwestFog', 80, 80, 560, 260, '#D2D0C6', null, 80);
  text(map, 'RegionLabel_RiverValley', '河谷 / 凡俗边缘区', 140, 300, 200, 20, 12, COLORS.subtext, FONT_MED);
  text(map, 'RegionLabel_SectBelly', '宗门腹地', 700, 280, 120, 20, 13, COLORS.green, FONT_MED);
  text(map, 'RegionLabel_BorderWild', '边界荒野', 1100, 560, 120, 20, 13, COLORS.warn, FONT_MED);

  // Routes
  const route = figma.createLine();
  route.name = 'RouteLine_Example_Path';
  route.x = 250;
  route.y = 560;
  route.resize(770, 0);
  route.rotation = -12;
  route.strokes = stroke(COLORS.gold, 0.7);
  route.strokeWeight = 4;
  map.appendChild(route);

  createNode(map, '青禾村', '凡人聚落｜风险低', 160, 600, 'known');
  createNode(map, '镇集', '坊市｜可交易', 380, 520, 'known');
  createNode(map, '云麓山道', '山道｜风险中', 640, 430, 'risk');
  createNode(map, '云麓宗山门', '当前位置｜宗门控制', 820, 320, 'current');
  createNode(map, '黑石岭矿脉', '资源紧张｜边境争夺', 1080, 470, 'target', ['▲', '宗', '矿']);
  createNode(map, '雾中旧洞府？', '传闻节点', 1260, 230, 'rumor', ['云']);
  createNode(map, '西北荒岭', '未知区域', 180, 160, 'fog');
  return map;
}

function createNode(parent, name, sub, x, y, type, badges = []) {
  const fill = type === 'target' ? '#FFF2D9' : type === 'fog' ? '#FFFFFF' : '#FFFFFF';
  const border = type === 'current' ? COLORS.gold : type === 'target' ? COLORS.red : type === 'risk' ? COLORS.warn : COLORS.stroke;
  rect(parent, `Node_${name}`, x, y, 190, 48, fill, border, 12);
  const dotColor = type === 'current' ? COLORS.gold : type === 'target' ? COLORS.red : type === 'risk' ? COLORS.warn : type === 'rumor' ? COLORS.muted : COLORS.green;
  ellipse(parent, `NodeDot_${name}`, x + 10, y + 14, 18, 18, dotColor);
  text(parent, `NodeName_${name}`, name, x + 38, y + 7, 140, 17, 12, COLORS.text, FONT_BOLD);
  text(parent, `NodeSub_${name}`, sub, x + 38, y + 26, 150, 16, 11, COLORS.subtext, FONT_REG);
  badges.forEach((b, i) => {
    rect(parent, `Badge_${name}_${b}`, x + 146 + i * 24, y - 12, 22, 22, b === '宗' ? COLORS.greenLight : '#FFF7E4', COLORS.stroke, 11);
    text(parent, `BadgeText_${name}_${b}`, b, x + 152 + i * 24, y - 8, 14, 14, 10, b === '▲' ? COLORS.warn : COLORS.text, FONT_BOLD);
  });
}

function createLeftPanels(parent, options = {}) {
  if (!options.collapsedGoal) {
    const goal = frame(parent, 'LeftTopGoalTrackerPanel', 24, 112, 320, 270, COLORS.panel, COLORS.stroke, 12);
    text(goal, 'GoalHeader', '目标追踪', 16, 14, 120, 22, 16, COLORS.text, FONT_BOLD);
    chip(goal, '主目标', 220, 14, COLORS.greenLight, COLORS.green, 64);
    rect(goal, 'PrimaryGoalCard', 16, 52, 288, 112, COLORS.panel2, COLORS.stroke, 10);
    text(goal, 'PrimaryGoalTitle', '寻物追踪：避瘴符材料', 28, 64, 250, 18, 13, COLORS.text, FONT_BOLD);
    text(goal, 'PrimaryGoalBody', '线索 2/4｜下一步：调查黑石岭矿脉外围', 28, 88, 250, 36, 12, COLORS.subtext, FONT_REG);
    rect(goal, 'Button_LocateNode', 28, 128, 86, 28, COLORS.panel, COLORS.gold, 8);
    text(goal, 'ButtonText_Locate', '定位节点', 42, 134, 60, 16, 12, COLORS.text, FONT_MED);
    rect(goal, 'SecondaryGoal_1', 16, 176, 288, 42, COLORS.panel2, COLORS.stroke, 8);
    text(goal, 'SecondaryGoal1Text', '突破准备：稳固元气｜闭关吐纳', 28, 188, 250, 16, 12, COLORS.text, FONT_MED);
    rect(goal, 'SecondaryGoal_2', 16, 226, 288, 42, COLORS.panel2, COLORS.stroke, 8);
    text(goal, 'SecondaryGoal2Text', '宗门委派：协助黑石岭驻守', 28, 238, 250, 16, 12, COLORS.text, FONT_MED);
  } else {
    rect(parent, 'GoalCollapsedTab_Target3', 0, 160, 34, 120, COLORS.panel, COLORS.stroke, 8);
    text(parent, 'GoalCollapsedText', '目标 3', 6, 180, 24, 80, 12, COLORS.text, FONT_BOLD);
  }

  if (!options.collapsedGlobal) {
    const global = frame(parent, 'LeftBottomGlobalNoticePanel', 24, 650, 320, 330, COLORS.panel, COLORS.stroke, 12);
    text(global, 'GlobalHeader', '全局消息', 16, 14, 120, 22, 16, COLORS.text, FONT_BOLD);
    chip(global, 'P1', 236, 14, '#F4DFC1', COLORS.warn, 42);
    rect(global, 'GlobalNoticeCard_Sect', 16, 52, 288, 122, '#FFF2D9', COLORS.warn, 10);
    text(global, 'GlobalNoticeTitle', '云麓宗边境驻守资源告急', 28, 64, 250, 18, 13, COLORS.text, FONT_BOLD);
    text(global, 'GlobalNoticeBody', '影响：黑石岭相关行动风险上升，宗门支持可能变少。', 28, 88, 250, 36, 12, COLORS.subtext, FONT_REG);
    rect(global, 'Button_OpenSect', 28, 134, 82, 28, COLORS.panel, COLORS.gold, 8);
    text(global, 'OpenSectText', '打开宗门', 40, 140, 60, 16, 12, COLORS.text, FONT_MED);
    rect(global, 'Button_Locate', 118, 134, 82, 28, COLORS.panel, COLORS.gold, 8);
    text(global, 'LocateText', '定位节点', 130, 140, 60, 16, 12, COLORS.text, FONT_MED);
    rect(global, 'GlobalNoticeCard_Ledger', 16, 188, 288, 78, COLORS.panel2, COLORS.stroke, 10);
    text(global, 'LedgerNoticeTitle', '账本线索更新', 28, 200, 250, 18, 13, COLORS.text, FONT_BOLD);
    text(global, 'LedgerNoticeBody', '前世旧闻与雾中旧洞府传闻产生关联。', 28, 224, 250, 28, 12, COLORS.subtext, FONT_REG);
    rect(global, 'ArchiveButton', 214, 286, 74, 26, COLORS.panel, COLORS.stroke, 8);
    text(global, 'ArchiveText', '归档', 238, 292, 40, 14, 12, COLORS.subtext, FONT_MED);
  } else {
    rect(parent, 'GlobalCollapsedTab_Global2', 0, 740, 34, 120, COLORS.panel, COLORS.stroke, 8);
    text(parent, 'GlobalCollapsedText', '全局 2', 6, 760, 24, 80, 12, COLORS.text, FONT_BOLD);
  }
}

function createRightPanel(parent, tab = '详情', readOnly = false) {
  const p = frame(parent, 'RightNodeContextPanel_TopTabs', 1520, 112, 376, 868, COLORS.panel, COLORS.stroke, 12);
  text(p, 'NodePanelTitle', '黑石岭矿脉', 18, 16, 200, 24, 18, COLORS.text, FONT_BOLD);
  text(p, 'NodePanelReadonly', readOnly ? '只读' : '', 320, 20, 40, 18, 12, COLORS.warn, FONT_MED);
  const tabs = ['详情', '短时行动 3', '长时行动 2', '资源设施 4', '风险线索 5'];
  let tx = 14;
  tabs.forEach((t) => {
    const active = t.indexOf(tab) === 0;
    const tw = t.length * 14 + 18;
    rect(p, `Tab_${t}`, tx, 52, tw, 30, active ? COLORS.green : COLORS.panel2, COLORS.stroke, 8);
    text(p, `TabText_${t}`, t, tx + 9, 60, tw - 18, 16, 11, active ? '#FFFFFF' : COLORS.subtext, FONT_MED);
    tx += tw + 6;
  });
  rect(p, `Page_${tab}`, 16, 98, 344, 746, COLORS.panel2, COLORS.stroke, 10);
  if (tab === '详情') {
    text(p, 'DetailBody', '类型：资源型地理节点\n区域：边界荒野\n控制权：云麓宗影响 56%，赤砂门 31%\n危险：中｜灵气：中等波动\n资源：玄铁矿脉、碎灵石、未知伴生矿\n\n最近变化：\n1. 云麓宗驻守推进至 47%。\n2. 外宗活动增加，路线风险上升。\n\n信息来源：宗门摘要 + 本地传闻\n可见性：sect_visible / rumor_visible', 28, 116, 320, 300, 12, COLORS.subtext, FONT_REG);
  } else if (tab === '短时行动') {
    actionCard(p, '调查矿脉外围', '短时｜约 4 小时｜风险中', '检查矿脉异动来源，可能获得资源线索或路线风险信息。', 28, 116);
    actionCard(p, '协助外围警戒', '短时｜8 小时｜宗门相关', '降低路线突发风险，可能提升宗门驻守进度。', 28, 330);
  } else if (tab === '长时行动') {
    actionCard(p, '探索黑石岭深处', '长时｜可投入｜风险中', '投入越多，发现资源槽、隐藏层或事件入口的概率越高。', 28, 116, ['半天', '1 天', '2 天', '投入剩余时间']);
    actionCard(p, '布置藏物后手', '长时｜固定 2 天｜风险：暴露', '在当前节点封存少量资产，写入轮回账本。', 28, 350, ['普通隐蔽', '谨慎隐蔽']);
  } else if (tab === '资源设施') {
    text(p, 'ResourcesBody', '资源槽 3\n- 玄铁矿脉｜丰度下降｜采集难度中\n- 碎灵石矿点｜已知｜采集难度低\n- 未知伴生矿｜传闻｜需调查\n\n设施 2\n- 临时驻守营地｜云麓宗｜建设中\n- 废弃矿棚｜可调查', 28, 116, 320, 260, 12, COLORS.subtext, FONT_REG);
  } else {
    text(p, 'RisksBody', '线索｜坊市｜未证实\n云麓山道有妖兽踪迹。\n[加入关注] [预估路线]\n\n宗门波及｜云麓宗\n当前持续行动：强化黑石岭驻守\n进度：47%\n阻碍：材料不足、边境冲突升温\n[打开宗门面板] [加入规划：协助驻守]\n\n后手感应｜账本\n雾中旧洞府方向出现模糊呼应。', 28, 116, 320, 320, 12, COLORS.subtext, FONT_REG);
  }
  return p;
}

function actionCard(parent, title, tags, desc, x, y, options = ['2 小时', '4 小时', '8 小时']) {
  rect(parent, `ActionCard_${title}`, x, y, 320, 190, COLORS.panel, COLORS.stroke, 10);
  text(parent, `ActionTitle_${title}`, title, x + 14, y + 12, 280, 20, 14, COLORS.text, FONT_BOLD);
  text(parent, `ActionTags_${title}`, tags, x + 14, y + 38, 280, 18, 11, COLORS.warn, FONT_MED);
  text(parent, `ActionDesc_${title}`, desc, x + 14, y + 62, 286, 34, 12, COLORS.subtext, FONT_REG);
  text(parent, `ParamLabel_${title}`, '投入时间', x + 14, y + 106, 60, 16, 11, COLORS.text, FONT_MED);
  let ox = x + 74;
  options.forEach((o) => {
    const ww = Math.max(46, o.length * 12 + 12);
    rect(parent, `Param_${title}_${o}`, ox, y + 102, ww, 24, COLORS.panel2, COLORS.stroke, 8);
    text(parent, `ParamText_${title}_${o}`, o, ox + 6, y + 108, ww - 12, 14, 10, COLORS.subtext, FONT_MED);
    ox += ww + 6;
  });
  rect(parent, `AddPlan_${title}`, x + 14, y + 144, 120, 30, COLORS.green, COLORS.green, 8);
  text(parent, `AddPlanText_${title}`, '加入规划', x + 44, y + 151, 70, 16, 12, '#FFFFFF', FONT_MED);
  rect(parent, `Advanced_${title}`, x + 146, y + 144, 90, 30, COLORS.panel2, COLORS.stroke, 8);
  text(parent, `AdvancedText_${title}`, '高级设置', x + 166, y + 151, 60, 16, 12, COLORS.subtext, FONT_MED);
}

function createBottom(parent, mode) {
  const bottom = frame(parent, 'BottomDockLayer', 0, BOTTOM_Y, W, BOTTOM_H, '#F2E7D3', '#B79862', 0);
  const entries = ['修为', '物品', '功法', '传讯', '宗门', '日志'];
  entries.forEach((e, i) => {
    rect(bottom, `SystemEntry_${e}_Frozen`, 24 + i * 46, 17, 38, 38, COLORS.panel, COLORS.stroke, 10);
    text(bottom, `SystemEntryText_${e}`, e, 30 + i * 46, 29, 26, 14, 11, COLORS.text, FONT_MED);
  });
  if (mode === 'prepare') {
    diamond(bottom, 'StartPlanning_Diamond', 1510, 16, 44, COLORS.green, '开始规划');
    ellipse(bottom, 'Autopilot_Round', 1624, 18, 40, 40, COLORS.gold);
    text(bottom, 'AutopilotText', '托管', 1630, 30, 28, 16, 11, '#FFFFFF', FONT_MED);
  } else {
    createBudget(bottom, mode);
    if (mode === 'locked') {
      ellipse(bottom, 'Back_Round', 1760, 18, 40, 40, COLORS.panel2, COLORS.gold);
      text(bottom, 'BackText', '回退', 1766, 30, 28, 16, 11, COLORS.text, FONT_MED);
    } else {
      diamond(bottom, 'LockSubmit_Diamond', 1510, 16, 44, COLORS.green, '锁定提交');
      ellipse(bottom, 'Autopilot_Round', 1624, 18, 40, 40, COLORS.gold);
      text(bottom, 'AutopilotText', '托管', 1630, 30, 28, 16, 11, '#FFFFFF', FONT_MED);
      ellipse(bottom, 'Back_Round', 1710, 22, 32, 32, COLORS.panel2, COLORS.gold);
      text(bottom, 'BackText', '回退', 1714, 32, 24, 12, 10, COLORS.text, FONT_MED);
    }
  }
}

function diamond(parent, name, x, y, size, color, label) {
  const poly = figma.createPolygon();
  poly.name = name;
  poly.pointCount = 4;
  poly.x = x;
  poly.y = y;
  poly.resize(size, size);
  poly.rotation = 45;
  poly.fills = paint(color);
  poly.strokes = stroke(color);
  parent.appendChild(poly);
  text(parent, `${name}_Label`, label, x - 26, y + 50, 100, 16, 11, COLORS.text, FONT_BOLD);
}

function createBudget(parent, mode) {
  rect(parent, 'TurnTimeBudgetBar_DisplayOnly', 340, 9, 1030, 44, COLORS.panel, COLORS.stroke, 8);
  for (let i = 0; i < 5; i++) {
    rect(parent, `DaySegment_${i+1}`, 352 + i * 196, 16, 188, 12, '#EAE0C7', null, 4);
    text(parent, `DayLabel_${i+1}`, `第 ${i+1} 天`, 352 + i * 196, 32, 60, 14, 10, COLORS.subtext, FONT_REG);
  }
  if (mode === 'cancelled') {
    text(parent, 'CancelledHint', '提示：已取消延续：闭关吐纳。再次进入规划阶段会重新读取可延续状态。', 360, 54, 700, 14, 11, COLORS.warn, FONT_MED);
  } else if (mode === 'locked') {
    text(parent, 'BudgetActionText', '只读预算：① 闭关吐纳｜延续   ② 前往黑石岭   ③ 探索矿脉', 360, 54, 800, 14, 11, COLORS.subtext, FONT_MED);
  } else {
    text(parent, 'BudgetActionText', '① 闭关吐纳｜延续   ② 前往黑石岭   ③ 探索矿脉｜剩余时间', 360, 54, 760, 14, 11, COLORS.subtext, FONT_MED);
  }
}

function createAutopilotPopover(parent) {
  const pop = frame(parent, 'AutopilotPopover_RightBottom', 1320, 690, 430, 250, COLORS.panel, COLORS.gold, 12);
  text(pop, 'AutopilotTitle', '托管摘要', 18, 18, 160, 24, 16, COLORS.text, FONT_BOLD);
  text(pop, 'AutopilotBody', '本回合将优先：\n- 保命 / 避险\n- 延续安全连续行动\n- 基础修炼或休整\n- 不暴露核心后手\n\n不会主动：\n- 发起大境界突破\n- 进入高危秘境\n- 回收高风险正式后手\n- 消耗稀有不可逆资源', 18, 52, 390, 150, 12, COLORS.subtext, FONT_REG);
  rect(pop, 'ConfirmAutopilot', 220, 212, 90, 30, COLORS.green, COLORS.green, 8);
  text(pop, 'ConfirmText', '确认托管', 240, 219, 60, 16, 12, '#FFFFFF', FONT_MED);
  rect(pop, 'CancelAutopilot', 320, 212, 70, 30, COLORS.panel2, COLORS.stroke, 8);
  text(pop, 'CancelText', '取消', 342, 219, 40, 16, 12, COLORS.subtext, FONT_MED);
}

function createStateFrame(page, name, x, stageLabel, options = {}) {
  const root = frame(page, name, x, 0, W, H, COLORS.bg, COLORS.stroke, 0);
  createTopBar(root, stageLabel);
  createMap(root);
  createLeftPanels(root, { collapsedGoal: options.collapsedGoal, collapsedGlobal: options.collapsedGlobal });
  if (!options.collapsedRight) createRightPanel(root, options.rightTab || '详情', options.readOnly);
  else {
    rect(root, 'RightPanelCollapsedTab_Node', 1886, 300, 34, 140, COLORS.panel, COLORS.stroke, 8);
    text(root, 'RightPanelCollapsedText', '节点', 1894, 330, 18, 80, 12, COLORS.text, FONT_BOLD);
  }
  createBottom(root, options.bottomMode || 'prepare');
  if (options.autopilot) createAutopilotPopover(root);
  return root;
}

function createComponentsPage() {
  const page = makePage('UI_MainFrame_Components_v0.9');
  const root = frame(page, 'Component_Specs', 0, 0, 1920, 1600, COLORS.bg, COLORS.stroke, 0);
  text(root, 'Title', '组件规格草案 v0.9', 40, 40, 400, 36, 24, COLORS.text, FONT_BOLD);
  createLeftPanels(root, {});
  createRightPanel(root, '短时行动');
  createBottom(root, 'planning');
  createAutopilotPopover(root);
  text(root, 'ComponentNote', '说明：本页为低保真组件骨架。行动卡暂不使用图片，优先保证参数选择与加入规划流程可靠。', 40, 1120, 1200, 40, 16, COLORS.subtext, FONT_MED);
}

function createFlowsPage() {
  const page = makePage('UI_MainFrame_Flows_v0.9');
  const root = frame(page, 'Flow_Specs', 0, 0, 1920, 1200, COLORS.bg, COLORS.stroke, 0);
  text(root, 'Title', '主界面状态流转 v0.9', 40, 40, 500, 36, 24, COLORS.text, FONT_BOLD);
  const steps = [
    ['准备阶段', '开始规划 / 托管'],
    ['规划阶段', '右侧行动卡设置参数并加入规划'],
    ['锁定提交', '进入等待锁定'],
    ['锁定等待', '可回退取消锁定'],
    ['服务端结算', '结算开始后不可回退'],
    ['回合结束报告', '原计划 vs 实际结果']
  ];
  steps.forEach((s, i) => {
    const x = 80 + i * 285;
    rect(root, `FlowStep_${i+1}`, x, 180, 230, 120, i === 4 ? '#FFF2D9' : COLORS.panel, COLORS.stroke, 12);
    text(root, `FlowTitle_${i+1}`, s[0], x + 18, 205, 190, 24, 16, COLORS.text, FONT_BOLD);
    text(root, `FlowBody_${i+1}`, s[1], x + 18, 242, 190, 42, 12, COLORS.subtext, FONT_REG);
    if (i < steps.length - 1) {
      const line = figma.createLine();
      line.name = `FlowArrow_${i+1}`;
      line.x = x + 236;
      line.y = 240;
      line.resize(52, 0);
      line.strokes = stroke(COLORS.gold);
      line.strokeWeight = 3;
      root.appendChild(line);
    }
  });
  text(root, 'BackLogic', '回退逻辑：锁定等待态先取消锁定 → 回到规划态；规划态逐条删除最后一条行动；队列为空后回退返回准备态。默认延续行动是普通编号行动，按普通行动删除。', 80, 380, 1200, 80, 16, COLORS.text, FONT_MED);
  text(root, 'AutopilotLogic', '托管逻辑：点击托管先显示右下弹层摘要，再确认。托管优先保命 / 避险 / 延续安全行动，不主动突破、高危秘境、高风险后手回收或稀有不可逆资源消耗。', 80, 480, 1200, 80, 16, COLORS.text, FONT_MED);
}

async function main() {
  await loadFonts();
  const page = makePage('UI_MainFrame_Rebuild_v0.9');
  await figma.setCurrentPageAsync(page);
  createStateFrame(page, 'State_01_Prepare_InfoProcessing_1920x1080', 0, '准备阶段｜信息处理', { bottomMode: 'prepare', rightTab: '详情' });
  createStateFrame(page, 'State_02_Planning_WithContinuation_1920x1080', 2000, '个人行动规划｜默认延续', { bottomMode: 'planning', rightTab: '长时行动' });
  createStateFrame(page, 'State_03_Planning_ContinuationCancelled_1920x1080', 4000, '个人行动规划｜已取消延续', { bottomMode: 'cancelled', rightTab: '短时行动' });
  createStateFrame(page, 'State_04_LockedWaiting_Readonly_1920x1080', 6000, '锁定等待｜已锁定', { bottomMode: 'locked', rightTab: '风险线索', readOnly: true });
  createStateFrame(page, 'State_05_AutopilotPreview_1920x1080', 8000, '托管确认｜摘要弹层', { bottomMode: 'planning', rightTab: '详情', autopilot: true });
  createStateFrame(page, 'State_06_SidePanelsCollapsed_1920x1080', 10000, '面板隐藏｜地图视口', { bottomMode: 'planning', collapsedGoal: true, collapsedGlobal: true, collapsedRight: true });
  createComponentsPage();
  createFlowsPage();
  figma.notify('Xiuxian main UI stage skeleton created: v0.9');
  figma.closePlugin();
}

main().catch((err) => {
  figma.notify(`Initializer failed: ${err && err.message ? err.message : err}`);
  figma.closePlugin();
});
