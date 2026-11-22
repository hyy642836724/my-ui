# my-ui

自建 shadcn/ui 组件库（registry）。组件源码在这里集中维护，通过 shadcn CLI 分发到各个项目。

## 这是什么

shadcn/ui 不是 npm 包——它把组件源码**复制**进你的项目。所以「复用」的关键是那个下载地址由谁提供：

- 官方：`https://ui.shadcn.com/r/button.json`
- 本库：`https://<你的名字>.github.io/my-ui/r/button.json`

本仓库就是后者：维护组件源码 → 编译成 registry JSON → 挂到 GitHub Pages。

## 在别的项目里用

### 1. 项目里配 `components.json`

```json
{
  "registries": {
    "@myui": "https://<你的名字>.github.io/my-ui/r/{name}.json"
  }
}
```

`{name}` 必须原样保留，CLI 会替换成组件名。

### 2. 装组件

```bash
npx shadcn@latest add @myui/button
npx shadcn@latest add @myui/card @myui/input
```

也可以用直接 URL，不配 `components.json` 也能临时装：

```bash
npx shadcn@latest add https://<你的名字>.github.io/my-ui/r/button.json
```

## 现有组件

| 组件 | 依赖 | 说明 |
|---|---|---|
| `utils` | clsx, tailwind-merge | `cn()` 工具，几乎所有组件都依赖 |
| `button` | radix-ui | 按钮，含 asChild |
| `badge` | radix-ui | 标签徽章 |
| `card` | — | 卡片容器 |
| `input` | — | 输入框 |
| `label` | radix-ui | 表单标签 |
| `separator` | radix-ui | 分割线 |
| `textarea` | — | 多行输入 |

## 加新组件到本库

```bash
# 从官方拉一份源码做起点
curl -s https://ui.shadcn.com/r/styles/new-york-v4/dialog.json > tmp.json
# 取出 files[0].content，把 from "cn" 改成 from "@/lib/utils"
# 存到 registry/new-york-v4/ui/dialog.tsx
```

然后在 `registry.json` 的 `items` 里加一条：

```json
{
  "name": "dialog",
  "type": "registry:ui",
  "dependencies": ["radix-ui"],
  "registryDependencies": ["utils"],
  "files": [
    { "path": "registry/new-york-v4/ui/dialog.tsx", "type": "registry:ui" }
  ]
}
```

改完必须重新构建：

```bash
npx shadcn@latest build
```

## 构建与发布

```bash
npx shadcn@latest build --output docs/r     # 读 registry.json，产物输出到 docs/r/
```

产物必须提交到仓库。**注意目录名必须是 `docs`**：GitHub Pages 的发布目录只支持 `/` 或 `/docs`，不认 `public`。

验证：

```bash
curl -s https://<你的名字>.github.io/my-ui/r/registry.json | head -c 200
```

## 部署到 GitHub Pages

1. 推到 GitHub
2. 仓库 Settings → Pages → Source 选 `Deploy from a branch`
3. Branch 选 `main`，目录选 `/docs`
4. 等 1 分钟左右，访问 `https://<你的名字>.github.io/my-ui/r/registry.json`

本库已部署：<https://hyy642836724.github.io/my-ui/r/registry.json>

## 约定

- `registry/new-york-v4/ui/*` 是上游源码，业务定制不要写在这里
- 每个组件的 `registryDependencies` 至少声明 `utils`
- 改完源码一定重新 `build`，否则分发出去的是旧内容
