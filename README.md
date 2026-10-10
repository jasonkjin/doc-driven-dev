# doc-driven-dev

A document-driven development workflow for Claude Code: one shared skill plus ten slash commands that keep project state on disk instead of inside a long chat session. Every session starts by reading the docs and ends by writing results back, so sessions become disposable, work can run in parallel windows, and each new task in the same repo starts cheaper than the last. Documentation below is in Chinese.

**一句话:把项目状态写进文档,让会话变成一次性的消耗品。**

会话读文档开工、写文档收工,文档是会话之间唯一的交接物。由此:上下文更短、被推翻的结论不会在上下文里和新结论并存、任何新窗口都能加入、同一个仓库做的任务越多起步越快。

### 适合谁

维护几个较大的代码仓库、以需求单为单位做开发和维护的工程师。如果下面几条你中了两条以上,这套流程就是为你写的:

- 有一个不敢关的 Claude Code 会话,里面压着几个仓库的约定、几个需求的进度、昨天刚否掉的方案
- 上下文一压缩,AI 就忘了「生成代码别手改」「字段统一叫 X」这类约定
- 每开一个新窗口,都要把仓库背景重新讲一遍
- AI 自己写、自己测、自己说没问题,你不知道它没说的是什么

做一次性的小 demo 用不上:没有需要跨会话保留的状态,流程只是负担。

---

## 安装

```bash
git clone https://github.com/jasonkjin/doc-driven-dev.git
cd doc-driven-dev
./install.sh
```

`install.sh` 把 `skills/ddd/` 拷进 `~/.claude/skills/ddd/`、`commands/*.md` 拷进 `~/.claude/commands/`,已存在的同名文件先备份。也可以手动:

```bash
mkdir -p ~/.claude/skills/ddd ~/.claude/commands
cp skills/ddd/*.md ~/.claude/skills/ddd/
cp commands/*.md ~/.claude/commands/
```

工作区 `~/ddd/` 由 `/ddd-init` 首次运行时自动建立,独立于所有业务仓库,不进任何业务仓库的版本控制。**建议把 `~/ddd/` 初始化为私有 git 仓库**:文档是项目状态的唯一载体,而就地改文档、`/ddd-slim` 重写都会覆盖原内容,版本追溯与回滚全靠 git。

在 `~/ddd` 启动 Claude Code,通过 settings 或 `--add-dir` 授权业务仓库目录。

---

## 命令

| 命令 | 参数 | 作用 |
|---|---|---|
| `/ddd-init` | `<repo别名> [路径]` | 扫仓库生成长期档案。每个仓库一次,结构性变化时重跑 |
| `/ddd-spec` | `<槽位名>` | 进入任务,准备上下文后停下等需求。产出 requirement + spec |
| `/ddd-plan` | `<槽位名>` | 拆任务单元,验收下沉 |
| `/ddd-run` | `<槽位名> [单元...]` | 派 subagent 执行,并对 report 判档 |
| `/ddd-review` | `<槽位名> [单元...]` | 开发完成后独立复核。**必须新会话跑** |
| `/ddd-sync` | `<槽位名>` | 收尾守门,归档 |
| `/ddd-load` | `<槽位名>` | 新会话重建任务认知 |
| `/ddd-upstream` | `<槽位名>` | 拉取上游改动并过滤。**外部冲突的唯一防线** |
| `/ddd-audit` | `<repo别名>` | 校验仓库级文档与代码是否分叉 |
| `/ddd-slim` | `<槽位名>` | 把臃肿的任务文档重写成当下正确的形态 |

参数只需槽位名,编号由 `/ddd-spec` 自动分配。`/ddd-spec user-export` 对应 `work/001-user-export/`,之后用 `1`、`001` 或 `user-export` 都能指到它。

---

## 典型路径

```
一次性:   /ddd-init api-service /path/to/repo

每个任务:  /ddd-spec <名>
             → 描述需求(可多轮)
             → 产出 requirement.md   【确认点 1】
             → 契约澄清
             → 产出 spec.md          【控制点 2】
           /ddd-plan <名>            【过目 plan】
           /ddd-run <名> [单元...]     分批,可换会话
           /ddd-review <名>           必须换会话
           /ddd-sync <名>

新会话:    /ddd-load <名>
每天开工:  /ddd-upstream <名>
定期兜底:  /ddd-audit <repo>
文档臃肿:  /ddd-slim <名>
```

**两份文档的分工:** `requirement.md` 回答"要解决什么问题、系统怎么改",允许模糊、允许留待确认项。`spec.md` 回答"要交付什么",契约层不留白。

分两步是因为方向没定的时候讨论字段类型是过早的。需求明确且改动小时 requirement 可以写得很短,但不建议跳过,那是确认 agent 理解正确的最便宜的检查点。

---

## 目录结构

