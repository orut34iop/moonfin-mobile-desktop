# 高级筛选能力（Advanced Filter）移植文档

**用途：** 从 commit `3665a74` 到 `854d302` 的完整“高级筛选能力”修改集合（非 diff 形式）。

**时间范围：** 2026-06-05 15:02:07 ~ 2026-06-05 20:53:25

**目标：** 在另一条 moonfin 分支上完整复现“高级筛选”特性，并保证行为与原实现一致。

---

## 一、按时间顺序的 commit 列表（按用户要求保留，按提交时间）

1. `3665a74` — Add advanced media filtering
   - 核心：首次引入高级筛选界面、默认 VM、路由入口、左侧导航和顶部工具栏入口、基础本地化与筛选初始加载。

2. `65df3b2` — Add advanced filter result sorting
   - 核心：结果排序（名称/年份）、排序方向（升序/降序）、排序持久化。

3. `f5ad546` — Scope advanced filter cache by user
   - 核心：缓存与配置范围改为按 `serverId + userId` 作用域。

4. `47ab09f` — Cache advanced filter catalog locally
   - 核心：新增本地持久化数据库（Drift 表）、离线目录仓储 API、SQLite 缓存优先加载。

5. `1c90424` — Add advanced filter cache refresh sync
   - 核心：新增全量刷新、增量刷新机制；监听 WebSocket 事件；Session 下线/切换后刷新服务启动。

6. `aa50008` — Add advanced filter performance logging
   - 核心：新增专用性能日志服务（IO/stub），覆盖加载、刷新、同步流程关键耗时。

7. `f86ff40` — Optimize advanced filter preference persistence
   - 核心：偏好写入改为延迟/串行化写，减少 UI 抖动与重复磁盘操作。

8. `0cc4b54` — Clear all legacy advanced filter caches
   - 核心：新增偏好 key 列表清理能力，迁移期清理旧版共享偏好缓存。

9. `3a3a91a` — Require all selected advanced filter metadata
   - 核心：对多值选择（如风格/标签）要求“AND 全部匹配”。

10. `eaad6c2` — Update advanced filter option facets
    - 核心：筛选面板的可选项依赖当前结果动态收敛；库选项、年份、体裁、地区联动更新。

11. `854d302` — Show all detail title genres
    - 核心：详情页标题处可点击标签由“前 N 个”改为“全部 genre”并复用高级筛选入口。

---

## 二、总览：迁移范围与文件清单（按模块）

### 数据层（Repository/Service）
- `lib/data/models/aggregated_item.dart`（已存在类型，供过滤模型使用）
- `lib/data/repositories/advanced_filter_catalog_repository.dart`
- `lib/data/services/advanced_filter_catalog_sync_service.dart`
- `lib/data/services/advanced_filter_catalog_constants.dart`
- `lib/data/services/advanced_filter_perf_logger.dart`
- `lib/data/services/advanced_filter_perf_logger_io.dart`
- `lib/data/services/advanced_filter_perf_logger_stub.dart`

### 本地数据库（离线缓存）
- `lib/data/database/offline_database.dart`
- `lib/data/database/offline_database.g.dart`

### UI 与导航
- `lib/ui/screens/filter/advanced_filter_screen.dart`
- `lib/ui/navigation/destinations.dart`
- `lib/ui/navigation/app_router.dart`
- `lib/ui/widgets/left_sidebar.dart`
- `lib/ui/widgets/top_toolbar.dart`
- `lib/ui/screens/detail/item_detail_screen.dart`

### 视图模型（业务逻辑）
- `lib/data/viewmodels/advanced_filter_view_model.dart`

### 偏好与生命周期
- `lib/preference/user_preferences.dart`
- `packages/preference/lib/src/store/preference_store.dart`
- `lib/di/injection.dart`
- `lib/di/modules/app_module.dart`
- `lib/auth/repositories/session_repository.dart`

### 本地化（至少中文 + 英文）
- `lib/l10n/app_en.arb`
- `lib/l10n/app_localizations.dart`
- `lib/l10n/app_localizations_af.dart` …… `lib/l10n/app_zh-Hans.arb`、`lib/l10n/app_zh-Hant.arb`、`lib/l10n/app_zh.arb`

### 测试
- `test/browse/advanced_filter_view_model_test.dart`
- `test/detail/item_detail_title_genres_test.dart`

### 文档与说明文案
- `README.md`（变更说明条目）

---

## 三、核心设计与迁移顺序（可直接照着执行）

### 步骤 1：先建立数据库与数据层

1. 在数据库中新增 4 张表，并升高 schema 版本：
   - `AdvancedFilterCatalogItems`
   - `AdvancedFilterCatalogItemGenres`
   - `AdvancedFilterCatalogItemRegions`
   - `AdvancedFilterCatalogSyncStates`
2. 实现 `MigrationStrategy.onUpgrade`（from <2 创建新表）。
3. 生成/更新 `offline_database.g.dart`。
4. 实现 `AdvancedFilterCatalogRepository`：
   - `loadSnapshot` / `replaceScope` / `upsertItems` / `removeItems` / `clearScope` / `hasScope` / `isExpired`。
   - 缓存内容包括：主表元数据 JSON、排序名、年份、分类库/流派/地区映射。
