import '../models/sop.dart';

const plazaCategories = ['全部', '个人效率', '门店运营', '工厂产线', '团队协作'];

final plazaTemplates = <SopTemplate>[
  SopTemplate(
    id: 'tpl-daily-review',
    title: '每日复盘清单',
    scene: '睡前 10 分钟',
    description: '个人效率入门模板：记录今日完成、明日重点与阻碍项。',
    category: '个人效率',
    illustration: 0,
    useCount: 1280,
    steps: [
      SopStep(title: '今日回顾', items: ['列出 3 件已完成的事', '记录 1 个可改进点']),
      SopStep(title: '明日计划', items: ['确定明日 Top 3', '预留缓冲时间']),
    ],
  ),
  SopTemplate(
    id: 'tpl-weekly-plan',
    title: '周计划制定',
    scene: '每周一上午',
    description: '把本周目标拆成可执行的 SOP 步骤，避免忙乱。',
    category: '个人效率',
    illustration: 1,
    useCount: 860,
    steps: [
      SopStep(title: '目标对齐', items: ['回顾上周完成情况', '列出本周 3 个核心目标']),
      SopStep(title: '任务拆分', items: ['每个目标拆成 3-5 步', '标注优先级']),
    ],
  ),
  SopTemplate(
    id: 'tpl-store-open',
    title: '门店开店标准',
    scene: '每日营业前',
    description: '适用于小型门店的开店检查，确保环境、设备、人员就绪。',
    category: '门店运营',
    illustration: 0,
    useCount: 2340,
    steps: [
      SopStep(title: '环境', items: ['开灯开空调', '清洁入口', '检查陈列']),
      SopStep(title: '设备', items: ['启动收银', '测试网络', '补打印纸']),
      SopStep(title: '人员', items: ['同步今日活动', '确认排班']),
    ],
  ),
  SopTemplate(
    id: 'tpl-store-close',
    title: '门店闭店清点',
    scene: '每日打烊后',
    description: '闭店时的收银、安全与卫生收尾流程。',
    category: '门店运营',
    illustration: 1,
    useCount: 1920,
    steps: [
      SopStep(title: '收银', items: ['核对当日流水', '完成日结']),
      SopStep(title: '安全', items: ['检查门窗', '关闭非必要电源']),
      SopStep(title: '卫生', items: ['清理操作台', '处理垃圾']),
    ],
  ),
  SopTemplate(
    id: 'tpl-line-start',
    title: '产线开班点检',
    scene: '每班开始前',
    description: '工厂流水线开班前的设备、物料与人员确认。',
    category: '工厂产线',
    illustration: 2,
    useCount: 3100,
    steps: [
      SopStep(title: '设备', items: ['开机自检', '确认参数设置', '润滑点检']),
      SopStep(title: '物料', items: ['核对工单', '确认物料批次', '备料到位']),
      SopStep(title: '人员', items: ['岗位签到', '安全提醒', '首件确认']),
    ],
  ),
  SopTemplate(
    id: 'tpl-quality-check',
    title: '工序质检记录',
    scene: '每批次产出后',
    description: '标准化质检步骤，减少漏检与记录缺失。',
    category: '工厂产线',
    illustration: 2,
    useCount: 2750,
    steps: [
      SopStep(title: '抽样', items: ['按标准抽取样品', '标记批次号']),
      SopStep(title: '检测', items: ['外观检查', '尺寸测量', '功能测试']),
      SopStep(title: '记录', items: ['填写质检表', '异常上报']),
    ],
  ),
  SopTemplate(
    id: 'tpl-meeting-prep',
    title: '会议准备清单',
    scene: '会议前 30 分钟',
    description: '团队会议前的资料、设备与议程确认。',
    category: '团队协作',
    illustration: 1,
    useCount: 980,
    steps: [
      SopStep(title: '资料', items: ['确认议程', '准备演示材料']),
      SopStep(title: '设备', items: ['测试投影/麦克风', '准备备用方案']),
    ],
  ),
  SopTemplate(
    id: 'tpl-onboard',
    title: '新人上岗引导',
    scene: '入职第一天',
    description: '帮助新员工快速熟悉岗位与环境的标准步骤。',
    category: '团队协作',
    illustration: 0,
    useCount: 720,
    steps: [
      SopStep(title: '环境', items: ['参观工作区', '介绍安全规范']),
      SopStep(title: '工具', items: ['账号开通', '工具培训']),
      SopStep(title: '任务', items: ['分配首周任务', '指定带教人']),
    ],
  ),
];

