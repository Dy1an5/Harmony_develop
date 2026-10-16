# 03 ArkTS 与 ArkUI 基础

从 Android / Java / TypeScript 过来最容易踩的思维差异，以及必须记住的那几条规则。**不是教程的替代品**
—— 每节末尾都给了 `devecocli docs read` 的路径，细节回官方文档看。

## 一、ArkTS 不是 TypeScript

**这是最容易吃亏的地方：TS 能编过的代码，ArkTS 可能直接编译不过。**

ArkTS 保留 TS 的大部分语法，但为了编译成方舟字节码做优化，砍掉了所有"运行时才知道类型"的动态特性。

### 必须记住的四条

| 规则 | 说明 |
| --- | --- |
| **强制静态类型** | 不许 `any` / `unknown`，不许靠类型推断蒙混；函数返回类型建议显式标注 |
| **禁止运行时改对象结构** | 不能给对象动态加属性、不能 `delete`、不能改方法 |
| **严格空安全** | `null` / `undefined` 不能传给 `string` 这类非空类型，编译期就拦；可能为空要标 `string \| undefined`，取值用 `?.` |
| **类的属性必须显式初始化** | 声明时或构造函数里赋初值，不能像宽松 TS 那样留着 undefined |

```typescript
// ✗ TS 宽松模式能过，ArkTS 编译失败
class Person {
  name: string;               // 没初始化
  getName(): string { return this.name; }
}

// ✓ ArkTS 写法
class Person {
  name: string = '';          // 显式初始化
  getName(): string { return this.name; }
}

// ✓ 如果确实可能为空，类型要写清楚
class Person2 {
  name?: string;
  getName(): string | undefined { return this.name; }
}
let len = new Person2().getName()?.length;   // 用 ?. 安全访问
```

### 常被 TS/JS 习惯坑到的具体条目

- **不支持解构**：`const { a, b } = obj`、参数解构、数组解构都不行，用临时变量代替。
- **不支持 `var`**：用 `let` / `const`。
- **不支持 `for...in`**：用 `for...of` 或普通 `for`。
- **不支持 `Function.apply` / `call` / `bind`**。
- **不支持 `Symbol()`、`globalThis`、`with`**。
- **不支持 index signature**：`obj['field']` 这种按下标访问字段会报
  `Indexed access is not supported for fields (arkts-no-props-by-index)`。
- **不支持 structural typing**：形状一样的两个类型不能互相赋值，要么同一个类，要么显式 `as`。
- **类型转换只能用 `as T`**，不能用 `<T>value`；而且 `as` 只在编译期生效，运行时不做转换。
- **对象字面量必须有明确的类型标注**，不能凭空构造。
- **不支持声明合并**（同名 interface / enum 合并、`Cannot redeclare block-scoped variable`）。
- **一个文件里的函数内不能再声明函数**（不支持函数声明的嵌套）。
- **不支持 `catch` 里标注类型**：`catch (e)`，然后自己判类型。
- **`.ets` 可以 import `.ts` / `.js`，反过来不行**。

**完整清单**（按字母序列了七十多条）：
`开发指南/学习ArkTS语言/从TypeScript到ArkTS的适配指导/从TypeScript到ArkTS的适配规则/typescript-to-arkts-migration-guide`

> **有 Java/Kotlin 背景的话建议先看这一篇**，比啃 TS 文档快：
> `开发指南/学习ArkTS语言/面向其他语言的ArkTS迁移指导/从Java到ArkTS的迁移指导/getting-started-with-arkts-for-java-programmers`

### 为什么这么严

不是为了折腾人：ArkTS 编译成**方舟字节码**（不是 JS），静态类型信息让引擎不用在运行时反复做类型检查，
性能和稳定性都更好。详见 `开发指南/学习ArkTS语言/从TypeScript到ArkTS的适配指导/ArkTS语法适配背景/arkts-migration-background`。

