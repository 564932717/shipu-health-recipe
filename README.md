# 个性化健康食谱规划系统

本仓库用于团队协作开发“个性化健康食谱规划系统”。项目采用前后端分离结构：前端为 HarmonyOS NEXT 应用，后端为 Spring Boot 服务。

## 项目结构

```text
.
├── frontend/  # HarmonyOS NEXT 前端工程
├── backend/   # Spring Boot 后端工程
├── docs/      # 接口、数据库、测试用例、开发计划文档
└── README.md  # 项目说明
```

## 前端说明

前端目录：`frontend/`

开发工具：

- DevEco Studio
- HarmonyOS NEXT / ArkTS

主要代码位置：

```text
frontend/entry/src/main/ets/pages       # 页面
frontend/entry/src/main/ets/services    # 后端接口请求封装
frontend/entry/src/main/ets/common      # 数据模型与本地模拟数据
frontend/entry/src/main/resources       # 资源文件
```

已实现的主要页面与功能：

- 登录 / 注册
- 首页健康推荐概览
- AI 健康档案与体能评估
  - 身高、体重、年龄、性别录入
  - 慢病情况、饮食禁忌、健身目标录入
  - BMI、每日推荐热量、营养摄入比例计算
  - 健康画像生成
- 食谱中心
  - 推荐食谱
  - 食谱搜索
  - 收藏食谱
  - 浏览历史
- 饮食记录与统计
- 用户中心
  - 修改密码
  - 收藏 / 历史汇总
  - 跨设备同步开关

前端后端地址配置：

```text
frontend/entry/src/main/ets/services/ApiClient.ets
```

其中 `ApiClient.baseUrl` 是后端服务地址，团队成员需要根据自己电脑或服务器 IP 修改。

前端验证状态：

- 前端页面已本地测试通过。
- 若后端未启动，部分页面会显示后端连接失败或使用本地演示数据。

## 后端说明

后端目录：`backend/`

技术栈：

- Java
- Spring Boot
- Maven
- H2 / SQL 初始化脚本

主要代码位置：

```text
backend/src/main/java/com/xd/healthrecipe/domain       # 领域模型
backend/src/main/java/com/xd/healthrecipe/dto          # 请求和响应 DTO
backend/src/main/java/com/xd/healthrecipe/repository   # 数据访问层
backend/src/main/java/com/xd/healthrecipe/service      # 业务逻辑层
backend/src/main/java/com/xd/healthrecipe/web          # Controller 接口层
backend/src/main/resources                             # 配置、schema.sql、data.sql
backend/src/test                                       # 后端测试
```

后端主要接口：

- 用户登录：`POST /api/users/login`
- 用户注册：`POST /api/users/register`
- 修改密码：`POST /api/users/password`
- 用户中心汇总：`GET /api/users/{userId}/center`
- 收藏食谱：
  - `GET /api/users/{userId}/favorites`
  - `POST /api/users/{userId}/favorites/{recipeId}`
  - `DELETE /api/users/{userId}/favorites/{recipeId}`
- 浏览历史：
  - `GET /api/users/{userId}/recipe-history`
  - `POST /api/users/{userId}/recipe-history/{recipeId}`
- 同步开关：`POST /api/users/{userId}/sync-setting`
- 健康档案：`GET /api/profiles/{userId}`、`POST /api/profiles`
- 健康推荐：`POST /api/health/recommendations/day`
- 饮食记录与统计
- 周报生成

启动后端：

```powershell
cd backend
mvn -s .mvn\settings.xml spring-boot:run
```

或：

```powershell
cd backend
.\run-backend.ps1
```

运行后端测试：

```powershell
cd backend
mvn -s .mvn\settings.xml test
```

## 文档说明

文档目录：`docs/`

```text
docs/接口说明.md
docs/数据库设计.md
docs/测试用例.md
docs/两周开发计划.md
```

## 团队开发流程

推荐协作方式：

1. 每位成员先 clone 仓库。
2. 从 `main` 分支拉取最新代码。
3. 每个功能新建独立分支，例如：

```bash
git checkout -b feature/user-center
```

4. 修改完成后提交：

```bash
git add .
git commit -m "实现用户中心接口对接"
git push origin feature/user-center
```

5. 在 GitHub 上创建 Pull Request，由组员检查后合并到 `main`。

## 注意事项

- 不要提交本地缓存和依赖目录，例如 `oh_modules/`、`.hvigor/`、`target/`、`.m2/`。
- 不要提交个人 IDE 配置，例如 `.idea/`。
- 后端 IP 或端口变化时，需要同步修改前端 `ApiClient.baseUrl`。
- 数据库初始化脚本在 `backend/src/main/resources/schema.sql` 和 `backend/src/main/resources/data.sql`。