final learnArticles = <LearnArticle>[
  LearnArticle(
    id: 'learn-what-is-sop',
    title: '什么是 SOP？为什么个人也需要',
    summary: '把重复性工作写成清单，减少遗漏与决策疲劳。',
    tag: '入门',
    readMinutes: 3,
    body: '''SOP（Standard Operating Procedure）并不只是工厂或大公司的专利。

对个人来说，任何「每周都要做、步骤差不多、一忙就容易漏」的事情，都值得写成 SOP：
- 晨间开工准备
- 内容发布前的检查
- 每周复盘

写好 SOP 的核心不是写得多详细，而是**每一步可勾选、可执行、可复盘**。

建议从一件你本周已经做过 2 次以上的事开始，拆成 3 个阶段、每阶段 2-4 个检查项即可。''',
  ),
  LearnArticle(
    id: 'learn-how-to-create',
    title: '如何创建你的第一个 SOP',
    summary: '四步上手：选场景 → 拆步骤 → 试运行 → 迭代。',
    tag: '实操',
    readMinutes: 4,
    body: '''**第一步：选场景**
选一个频率高、步骤固定、出错代价不低的事情。

**第二步：拆步骤**
按时间或逻辑分成 2-4 个阶段，每阶段列出具体动作（动词开头更好）。

**第三步：试运行**
真正按清单走一遍，把漏掉的步骤补进去。

**第四步：迭代**
执行 3 次后回顾：哪些步骤多余？哪些需要合并？

在「我的 SOP」里点右下角新建，或从「SOP 广场」添加模板后再改。''',
  ),
  LearnArticle(
    id: 'learn-stick-to-it',
    title: '如何坚持执行 SOP',
    summary: '靠触发器、最小版本和记录，而不是靠意志力。',
    tag: '习惯',
    readMinutes: 3,
    body: '''坚持执行 SOP 的三个技巧：

1. **绑定触发器**：「每天开店前」比「有空就做」更容易坚持。
2. **最小可行版本**：先保留核心 5 步，跑通后再扩展。
3. **记录执行次数**：看到 runCount 增长会有正向反馈。

如果某条 SOP 连续一周没执行，要么缩小步骤，要么合并到别的流程里——不是失败，是优化信号。''',
  ),
  LearnArticle(
    id: 'learn-team-factory',
    title: '从个人到团队：SOP 如何扩展',
    summary: '个人清单 → 岗位标准 → 产线规范，同一套逻辑。',
    tag: '扩展',
    readMinutes: 4,
    body: '''SOP Island 优先服务个人用户，但同一套方法可以自然扩展：

- **个人**：管理自己的重复任务
- **小团队**：会议准备、新人引导、值班交接
- **门店/工厂**：开班点检、质检记录、闭店清点

扩展时关键是：**同一份 SOP 要让执行者能勾选完成，管理者能看执行记录**。

你可以先从广场添加「门店开店标准」或「产线开班点检」，改成适合自己环境的版本。''',
  ),
  LearnArticle(
    id: 'book-checklist-manifesto',
    title: '《清单革命》：把关键步骤写出来',
    summary: '复杂工作不是靠记忆完成，而是靠关键检查点降低遗漏。',
    tag: '书籍',
    readMinutes: 8,
    body: '''这本书最适合转化成 SOP 的地方，是「清单不是替代专业能力，而是保护关键步骤不被跳过」。

可提炼成 10 个 SOP 知识点：
1. SOP 应优先覆盖高风险、高频率、易遗漏的关键动作。
2. 好清单不是百科全书，而是提醒最容易被跳过的要点。
3. 检查项要能被明确判断：完成或未完成。
4. 流程越复杂，越需要把关键节点从脑内记忆移到外部清单。
5. SOP 应区分「读后执行」和「边做边确认」两种使用场景。
6. 执行前的短暂停顿，可以避免带着错误状态进入下一步。
7. 团队 SOP 要明确谁发起、谁确认、何时开始。
8. 清单需要在真实场景中试运行，而不是只在会议室里设计。
9. SOP 失败后不要只追责，要检查清单是否漏掉了关键提醒。
10. 每次异常都是优化 SOP 的素材，应记录并回填到流程里。''',
  ),
  LearnArticle(
    id: 'book-e-myth',
    title: '《E-Myth》：把经验变成系统',
    summary: '小团队也需要可复制的做事方式，而不是只依赖某个能人。',
    tag: '书籍',
    readMinutes: 8,
    body: '''这本书对 SOP 的启发是：业务能稳定复制，靠的不是某个人很厉害，而是系统能让普通人按标准完成关键工作。

可提炼成 10 个 SOP 知识点：
1. SOP 的目标是让工作可复制，而不是把人管死。
2. 先写「最小可运行流程」，再逐步补充细节。
3. 如果一件事只能由某个人完成，就还没有形成系统。
4. SOP 应包含输入、动作、输出，而不只是动作列表。
5. 新人能否照着完成，是检验 SOP 清晰度的重要标准。
6. 每条 SOP 都应该对应一个具体业务结果。
7. 把关键经验写下来，可以降低培训成本和交接风险。
8. 标准化不是为了消灭创造力，而是让基础动作稳定。
9. 管理者应定期检查流程，而不是只检查人是否努力。
10. 当业务变化时，SOP 也要成为持续迭代的产品。''',
  ),
  LearnArticle(
    id: 'book-work-the-system',
    title: '《Work the System》：从系统视角写 SOP',
    summary: '把组织看成多个可观察、可调整的小系统。',
    tag: '书籍',
    readMinutes: 9,
    body: '''这本书非常适合做 SOP 方法论：先识别系统，再记录系统，最后持续优化系统。

可提炼成 10 个 SOP 知识点：
1. 先把工作拆成独立系统，再为每个系统写 SOP。
2. 每条 SOP 都要有负责人，没人负责的流程会自然失效。
3. 流程文件要短、清楚、能被实际执行者看懂。
4. SOP 应描述当前最佳做法，而不是理想中的完美做法。
5. 发现反复出错的地方，通常说明系统设计不清。
6. 把流程外显出来，团队才有共同优化的对象。
7. SOP 不应只放在文档库里，而要嵌入日常执行入口。
8. 更新流程要有版本意识，避免多人使用不同标准。
9. 系统改进应从小处开始，先修复最频繁的摩擦点。
10. 管理不是不停救火，而是减少未来需要救火的次数。''',
  ),
  LearnArticle(
    id: 'book-traction',
    title: '《Traction》：让 SOP 进入团队节奏',
    summary: '流程、目标、责任和例会要连接起来，SOP 才能长期运行。',
    tag: '书籍',
    readMinutes: 8,
    body: '''这本书强调运营系统。对 SOP 来说，重点是把流程放进团队的目标、角色和节奏里。

可提炼成 10 个 SOP 知识点：
1. SOP 要服务明确目标，否则容易变成形式主义文档。
2. 关键流程应绑定负责人，负责人负责维护和复盘。
3. 团队需要统一流程语言，减少每个人各做各的。
4. SOP 可以和周会、复盘、指标看板连接起来。
5. 重复性问题应进入问题清单，再转化为流程改进。
6. 流程是否有效，要看结果指标，而不只看是否写得完整。
7. 一次只优化少数关键流程，避免全员被文档淹没。
8. 角色职责不清时，SOP 执行会出现推诿和空档。
9. 团队应定期删除过时流程，保持流程库轻量。
10. SOP 的最终目的，是让团队执行更稳定、更可预测。''',
  ),
  LearnArticle(
    id: 'book-toyota-way',
    title: '《丰田模式》：标准化与持续改善',
    summary: '标准作业不是终点，而是下一轮改善的起点。',
    tag: '书籍',
    readMinutes: 9,
    body: '''这本书适合理解现场管理、标准作业和持续改善之间的关系。

可提炼成 10 个 SOP 知识点：
1. 没有标准，就很难判断什么叫改善。
2. SOP 应贴近现场，不能脱离真实工作条件。
3. 执行者的反馈是优化 SOP 的重要来源。
4. 标准化不是固定不变，而是当前最优做法的暂存。
5. 发现异常时，要追问流程原因，而不是只看表面结果。
6. SOP 可以帮助新人更快达到稳定水平。
7. 流程应尽量减少等待、返工、搬运和重复确认。
8. 视觉化提示能降低执行者的记忆负担。
9. 小步改善比一次性大改更容易被团队接受。
10. 好 SOP 会让问题更早暴露，而不是把问题藏起来。''',
  ),
  LearnArticle(
    id: 'book-out-of-the-crisis',
    title: '《走出危机》：用质量视角看 SOP',
    summary: '流程质量决定结果稳定性，不能只靠个人努力补救。',
    tag: '书籍',
    readMinutes: 9,
    body: '''这本书适合帮助我们理解：很多执行问题不是个人态度问题，而是系统和流程质量问题。

可提炼成 10 个 SOP 知识点：
1. 结果不稳定时，先检查流程是否稳定。
2. SOP 应减少人为解释空间，降低执行差异。
3. 质量不能只靠最后检查，而要嵌入每个关键步骤。
4. 管理者要改进系统，而不是只要求员工更努力。
5. 数据能帮助判断流程是否真的变好。
6. 异常记录应成为流程改进输入，而不是被忽略。
7. 培训和 SOP 要配套，否则标准无法真正落地。
8. 频繁返工通常说明前置检查点不足。
9. 流程指标应关注稳定性、缺陷和返工，而不只是速度。
10. 持续改进需要长期节奏，不是一次运动式整改。''',
  ),
  LearnArticle(
    id: 'book-the-goal',
    title: '《目标》：找到流程瓶颈',
    summary: '优化 SOP 时，不要平均用力，要先看限制整体产出的环节。',
    tag: '书籍',
    readMinutes: 8,
    body: '''这本书的约束理论很适合用来优化 SOP：流程中最慢或最受限的环节，往往决定整体表现。

可提炼成 10 个 SOP 知识点：
1. 先明确流程目标，再判断哪里需要优化。
2. 找到瓶颈步骤，比平均优化每一步更重要。
3. 非瓶颈环节提速，不一定能提升整体结果。
4. SOP 应标出关键等待点、审批点和资源限制点。
5. 瓶颈前要减少无效输入，避免堆积。
6. 瓶颈步骤应优先保证稳定、清晰、少打扰。
7. 流程优化后，新的瓶颈可能会转移。
8. 看局部效率时，也要看整体交付是否改善。
9. SOP 可以记录每一步耗时，帮助发现真实瓶颈。
10. 优化流程应形成循环：识别约束、改进约束、重新观察。''',
  ),
  LearnArticle(
    id: 'book-business-process-improvement',
    title: '《业务流程改进》：系统优化流程',
    summary: '从识别流程、画出流程，到分析问题、持续优化。',
    tag: '书籍',
    readMinutes: 9,
    body: '''这本书适合把 SOP 从「写清单」推进到「改流程」。

可提炼成 10 个 SOP 知识点：
1. 写 SOP 前，先定义流程边界：从哪里开始，到哪里结束。
2. 每个流程都应有输入、活动、输出和客户。
3. 画出流程图能帮助发现重复、等待和责任断点。
4. 关键流程应优先标准化，而不是所有流程同时推进。
5. 流程指标要和用户感受到的结果有关。
6. 访谈执行者能发现文档里看不到的实际绕路。
7. SOP 应记录异常处理方式，而不只写顺利路径。
8. 改流程前要先知道当前流程真实长什么样。
9. 优化后要复盘效果，确认问题是否真的减少。
10. 流程改进应形成闭环：记录、分析、调整、验证。''',
  ),
  LearnArticle(
    id: 'book-bpm-profiting-from-process',
    title: '《BPM》：把流程变成组织能力',
    summary: 'SOP 不只是个人清单，也可以连接角色、规则和绩效。',
    tag: '书籍',
    readMinutes: 8,
    body: '''这本书适合从业务流程管理视角理解 SOP：流程不是孤立文档，而是组织如何交付价值的方式。

可提炼成 10 个 SOP 知识点：
1. SOP 应连接业务目标，而不是只描述动作。
2. 流程要跨角色设计，避免只优化单个岗位。
3. 规则、权限和判断标准应写进关键步骤。
4. 流程负责人负责整体表现，而不只是某一步。
5. 流程指标应覆盖效率、质量、成本和体验。
6. 端到端流程视角能减少部门之间的断点。
7. SOP 可以作为培训、审计和改进的共同基础。
8. 复杂流程需要分层：总览、阶段、检查项。
9. 自动化前应先把流程定义清楚。
10. 流程管理的价值，在于让组织能力可重复、可衡量。''',
  ),
  LearnArticle(
    id: 'book-lean-six-sigma-toolbook',
    title: '《精益六西格玛工具书》：用工具优化 SOP',
    summary: '把 5S、流程图、鱼骨图、DMAIC 等方法转成 SOP 改进动作。',
    tag: '书籍',
    readMinutes: 9,
    body: '''这类工具书适合当 SOP 优化工具箱：遇到不同问题，选择不同分析方法。

可提炼成 10 个 SOP 知识点：
1. 用流程图看清步骤顺序、等待和返工。
2. 用 5S 优化现场类 SOP，让物品、工具和环境更容易执行。
3. 用鱼骨图分析反复出错的原因。
4. 用 DMAIC 做系统改进：定义、测量、分析、改进、控制。
5. 用检查表收集真实执行数据，而不是凭感觉判断。
6. 用帕累托思路优先解决最常见或影响最大的错误。
7. 用标准作业减少不同人之间的执行差异。
8. 用防错设计减少依赖记忆的步骤。
9. 用控制计划确保改进后的流程不会回退。
10. 工具不是越多越好，关键是为当前 SOP 问题选择合适方法。''',
  ),
];