5. 实现 `AdvancedFilterCatalogSyncService`：
   - `refreshCatalog`（全量刷新）
   - `refreshIfStale`（过期检测后触发）
   - `LibraryChangedMessage/UserDataChangedMessage` 增量更新处理
   - `refreshId` 队列 + 防抖 + 分批（100）抓取
   - 支持 Jellyfin + Emby 的抓取策略差异（Emby 分库采集 + 兜底全量）。
6. 增加 `AdvancedFilterCatalogConstants`：媒体类型常量、字段集合、分页大小、Emby 注入字段。
7. 加入性能日志服务（`_io` 与 `stub` 分离平台）。

### 步骤 2：实现高级筛选 ViewModel（核心业务行为）

文件：`lib/data/viewmodels/advanced_filter_view_model.dart`

实现以下行为顺序：

1. 生命周期与状态
   - `AdvancedFilterLoadState`、`AdvancedFilterSortField`。
   - `load`：先尝试恢复偏好 -> 应用 route 初始条件 -> 命中本地仓储缓存 -> 不命中则刷新。
   - 错误/加载/就绪三态切换。

2. 缓存优先级策略
   - 先读 `LoadSnapshot(serverId,userId)`。
   - 仍未命中再尝试旧版共享偏好缓存（`advancedFilterCache_*`）并写入新数据库。
   - 命中缓存后若过期触发后台刷新，不阻塞当前结果。

3. 过滤与排序
   - 支持类型/流派/地区/库/年份交互筛选。
   - `type`/`year` 单选（互斥），其他可多选（按选中项收敛）。
   - `year`、`genre`、`region`、`year` 可跨项目交集/并集策略按照最终实现。
   - 排序字段：`name` / `year` + 正反向。

4. 过滤逻辑（关键契约）
   - `type`、`year` 为单值匹配。
   - `genre`、`region` 是“全部命中”语义（多选时 item 必须同时包含全部已选项）。
   - 库选项 `showLibraryFilter` 只在 Emby 上显示。

5. 动态 facet 刷新
   - `types/genres/regions/libraries/years` 的候选项来自当前结果集，能随条件变化收敛。
   - 选项变化时会自动剔除不可用的已选项。

6. 会话与库/用户隔离
   - preference key 按 `serverUrl::userId` 作用域。
   - 排序/筛选状态也按该 scope 保存。

7. 缓存脏写优化
   - 设置偏好改为“延迟+串行”提交，避免频繁 I/O。

8. 旧数据迁移
   - `legacy cache clear`：按 key 前缀批量清理 `advanced_filter_cache_*`。
   - 仅在首次成功保存新库存时执行清理。

### 步骤 3：同步服务与会话生命周期接线

1. `lib/data/services/advanced_filter_catalog_sync_service.dart` 的 `start()` 与 `dispose()`。
2. 在用户会话切换逻辑中启动：`lib/auth/repositories/session_repository.dart`
   - `SetIt.instance<AdvancedFilterCatalogSyncService>().start()`。
3. 在用户级依赖里注册服务：`lib/di/modules/app_module.dart`
   - 注入 `AdvancedFilterCatalogSyncService`。
   - `resetUserScopedSingletons()` 时注销旧服务。

### 步骤 4：UI 与导航接入

1. 路由与参数
   - `lib/ui/navigation/destinations.dart`
     - 新增 `advancedFilter = '/advanced-filter'`。
     - 增加 `advancedFilterWith({genres,year})` 构造 query url。
   - `lib/ui/navigation/app_router.dart`
     - 新增 GoRoute 到 `AdvancedFilterScreen`。
     - 路由参数：`genre` 多值、`year`。

2. 新增筛选页
   - `lib/ui/screens/filter/advanced_filter_screen.dart`
     - 筛选行（类型/库/流派/地区/年份）
     - 刷新按钮
     - 加载中/错误/空结果状态
     - 网格结果区
     - 多列响应式布局、结果数/排序控件。

3. 全局导航入口
   - `left_sidebar.dart` 添加高级筛选项。
   - `top_toolbar.dart` 添加高级筛选按钮。

### 步骤 5：偏好系统扩展

1. `lib/preference/user_preferences.dart`
   - 新增：
     - `advancedFilterTypes`
     - `advancedFilterGenres`
     - `advancedFilterRegions`
     - `advancedFilterLibraries`
     - `advancedFilterYears`
     - `advancedFilterApplied`
     - `advancedFilterSortField`
     - `advancedFilterSortAscending`
     - `advancedFilterCache`
     - `advancedFilterCacheKeyPrefix`
2. `packages/preference/lib/src/store/preference_store.dart`
   - 新增 `removePreferenceKeys(Set<String>)`：用 `SharedPreferencesAsync.clear(allowList)` 批量删除。
3. `ViewModel` 里确保 key suffix 为 `serverId` 归一化。

