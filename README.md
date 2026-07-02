# JAVBUS 封面大图 (JAVBUS Larger Thumbnails)

这是一个功能强大的油猴（Tampermonkey）脚本，旨在优化 JAVBUS、JAVDB、AVMOO 和 JAVLIBRARY 等网站的浏览与下载体验。

## 🌟 主要功能

- **封面高清源图替换**：自动将列表页的缩略图替换为高清原图。
- **瀑布流排版**：支持自适应多列瀑布流展示，提供无缝滚动体验，且支持鼠标滚轮自动翻页。
- **详情页 Jackett 磁力集成**：自动在详情页请求 Jackett 接口，搜索并以表格化降序展示所有可用磁力。
- **原生磁力智能优化**：对原生的磁力表格进行文件大小降序排序，自动注入操作按钮。
- **绝对垂直对齐**：通过锁定 DOM 的各列百分比宽度以及物理布局对齐，使得 Jackett 搜索结果和自带搜索结果的表头及操作按钮完美纵向对齐。
- **qBittorrent 一键静默推送**：支持将磁力链接一键推送到您的 qBittorrent 下载器中，支持配置自动分类（`Jav`）和自定义下载目录，免去手动复制磁力跳转下载的繁琐步骤。
- **多种实用小工具**：一键复制番号/标题、一键下载封面、查看/下载来自 blogjav.net 的高清视频截图等。

## 🚀 安装方式

1. 首先确保您的浏览器已安装 [Tampermonkey (油猴)](https://www.tampermonkey.net/) 插件。
2. 点击安装本项目中的用户脚本：
   - [一键安装 javbus-larger-thumbnails.user.js](https://raw.githubusercontent.com/YuFan08/javmonkey/main/javbus-larger-thumbnails.user.js) （或直接复制 `JAVBUS封面大图.txt` 里的代码到新建脚本中）。

## ⚙️ 配置 qBittorrent 一键下载

若要使用**一键下载到 qb** 功能，请在安装脚本后，点击油猴菜单中的“编辑脚本”，修改脚本开头的 `QB_CONFIG` 配置对象：

```javascript
// qBittorrent 自动登录配置，若需要静默推送，请填写您的 qB WebUI 账号密码
const QB_CONFIG = {
    url: "https://qb.chunshi.lol",  // 您的 qB WebUI 访问地址
    username: "admin",              // 您的 qB 用户名
    password: "your_password",      // 您的 qB 密码
    category: "Jav",                // 推送时的分类名，下载时会自动分类为 Jav 并在对应目录下创建文件夹
    savepath: "./Jav"               // 若需指定下载的绝对路径，可在引号内填写（例如：/downloads/Jav ），为空则根据分类由 qB 自动管理
};
```

> [!NOTE]
> 脚本支持 qBittorrent 新旧版本的 WebUI API。当检测到未登录状态时，会自动尝试进行静默登录并自动重试添加下载，体验流畅。

## 📜 许可证

本项目基于 [MIT](LICENSE) 许可证开源。