> 从 **API 10** 起 `.ets` 文件走"标准模式"，**任何 ArkTS 语法违规都会让编译失败**；
> `compatibleSdkVersion < 10` 才是"兼容模式"（只告警）。现在的工程基本都是标准模式。

## 二、ArkUI 声明式 UI

> **思维转变**：Android 是"创建 View → 拿到引用 → 改属性"；ArkUI 是"**用代码描述某个状态下 UI 长什么样**"，
> 状态一变，框架自己重算受影响的部分。**不要找"控件对象"**。

### 组件与页面

```typescript
@Entry            // 页面入口，一个页面只能有一个
@Component        // 自定义组件
struct Index {
  build() {       // build() 里描述 UI，只能有一个根组件
    Column() {
      Text('Hello')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
      Button('点我')
        .onClick(() => { /* ... */ })
    }
    .width('100%')
    .padding(16)
  }
}
```

- `@Entry` 装饰的组件是页面根组件；`@Component` 装饰的可复用组件叫自定义组件。
- **`build()` 里只能有一个根组件**。
- 组件的**属性、事件、子组件**都写在链式调用/嵌套里。
- 自定义组件用 `export struct` 导出，在别处 `import` 后直接用。

`@Entry` 的细节与 `EntryOptions`（`routeName` 等）：
`API参考/ArkUI_方舟UI框架/ArkTS组件/自定义组件/自定义组件装饰器/Entry_页面入口/ts-universal-entry`

### 常用结构

| 场景 | 用什么 |
| --- | --- |
| 线性布局 | `Row` / `Column` |
| 层叠 | `Stack` |
| 相对定位 | `RelativeContainer` |
| 弹性 | `Flex` |
| 栅格 | `GridRow` / `GridCol` |
| 列表 | `List` + `ListItem`；网格 `Grid` + `GridItem`；瀑布流 `WaterFlow` |
| 页签 | `Tabs` |
| 文本 / 图片 / 按钮 | `Text` / `Image` / `Button` |
| 弹窗 | `promptAction.showToast` / `showDialog` / 自定义 `Dialog` |

布局总览：`开发指南/ArkUI_方舟UI框架/UI开发_ArkTS声明式开发范式/组件布局/布局概述/arkts-layout-development-overview`
（线性布局 `.../组件布局/构建布局/线性布局_Row_Column/arkts-layout-development-linear`，
列表 `.../列表与网格/创建列表_List/arkts-layout-development-create-list`）

### 渲染控制

| 语法 | 用途 |
| --- | --- |
| `if` / `else` | 条件渲染 |
| `ForEach` | 循环渲染 |
| `LazyForEach` | 大数据量懒加载（长列表必用） |
| `Repeat` | 可复用的循环渲染（较新） |

```typescript
ForEach(this.items, (item: Item) => {
  ListItem() { Text(item.title) }
}, (item: Item) => item.id)     // 第三个参数是 key 生成函数，不要省
```

> **`ForEach` 的 key 函数不要省**，否则列表更新会整片重建，性能和动画都会出问题。
> 入口：`开发指南/ArkUI_方舟UI框架/UI开发_ArkTS声明式开发范式/学习UI范式渲染控制/渲染控制概述/arkts-rendering-control-overview`

## 三、状态管理（重点）

**这是从命令式 UI 转过来最需要花时间的一块。** 记住一句话：**变量加了装饰器，改动才会驱动 UI 更新。**

### V1 装饰器（主流）

| 装饰器 | 作用域 | 数据流向 |
| --- | --- | --- |
| `@State` | 组件内 | 组件自己的状态，**必须本地初始化**；父组件传入只能当初始值，后续不同步 |
| `@Prop` | 父子 | **单向**：父 → 子；子改只在子内部生效 |
| `@Link` | 父子 | **双向**：父子互相同步 |
| `@Provide` / `@Consume` | 跨层级 | 祖先 ↔ 后代，不用逐层传参 |
| `@Observed` / `@ObjectLink` | 嵌套对象 | 类对象属性变化能触发刷新 |
| `@Watch` | 任意 | 状态变化时回调 |
| `AppStorage` / `LocalStorage` | 全局 / 页面级 | 应用级、页面级状态存储 |