final efficiencyPosts = <EfficiencyPost>[
  EfficiencyPost(
    id: 'eff-pomodoro',
    title: '番茄工作法：25 分钟专注 + 5 分钟休息',
    summary: '适合需要深度专注的任务，配合 SOP 清单效果更好。',
    category: '时间管理',
    readMinutes: 3,
    body: '''番茄工作法简单有效：
1. 选一个任务（可对应一条 SOP 的某个阶段）
2. 设定 25 分钟专注，期间只做这一件事
3. 休息 5 分钟，4 个番茄后长休息 15-20 分钟

与 SOP 结合：把「运行」模式当成一个番茄周期，完成一个阶段再休息，减少中途切换。''',
  ),
  EfficiencyPost(
    id: 'eff-two-minute',
    title: '两分钟法则：立刻处理小事',
    summary: '能在两分钟内完成的事，马上做掉，避免堆积。',
    category: '个人效率',
    readMinutes: 2,
    body: '''如果某件事能在两分钟内完成（回一条消息、归档一个文件），立即处理。

否则它会占用心智带宽。对于重复出现的「两分钟任务」，可以收进 SOP 的某个检查项，批量在固定时段处理。''',
  ),
  EfficiencyPost(
    id: 'eff-batch',
    title: '批处理：把同类任务放在一起',
    summary: '减少上下文切换，适合邮件、审批、巡检等重复工作。',
    category: '工作方法',
    readMinutes: 3,
    body: '''上下文切换是效率杀手。批处理原则：
- 固定时段处理邮件/消息
- 同类 SOP 连续执行（如上午只做巡检类）
- 准备阶段和执行阶段分开

在 SOP Island 里，你可以把相关 SOP 的执行时间写在「场景」字段里，形成自己的批处理节奏。''',
  ),
  EfficiencyPost(
    id: 'eff-5s',
    title: '5S 与现场管理：整理、整顿、清扫、清洁、素养',
    summary: '工厂与门店常用的现场管理框架，可写成 SOP 步骤。',
    category: '工厂/门店',
    readMinutes: 5,
    body: '''5S 起源于现场管理，对个人工作区同样适用：

- **整理（Seiri）**：区分要与不要
- **整顿（Seiton）**：物有其位
- **清扫（Seiso）**：保持清洁
- **清洁（Seiketsu）**：标准化
- **素养（Shitsuke）**：养成习惯

可将「开店/闭店/班前点检」SOP 与 5S 对应，让步骤更清晰、可培训。''',
  ),
  EfficiencyPost(
    id: 'eff-checklist-manifesto',
    title: '《清单革命》：复杂工作靠清单降低错误',
    summary: '航空、医疗、建筑行业验证过的方法，个人同样受益。',
    category: '方法论',
    readMinutes: 4,
    body: '''阿图·葛文德在《清单革命》中指出：即使专家也会遗漏关键步骤。

清单的价值不是限制创造力，而是**保证底线步骤不被跳过**。

你的 SOP 就是个人版清单。执行时逐步勾选，比凭记忆可靠得多。''',
  ),
  EfficiencyPost(
    id: 'eff-energy',
    title: '按精力安排任务，而非只按时间',
    summary: '高精力时段做决策型 SOP，低精力时段做检查型 SOP。',
    category: '个人效率',
    readMinutes: 3,
    body: '''观察自己一天中何时最清醒：
- 高精力：规划、创作、复杂决策（如周计划 SOP）
- 中精力：协作、沟通（如会议准备 SOP）
- 低精力：检查、归档、巡检（如设备点检 SOP）

把「运行」安排在匹配的时段，完成率会明显提高。''',
  ),
];

SopTemplate? findPlazaTemplate(String id) {
  for (final t in plazaTemplates) {
    if (t.id == id) return t;
  }
  return null;
}

LearnArticle? findLearnArticle(String id) {
  for (final a in learnArticles) {
    if (a.id == id) return a;
  }
  return null;
}

EfficiencyPost? findEfficiencyPost(String id) {
  for (final p in efficiencyPosts) {
    if (p.id == id) return p;
  }
  return null;
}