```
~/ddd/
  repos.md                      仓库注册表:别名 → 本地路径 / 远端 / 默认分支
  cross-repo-decisions.md       仅跨仓库决策

  projects/<repo别名>/           仓库长期档案｜慢变、必须正确、默认不写
    PROJECT.md                    定位、契约面、禁区、验收命令、反直觉约定
    contracts.md                  契约总账:在途 / 已生效
    decisions.md                  本仓库内决策,只追加不覆盖
    templates/                    按本仓库特化的 spec / report 模板

  work/<编号>-<槽位名>/           任务工作区｜快变、允许不完整、允许过期
    requirement.md                问题、目标、技术方案
    spec.md                       契约与验收
    plan.md                       单元划分、依赖、哪些可并行
    context.md                    涉及仓库、同步点、已确立的事实、参考文档索引
    reports/                      单元执行结果,重点是与 spec 的偏离
    review.md                     独立复核结果
    docs/                         调研、参考、草稿,须在 context.md 登记

  archive/                      归档,不是删除
```

两层的姿态完全不同:**任务级**允许不完整、允许过期、随便写;**仓库级**必须长期正确,且默认不写。仓库级文档的价值完全建立在它薄这个前提上。

---

## 追加与变更

命令序列不变,内部自动分流:

```
/ddd-spec <名>   → 识别已存在,输出状态摘要,等你描述变更
/ddd-plan <名>   → 增量补单元
/ddd-run <名> [新单元]
```

**文档一律原地改,不出 v2。** 历史在 git 里,始终要有一份东西回答"现在是什么"。

- `spec.md` 加变更记录,给读旧 report 的人对时间用
- 改变问题定义或技术方案时,`requirement.md` 也要更新
- plan 三条硬规则:编号只增不重排、作废用标记不删除、重做开新单元不复用编号
- 上游单元重做时下游已完成单元可能变脏,`/ddd-plan` 会检查并报告

---

## 三个会停下来问你的点

| 触发 | 关键判断 |
|---|---|
| 契约在途冲突 | 不自行绕开 |
| 追加需求推翻已定稿契约 | **该契约是否已合并默认分支**。未合并改原 spec,已合并且有外部依赖则新开任务 |
| spec 前提失效 | 不自行改 spec |

共同点:都会让已完成的工作作废。

---

## 内容归属速查

| 内容 | 位置 |
|---|---|
| 要解决什么问题、为什么 | `requirement.md` |
| 系统怎么改、为什么这么选、否决了什么 | `requirement.md` 技术方案 |
| 接口 / IDL / DB schema 精确定义 | `spec.md` 契约层 |
| 边界条件、错误时的可观测行为 | `spec.md` 行为层 |
| 改动哪些路径 | `plan.md` 范围 |
| 用什么数据结构、怎么分函数 | **不写** |
| 慢变事实(契约面、生成产物、禁区) | `PROJECT.md` |
| 单仓库内长期决策 | `projects/<repo>/decisions.md` |
| 跨仓库交互决策 | `cross-repo-decisions.md` |
| 调研、参考、测试方案、草稿 | `work/<任务>/docs/` + 登记进 `context.md` |

判断归属:**做另一个选择,后果是别人要跟着改,还是只是代码长得不一样。**

---

## docs/ 目录

任务工作区里有六个法定产物:`requirement.md`、`spec.md`、`plan.md`、`context.md`、`reports/`、`review.md`。
**其他一切文档落在 `work/<任务>/docs/`**,并在 `context.md` 的「参考文档」一节登记一行。

```
| 路径 | 用途 | 覆盖的代码路径 | 基线 | 产出者 |
```

后三列各被一条命令消费:覆盖路径给 `/ddd-upstream` 粗筛,基线给过期检测,产出者给 `/ddd-review` 定阅读次序。

**不登记的文档等于不存在**,没有命令会发现它。`/ddd-load` 会对账 `ls docs/` 与登记,对不上就报。

判据:**`docs/` 全删掉,流程仍能正确跑完,只是慢;法定产物删掉,流程会跑错。**

---

## 会话边界

除 `/ddd-spec` 的对话中途外,任何阶段之间都可以开新会话,唯一动作是 `/ddd-load`。

建议每个阶段都换会话,这是"状态存磁盘"的收益兑现方式。`/ddd-review` 必须换,因为复核者不能持有实现时的上下文。

如果 `/ddd-load` 重建的理解有误,**去修文档重开会话**,不要在当前会话里口头纠正后继续。那等于把状态放回了会话里。

---

## 两条覆盖所有文档的原则

- **只存代码里读不出来的东西。** 决策的理由、在途的变更、踩过的坑、「看起来能这么做但实际不行」的约定。能从代码推断的一律不写。
- **只记当下正确的结论,不记它是怎么变成正确的。** 结论错了就地改成对的,不留更正段;踩过的坑只留一句「不要做 X」。

存量已经臃肿时,跑 `/ddd-slim` 做一次性回收。

---

## 适用边界

并非所有改动都值得走全流程。判断标准是改动的不可逆程度,不是工作量:

- 改三行的 bugfix、加一条日志:直接做,不必开任务。
- 纯内部的重构,即使要写两千行,spec 可能只需半页。
- 只改三个字段但对外暴露的接口,spec 值得写一整页。
- 若 spec 的验收标准能被单个实现者一次跑通,就不用拆。

本方法是流程,不绑定具体工具。换 agent 或换模型之后,「状态落盘、契约先行、验收前置」几条依然成立,只是命令需要重写。

---

## License

MIT