```typescript
@Entry
@Component
struct Counter {
  @State count: number = 0            // 组件内状态

  build() {
    Column() {
      Text(`count = ${this.count}`)
      Button('+1').onClick(() => { this.count++ })   // 改状态 → UI 自动更新
      Child({ value: this.count })    // 传给子组件
    }
  }
}

@Component
struct Child {
  @Prop value: number                 // 只跟着父组件变
  build() { Text(`child: ${this.value}`) }
}
```

**`@State` 的两个硬性规则**（另外两个装饰器同理）：

- **必须本地初始化**，不能只靠父组件传。
- 能装饰的类型有限：`object` / `class` / `string` / `number` / `boolean` / `enum` 及其数组；
  API 10 起支持 `Date`，API 11 起支持 `Map` / `Set` / `undefined` / `null` 及联合类型。**Function 类型不允许**。
- 只能从组件内部访问（私有）。

官方详解：`开发指南/ArkUI_方舟UI框架/UI开发_ArkTS声明式开发范式/学习UI范式状态管理/状态管理_V1/管理组件拥有的状态/State装饰器_组件内状态/arkts-state`
（同目录下还有 `Prop装饰器_父子单向同步` / `Link装饰器_父子双向同步` / `Provide装饰器和_Consume装饰器_与后代组件双向同步` 等）

### V2 装饰器（新工程设计就考虑）

V2 是官方在推的新体系：`@ComponentV2` + `@Local` / `@Param` / `@Event` / `@Provider` / `@Consumer`，
数据对象用 `@ObservedV2` + `@Trace`，全局状态用 `AppStorageV2` / `PersistenceV2`。

V2 的观测能力更强、能深度观测类属性，但**V1 和 V2 不能随便混用**（有专门的混用规则和版本条件）。

- 选型与区别：`FAQ/UI框架/UI界面/状态管理V1和V2适用场景介绍/faqs-arkui-885`
- 迁移：`开发指南/ArkUI_方舟UI框架/UI开发_ArkTS声明式开发范式/学习UI范式状态管理/状态管理V1-V2迁移指导/V1-V2迁移概述/arkts-v1-v2-migration`

> **实务建议：跟着官方模板和现有工程走。** 新工程用 V1 也能做完，
> 别在不懂两套机制差异的时候自己混搭，容易出"改了状态但 UI 不刷新"这类查不出来的问题。

### 状态不刷新的常见原因

1. 变量**没加装饰器** —— 普通成员变量改了不触发渲染。
2. 改了**嵌套对象的属性**，但对象只加了 `@State` 没加 `@Observed` / `@ObjectLink`。
3. `ForEach` 的 key 函数写成了固定值或索引，导致框架认为元素没变。
4. 在装饰器不支持的类型上做文章（比如 `Function`）。

排查入口：`开发指南/ArkUI_方舟UI框架/UI开发_ArkTS声明式开发范式/学习UI范式状态管理/状态管理常见问题/...`

## 四、页面路由

**两套机制并存，选新的那套。**

| 方案 | 状态 | 说明 |
| --- | --- | --- |
| `Navigation` + `NavDestination` | **推荐** | 组件级路由，支持分栏（平板/折叠屏很关键）、转场动画、跨包路由 |
| `router`（`@ohos.router`） | 不推荐 | 老方案，只能单栏，官方有 [Router切换Navigation] 迁移指导 |

```typescript
// Navigation 的基本形态
Navigation() {
  // 首页内容
}
.title('首页')
.mode(NavigationMode.Auto)     // 大屏自动分栏
```

跳转用 `NavPathStack` 的 `pushPath` / `pushPathByName`，返回用 `pop`。
**目标页面要通过 `NavDestination` 承载**，并按官方要求注册路由表。

