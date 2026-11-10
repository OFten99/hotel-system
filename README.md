# 酒店人事一体化综合管理系统

Flask + MySQL 8

把「客房业务」和「人事管理」放在同一套数据模型里打通：前台办理入住退房，客房部处理工单与房态，
人事管理员工与考勤排班，财务核算薪资并出报表。业务规则尽量下沉到数据库层，用存储过程保证
入住、退房、发薪这类跨多表操作的原子性，用触发器维护房态、账号与日志的一致性。

## 功能

**前台**
- 客房台账：房型、房号、价格、状态（空闲 / 占用 / 维修）
- 入住办理：客户登记 + 开单 + 占用房态（`sp_checkin`）
- 退房结算：汇总消费明细、释放房态（`sp_checkout`）
- 客户档案：查询 / 新增 / 修改 / 删除

**人事**
- 员工档案与登录账号同步创建（`sp_add_employee`）
- 排班、考勤打卡、请假、加班记录
- 员工离职自动锁定其账号（`trg_employee_leave_lock_account`）

**财务**
- 月度薪资核算：基本工资 + 出勤 + 加班 − 请假扣款（`sp_calculate_monthly_salary`）
- 发薪并写入发放流水（`sp_pay_salary`）
- 营收报表与导出（`/reports`、`/export/<name>`）

**经理**
- 全量业务数据与统计视图

## 技术栈

| 层次 | 选型 |
| --- | --- |
| 语言 | Python 3.10+ |
| Web 框架 | Flask 3.x |
| 数据库 | MySQL 8.0+ |
| 驱动 | mysql-connector-python 8.3+ |
| 前端 | Jinja2 模板 + 原生 CSS（无构建步骤） |

## 目录结构

```
hotel system/
├── sql/                         数据库脚本，按编号顺序执行
│   ├── 01_create_database.sql   建库与字符集
│   ├── 02_create_tables.sql     19 张表
│   ├── 03_views.sql             4 个统计视图
│   ├── 04_procedures.sql        5 个存储过程
│   ├── 05_triggers.sql          4 个触发器
│   ├── 06_indexes_queries.sql   索引与示例查询
│   └── 07_seed_data.sql         种子数据（6 名员工及登录账号）
├── web_app/                     Flask Web 端
│   ├── app.py                   路由与业务编排
│   ├── db.py                    连接池与查询封装
│   ├── templates/               12 个页面模板
│   ├── static/style.css
│   └── exports/                 报表导出目录（内容不入库）
├── python/                      命令行端（对应 run_cli.bat）
├── init_database.py             一键建库：依次执行 sql/ 下全部脚本
├── check_env.py                 环境自检：Python 版本、依赖、数据库连通性
├── start_mysql.bat              启动本地 MySQL
├── run_web.bat                  启动 Web 端
├── run_cli.bat                  启动命令行端
├── change_port.py               修改 Web 端口
└── 运行说明.md                  部署细节与常见问题
```

## 数据库设计

**表（19）**
`departments` `positions` `roles` `employees` `user_accounts` `room_types` `rooms`
`customers` `checkin_orders` `consumption_items` `work_orders` `schedules` `attendance_records`
`leave_records` `overtime_records` `salary_records` `salary_payments` `operation_logs`

**视图（4）**
`v_monthly_room_revenue` · `v_employee_monthly_attendance_summary`
`v_current_occupied_rooms` · `v_employee_performance_summary`

**存储过程（5）**
`sp_add_employee` · `sp_checkin` · `sp_checkout` · `sp_calculate_monthly_salary` · `sp_pay_salary`

**触发器（4）**
`trg_employee_leave_lock_account` · `trg_checkout_update_room_status`
`trg_work_order_insert_log` · `trg_work_order_finish_update_room`

设计上的几个取舍：

- 员工、账号、角色拆三张表，`user_accounts` 只存登录所需的最小信息，权限靠 `roles.role_code` 判定
- 入住单与消费明细分离，退房时由存储过程汇总，避免金额散落在多处
- 房态不做冗余字段同步，交给触发器在退房、工单完成时统一维护，减少应用层遗漏
- 所有写操作留痕到 `operation_logs`，便于按员工追溯

## 快速开始

需要本地 MySQL 8 已在 `127.0.0.1:3306` 启动。

```bash
python init_database.py      # 建库：依次执行 sql/ 下 7 个脚本，可重复执行
run_web.bat                  # 启动，浏览器打开 http://127.0.0.1:5001
run_cli.bat                  # 或使用命令行端
```

连接参数可以显式指定：

```bash
python init_database.py --host 127.0.0.1 --port 3306 --user root --password 你的密码
```

## 登录

| 账号 | 角色 |
| --- | --- |
| `front01` | 前台 |
| `room01` / `room_mgr` | 客房 / 客房主管 |
| `finance01` | 财务 |
| `manager01` | 经理 |

演示账号密码统一为 `123456`。`manager01` 会被演示数据里的离职流程锁定，需要时可参照 `运行说明.md` 恢复。

## 配置

数据库连接从环境变量读取，未设置时回落到本地默认值：

| 变量 | 默认值 |
| --- | --- |
| `HOTEL_DB_HOST` | `127.0.0.1` |
| `HOTEL_DB_PORT` | `3306` |
| `HOTEL_DB_USER` | `root` |
| `HOTEL_DB_PASSWORD` | `123456` |

Web 端口在 `web_app/app.py` 末尾指定（5001），也可用 `change_port.py` 修改。

## 更多说明

- 部署细节与常见报错：`运行说明.md`、`web_app/网页端运行说明.md`
- 环境自检：`python check_env.py`

## 许可

本项目著作权归作者所有，仅供学习与技术参考，禁止商业使用与抄袭。