### 步骤 6：细节页入口

- `lib/ui/screens/detail/item_detail_screen.dart`
  - `detailTitleGenres(AggregatedItem)` 仅做 trim + non-empty，不再截断（`take(3)` 已移除）。
  - 点击任意 genre 标签打开高级筛选：`Destinations.advancedFilterWith(genres: genres, year: item.productionYear)`。

### 步骤 7：本地化接入

- 同步新增 `advancedFilter*` 文案：
  - `advancedFilter`, `advancedFilterByType`, `advancedFilterByGenre`, `advancedFilterByLibrary`, `advancedFilterByRegion`, `advancedFilterByYear`
  - `advancedFilterMovie`, `advancedFilterSeries`
  - `advancedFilterLoading`, `advancedFilterLoadFailed`, `advancedFilterResultsCount`, `advancedFilterSortByName`, `advancedFilterSortByYear`, `advancedFilterSortAscending`, `advancedFilterSortDescending`
- 至少覆盖英文与多语言文件，当前实现中覆盖范围为 `app_en + 全量语言文件`，同时更新 `app_localizations.dart` 与生成产物。

### 步骤 8：测试移植

- `test/detail/item_detail_title_genres_test.dart`
  - 验证全部 genre 保留、不被截断。
  - 验证 `advancedFilterWith()` 路由参数。
- `test/browse/advanced_filter_view_model_test.dart`
  - 覆盖点：默认加载、默认排序、路由初始条件覆盖持久化、筛选持久化、结果排序、动态 facet 收敛、数据库本地缓存复用、失效自动刷新、跨用户隔离、WebSocket 增量更新。

---

## 四、推荐迁移执行清单（最少遗漏版）

### 先决条件
1. 新分支已包含基础依赖与数据库打开逻辑。
2. 已有 `drift/native`、`drift`、`server_core`、`shared_preferences`、`get_it` 相关依赖。

### 逐项执行（建议）
1. 先完成数据库和仓储/服务文件。
2. 增加偏好 API 与 PreferenceStore 删除能力。
3. 注册 DI（`injection + app_module`），并确保 session 切换时启动同步服务。
4. 接入路由与导航入口。
5. 接入筛选界面与筛选逻辑。
6. 接入详情页点击链路。
7. 同步本地化（至少 `en` + 中文基础语言）。
8. 移植测试。
9. 运行生成产物：`dart run build_runner build --delete-conflicting-outputs`。

---

## 五、验收行为（迁移后必须满足）

1. 路由 `Destination.advancedFilter` 可正常打开。
2. 筛选页展示：类型/库/流派/地区/年份，可点击清空全部与单独清空。
3. 首次进入优先读取缓存；无缓存时回落到服务器。
4. 缓存过期自动后台刷新，不阻塞当前列表；缓存恢复成功且刷新结果覆盖时列表更新。
5. Emby 下显示库过滤，Jellyfin 不显示。
6. 排序可在“名称/年份”及升降方向切换且持久化。
7. 多选 genre/region 年份等需要“全部命中”语义。
8. 详情页中的所有 genre 标签可点击并带年份打开高级筛选。
9. 登录/会话切换后 WebSocket 同步服务重新 `start()`。
10. 旧版 `advanced_filter_cache_*` 会在新库缓存成功后清理。

---

## 六、迁移时常见坑位

- `PreferenceStore.removePreferenceKeys` 不存在时要先补齐该 API。
- `AdvancedFilterCatalogSyncService` 需要 `SocketHandler.events` 可注入。
- `schemaVersion` 增量后必须重建/更新 generated 文件。
- `advanced_filter_catalog_sync_service` 中 `defaultMaxAge` 与 VM 过期刷新策略要保持一致。
- route query 多值 `genre` 使用 `queryParametersAll`。
- `itemId` 可能重复/异常时，仓储解析必须按 JSON 安全降级。

---

## 七、迁移结果文件树（建议在目标分支核对）

```text
lib/
  data/
    repositories/
      advanced_filter_catalog_repository.dart
    services/
      advanced_filter_catalog_constants.dart
      advanced_filter_catalog_sync_service.dart
      advanced_filter_perf_logger.dart
      advanced_filter_perf_logger_io.dart
      advanced_filter_perf_logger_stub.dart
    viewmodels/advanced_filter_view_model.dart
    database/
      offline_database.dart
      offline_database.g.dart
  ui/
    screens/filter/advanced_filter_screen.dart
    screens/detail/item_detail_screen.dart
    navigation/
      destinations.dart
      app_router.dart
    widgets/
      left_sidebar.dart
      top_toolbar.dart
  preference/user_preferences.dart
  auth/repositories/session_repository.dart
  di/
    injection.dart
    modules/app_module.dart
test/
  browse/advanced_filter_view_model_test.dart
  detail/item_detail_title_genres_test.dart
```

---

## 八、补充（可选）

可直接从该文档按“模块顺序”执行迁移，避免遗漏 `测试 + 生成产物 + 本地化 + 会话接线` 这四个高频遗忘项。