- 总览：`开发指南/ArkUI_方舟UI框架/UI开发_ArkTS声明式开发范式/设置组件导航和页面路由/组件导航和页面路由概述/arkts-navigation-introduction`
- 基础架构：`.../组件导航_Navigation_推荐/Navigation基础架构介绍/arkts-navigation-architecture`
- 子页面：`.../组件导航_Navigation_推荐/Navigation子页面/arkts-navigation-navdestination`
- 跳转：`.../组件导航_Navigation_推荐/Navigation页面路由/arkts-navigation-jump`
- 分栏（平板）：`.../组件导航_Navigation_推荐/Navigation分栏开发/arkts-navigation-split-mode`
- 从 router 迁过来：`.../Router切换Navigation/arkts-router-to-navigation`

> **目标是平板的话，优先用 `Navigation` 并打开分栏模式** —— 大屏上单栏铺满宽度体验很差，
> 而 `router` 做不了分栏。

## 五、其他会反复用到的

| 能力 | 用什么 | 笔记 |
| --- | --- | --- |
| 弹 Toast | `promptAction.showToast` | |
| 弹窗 | `promptAction.showDialog` / 自定义 `Dialog` | |
| 数据存储 | `@ohos.data.preferences` | 对应 SharedPreferences |
| 数据库 | `@ohos.data.relationalStore` | 对应 SQLite / Room |
| 网络 | `@ohos.net.http` 或 RCP | 对应 OkHttp / Retrofit |
| 权限 | `module.json5` 声明 + `abilityAccessCtrl` 动态申请 | **声明和申请是两步** |
| 公共事件 | CommonEvent | 对应 BroadcastReceiver |
| 通知 | Notification Kit | |
| 文件 | Core File Kit | |

UI 之外的基础能力按需查：`devecocli docs search <关键词>`。

## 六、写代码时的自查清单

- [ ] 没有 `any` / `unknown`，可能为空的类型标了 `| undefined`
- [ ] 类属性都有初值
- [ ] 没有解构、没有 `for...in`、没有动态加属性
- [ ] `build()` 只有一个根组件
- [ ] 驱动 UI 的变量**都加了状态装饰器**
- [ ] `ForEach` 带了正确的 key 函数
- [ ] 新建页面已在 `main_pages.json` 里登记
- [ ] UI 之外的行为不靠"拿控件改属性"实现

## 参考

全部条目都可以用 `devecocli docs read <路径>` 读全文：

- ArkTS 语言介绍：`开发指南/学习ArkTS语言/ArkTS语言介绍/introduction-to-arkts`
- TS → ArkTS 适配规则：`开发指南/学习ArkTS语言/从TypeScript到ArkTS的适配指导/从TypeScript到ArkTS的适配规则/typescript-to-arkts-migration-guide`
- Java → ArkTS：`开发指南/学习ArkTS语言/面向其他语言的ArkTS迁移指导/从Java到ArkTS的迁移指导/getting-started-with-arkts-for-java-programmers`
- ArkTS 编程规范：`开发指南/学习ArkTS语言/ArkTS编程规范/arkts-coding-style-guide`
- ArkTS 高性能编程：`开发指南/学习ArkTS语言/ArkTS高性能编程实践/arkts-high-performance-programming`
- UI 开发概述：`开发指南/ArkUI_方舟UI框架/UI开发_ArkTS声明式开发范式/UI开发_ArkTS声明式开发范式_概述/arkts-ui-development-overview`
- 声明式 UI 描述：`开发指南/ArkUI_方舟UI框架/UI开发_ArkTS声明式开发范式/学习UI范式基本语法/声明式UI描述/arkts-declarative-ui-description`
- 创建自定义组件：`开发指南/ArkUI_方舟UI框架/UI开发_ArkTS声明式开发范式/学习UI范式基本语法/自定义组件/创建自定义组件/arkts-create-custom-components`
- 状态管理 V1 / V2：`开发指南/ArkUI_方舟UI框架/UI开发_ArkTS声明式开发范式/学习UI范式状态管理/...`
