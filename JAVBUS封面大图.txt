 // ==UserScript==
// @name         JAVBUS larger thumbnails
// @name:zh-CN   JAVBUS封面大图
// @namespace    https://github.com/kygo233/tkjs
// @homepage     https://sleazyfork.org/zh-CN/scripts/409874-javbus-larger-thumbnails
// @version      20210903
// @author       kygo233
// @license      MIT
// @description          replace thumbnails of javbus,javdb,javlibrary and avmoo with source images
// @description:zh-CN    javbus,javdb,javlibrary,avmoo替换封面为源图

// @include      *javbus.com/*
// @include      *javdb.com/*
// @include      *avmoo.cyou/*
// @include      *javlibrary.com/*
// @include      *mgstage.com/*
// @include      *dmm.co.jp/*
// @include      *imdb.com/*
// @include      /^.*(javbus|busfan|fanbus|buscdn|cdnbus|dmmsee|seedmm|busdmm|busjav)\..*$/
// @include      /^.*(javdb)[0-9]*\..*$/
// @include      /^.*(avmoo)\..*$/

// @require      https://cdn.jsdelivr.net/npm/vanilla-lazyload@17.3.0/dist/lazyload.min.js
// @require      https://cdn.jsdelivr.net/npm/jquery@3.6.0/dist/jquery.min.js

// @grant        GM_addStyle
// @grant        GM_xmlhttpRequest
// @grant        GM_getValue
// @grant        GM_setValue
// @grant        GM_download
// @grant        GM_setClipboard
// @connect *

// 2021-09-03 匹配javdb更多网址 例如javdb30
// 2021-08-18 调整blogjav视频截图获取方法
// 2021-06-03 修复javdb磁力弹窗预告片播放bug；番号变成可点击
// 2021-06-01 修复多列布局下 图片样式失效的问题
// 2021-05-31 JavDb添加磁力功能;解决已点击链接颜色失效问题;对大于标准宽高比的图片进行缩放;
// 2021-05-06 适配javlibrary;添加标题全显样式控制;自动翻页开关无需刷新页面;删除高清图标的显示控制
// 2021-04-04 适配JAVDB;点击图片弹出新窗口;标题默认显示一行;调整样式;增加英文显示
// 2021-03-09 恢复高清字幕图标的显示
// 2021-02-06 新增图片懒加载插件；重调样式；优化按钮效果，切换样式不刷新页面；磁力界面新增演员表样品图显示；
// 2021-01-18 适配AVMOO网站;无码页面屏蔽竖图模式;调整域名匹配规则
// 2021-01-01 新增宽度调整功能;
// 2020-12-29 解决半图模式下 竖图显示不全的问题;
// 2020-10-16 解决功能开关取默认值为undefined的bug
// 2020-10-16 解决和"JAV老司机"同时运行时样式冲突问题，需关闭老司机的瀑布流
// 2020-10-14 收藏界面只匹配影片；下载图片文件名添加标题；新增复制番号、标题功能；视频截图文件下载；封面显示半图；增加样式开关
// 2020-09-20 收藏界面的适配
// 2020-08-27 适配更多界面
// 2020-08-26 修复查询结果为1个时，item宽度为100%的问题
// 2020-08-26 添加瀑布流
// 2020-08-24 第一版：封面大图、下载封面、查看视频截图
// ==/UserScript==

(function () {
    'use strict';

    // qBittorrent 自动登录配置，若需要静默推送，请填写您的 qB WebUI 账号密码
    const QB_CONFIG = {
        url: "https://qb.chunshi.lol",  // 您的 qB WebUI 地址
        username: "admin",      // 您的 qB 用户名，请修改为您真实的用户名
        password: "131415",      // 您的 qB 密码，请修改为您真实的密码
        category: "Jav",        // 推送时的分类名，下载时会自动分类为 Jav 并在对应目录下创建文件夹
        tags: "Jav",            // 默认标签，Javbus/MGS/DMM 下载任务会自动标记为 Jav
        savepath: "./Jav"       // 若需指定下载的绝对路径，可在引号内填写（例如：/downloads/Jav ），为空则根据分类由 qB 自动管理
    };
    let statusDefault = {
        autoPage: false,
        copyBtn :true,
        toolBar: true,
        halfImg:false,
        fullTitle:false,
        waterfallWidth:100,
        columnNumFull:3,
        columnNumHalf:4
    };
    const IMG_SUFFIX = "-screenshot-tag";
    const blogjavSelector= "h2.entry-title>a";
    const fullImgCSS=`width: 100%!important;height:100%!important;`;
    const halfImgCSS=`position: relative;left: -112%;width: 212% !important;height: 100% !important;max-width: 212%;`;

    const copy_Svg = `<svg xmlns="http://www.w3.org/2000/svg" fill="currentColor"  width="16" height="16" viewBox="0 0 16 16"><path d="M2 2a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v13.5a.5.5 0 0 1-.777.416L8 13.101l-5.223 2.815A.5.5 0 0 1 2 15.5V2zm2-1a1 1 0 0 0-1 1v12.566l4.723-2.482a.5.5 0 0 1 .554 0L13 14.566V2a1 1 0 0 0-1-1H4z"/></svg>`;
    const download_Svg = `<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" class="tool-svg" viewBox="0 0 16 16"><path fill-rule="evenodd" d="M1 8a7 7 0 1 0 14 0A7 7 0 0 0 1 8zm15 0A8 8 0 1 1 0 8a8 8 0 0 1 16 0zM8.5 4.5a.5.5 0 0 0-1 0v5.793L5.354 8.146a.5.5 0 1 0-.708.708l3 3a.5.5 0 0 0 .708 0l3-3a.5.5 0 0 0-.708-.708L8.5 10.293V4.5z"/></svg>`;
    const picture_Svg = `<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16"  class="tool-svg" viewBox="0 0 16 16"><path d="M6.002 5.5a1.5 1.5 0 1 1-3 0 1.5 1.5 0 0 1 3 0z"/><path d="M2.002 1a2 2 0 0 0-2 2v10a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V3a2 2 0 0 0-2-2h-12zm12 1a1 1 0 0 1 1 1v6.5l-3.777-1.947a.5.5 0 0 0-.577.093l-3.71 3.71-2.66-1.772a.5.5 0 0 0-.63.062L1.002 12V3a1 1 0 0 1 1-1h12z"/></svg>`;

    const LOCALE = {
        zh: {
            menuText :'设置',
            menu_autoPage: '鼠标滚轮翻页',
            menu_copyBtn :'复制图标',
            menu_toolBar: '功能图标',
            menu_halfImg:'竖图模式',
            menu_fullTitle:'标题全显',
            menu_columnNum:'列',
            copySuccess:'复制成功',
            getAvImg_norespond:'blogjav.net网站暂时无法响应',
            getAvImg_none:'未搜索到',
            tool_downloadTip:'下载封面',
            tool_pictureTip:'视频截图(blogjav.net)',
            scrollerPlugin_end:'完'
        },
        en: {
            menuText :'Settings',
            menu_autoPage:'turn pages by mouse wheel',
            menu_copyBtn:'copy icon',
            menu_toolBar:'tools icon',
            menu_halfImg:'Vertical image mode',
            menu_fullTitle:'Full Title',
            menu_columnNum:'columns',
            copySuccess:'Copy successful',
            getAvImg_norespond:'blogjav.net is temporarily unable to respond',
            getAvImg_none:'Not found',
            tool_downloadTip:'Download cover',
            tool_pictureTip:'Video screenshot from blogjav.net',
            scrollerPlugin_end:'End'
        }
    }
    let getlanguage = () => {
        let local= navigator.language;
        local = local.toLowerCase().replace('_', '-');
        if (local in LOCALE){
            return LOCALE[local];
        }else if (local.split('-')[0] in LOCALE){
            return LOCALE[local.split('-')[0]];
        }else {
            return LOCALE.en;
        }
    }
    let lang = getlanguage();

    function showAlert(msg){
        var $alert=$(`<div  class="alert-zdy" ></div>`);
        $('body').append($alert);
        $alert.text(msg);
        $alert.show({start:function(){
            $(this).css({'margin-top': -$(this).height() / 2 });
            $(this).css({'margin-left': -$(this).width() / 2 });
        }}).delay(3000).fadeOut();
    }

    function sanitizeFilename(name) {
        return String(name || "cover").replace(/[\\/:*?"<>|]+/g, " ").replace(/\s+/g, " ").trim().slice(0, 160) || "cover";
    }

    function escapeHtml(value) {
        return String(value ?? "").replace(/[&<>"']/g, ch => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[ch]));
    }

    function downloadCover(url, name) {
        if (!url) {
            showAlert("封面地址为空");
            return;
        }
        let ext = (url.match(/\.(png|webp|jpe?g)(?=[?#]|$)/i) || [".jpg"])[0];
        let filename = sanitizeFilename(name).replace(/\.(png|webp|jpe?g)$/i, "") + ext;
        try {
            GM_download({
                url: url,
                name: filename,
                saveAs: false,
                onerror: function() {
                    showAlert("下载失败，已打开原图");
                    window.open(url, "_blank");
                }
            });
        } catch (e) {
            showAlert("下载失败，已打开原图");
            window.open(url, "_blank");
        }
    }
    let tool_Func = {
        autoPage: function () {
            if(scroller){
                scroller.destroy();
                scroller=null;
            }else{
                scroller= new ScrollerPlugin($('#waterfall-zdy'),lazyLoad);
            }
        },
        copyBtn: function () {
            $("#waterfall-zdy .copy-svg").toggle();
        },
        toolBar: function () {
            $("#waterfall-zdy .func-div").toggle();
        },
        halfImg:function () {
            let me = this;
            $("#waterfall-zdy .movie-box-b img.loaded").each(function (index,el) {
                me.imgCallback(el);
            });
            var columnNum = Status.getColumnNum();
            GM_addStyle('#waterfall-zdy .item-b{ width: ' + 100 / columnNum + '%;}');
            $("#columnNum_range").val(columnNum);
            $("#columnNum_range+span").text(columnNum);
        },
        fullTitle : function(){
            $("#waterfall-zdy a[name='av-title']").toggleClass("titleNowrap");
        },
        columnNum: function (columnNum) {
            GM_addStyle('#waterfall-zdy .item-b{ width: ' + 100 / columnNum + '%;}');
        },
        waterfallWidth: function (width) {
            var widthSelctor=currentObj.widthSelector;
            $(widthSelctor).css("width", width + "%");
            $(widthSelctor).css("margin", "0 " + (width>100?(100-width)/2+"%":"auto"));
        },
        imgCallback:function (img) {
            if (Status.isHalfImg()) {
                if(img.height < img.width){
                    img.style= halfImgCSS ;
                }else{
                    img.style= fullImgCSS ;
                }
            }else{
                if(img.height/img.width>=0.7){
                    img.style= `width:${img.width*67.25/img.height}%;` ;
                }else{
                    img.style= fullImgCSS ;
                }
            }
        }
    };

    let Status = {
        halfImg_block:false,
        set : function(key,value){
            if(key=="columnNum") {
                key=key+(this.isHalfImg()?"Half":"Full");
            }else if(key=="waterfallWidth"){
                key=key+"_"+currentWeb;
            }
            return GM_setValue(key, value);
        },
        get : function(key){
            return GM_getValue(key=="waterfallWidth"?(key+"_"+currentWeb):key, statusDefault[key]);
        },
        isHalfImg: function () {
            return this.get("halfImg") && (!this.halfImg_block);
        },
        getColumnNum: function () {
            var key= 'columnNum'+(this.isHalfImg()?"Half":"Full");
            return this.get(key);
        }
    };

    class Popover{
        show(el){
            if(el) {$(el).removeClass("svg-loading")};
            document.documentElement.classList.add("scrollBarHide");
            this.element.show({duration:0,start:function(){
                var t=$(this).find('#modal-div');
                t.css({'margin-top': Math.max(0, ($(window).height() - t.height()) / 2) });
            }});
        }
        hide(){
            document.documentElement.classList.remove("scrollBarHide");
            this.element.hide();
            this.element.find('.pop-up-tag').hide();
        }
        init(){
            var me=this;
            me.element = $('<div  id="myModal"><div  id="modal-div" > </div></div>');
            me.element.on('click',function(e){
                if($(e.target).closest("#modal-div").length==0){
                    me.hide();
                }
            });
            me.scrollBarWidth = me.getScrollBarWidth();
            GM_addStyle('.scrollBarHide{ padding-right: ' + me.scrollBarWidth + 'px;overflow:hidden;}');
            $('body').append(me.element);
        }
        append(elem){
            if(!this.element){ this.init();}
            this.element.find("#modal-div").append(elem);
        }
        getScrollBarWidth() {
            var el = document.createElement("p");
            var styles = {width: "100px",height: "100px",overflowY: "scroll" };
            for (var i in styles) {
                el.style[i] = styles[i];
            }
            document.body.appendChild(el);
            var scrollBarWidth = el.offsetWidth - el.clientWidth;
            el.remove();
            return scrollBarWidth;
        }
    }

    function addMenu() {
        var columnNum = Status.getColumnNum();
        var $menu = $('<div  id="menu-div" ></div>');
        $menu.append(creatCheckbox("autoPage", lang.menu_autoPage));
        $menu.append(creatCheckbox("copyBtn", lang.menu_copyBtn));
        $menu.append(creatCheckbox("toolBar", lang.menu_toolBar));
        $menu.append(creatCheckbox("halfImg", lang.menu_halfImg,Status.halfImg_block));
        $menu.append(creatCheckbox("fullTitle", lang.menu_fullTitle));
        $menu.append(creatRange("columnNum", lang.menu_columnNum, columnNum, 8));
        $menu.append(creatRange("waterfallWidth", '%', Status.get("waterfallWidth"), currentObj.maxWidth?currentObj.maxWidth:100));
        var $spanner = $(currentObj.menu.html);
        $spanner.append($menu);
        $spanner.mouseenter(()=>$menu.show()).mouseleave(()=>$menu.hide());
        $(currentObj.menu.position).append($spanner);
    }

    function creatCheckbox(tagName, name,disabled) {
        var $checkbox = $(`<div class="switch-div"><input ${disabled?'disabled="disabled"':''} type="checkbox" id="${tagName}_checkbox" /><label  for="${tagName}_checkbox" >${name}</label></div>`);
        $checkbox.find("input")[0].checked = Status.get(tagName);
        $checkbox.find("input").eq(0).click(function () {
            Status.set(tagName, this.checked);
            tool_Func[tagName]();
        });
        return $checkbox;
    }
    function creatRange(tagName, name, value, max) {
        var $range = $(`<div  class="range-div"><input type="range" id="${tagName}_range"  min="1" max="${max}" step="1" value="${value}"  /><span name="value">${value}</span><span>${name}</span></div>`);
        $range.bind('input propertychange', function () {
            var val = $(this).find("input").eq(0).val();
            $(this).find("span[name=value]").html(val);
            Status.set(tagName, val);
            tool_Func[tagName](val);
        });
        return $range;
    }





    function normalizeAvid(avid, stripLeadingDigits) {
        avid = decodeURIComponent(avid || "").trim().toUpperCase();
        if (stripLeadingDigits) {
            avid = avid.replace(/^[A-Z]+_\d+/, "").replace(/BOD$/, "").replace(/^\d+/, "");
        }
        avid = avid.replace(/[^A-Z0-9-]/g, "");
        if (stripLeadingDigits) {
            avid = avid.replace(/^([A-Z]+)-?(\d+)$/, (_, prefix, digits) => {
                const trimmed = digits.replace(/^0+/, "") || "0";
                return `${prefix}-${trimmed.length <= 3 ? trimmed.padStart(3, "0") : trimmed}`;
            });
        }
        return avid.includes("-") ? avid : avid.replace(/^([A-Z]+)(\d+)$/, "$1-$2");
    }

    function cleanImdbSearchTitle(title) {
        return title.split(/[：:]/)[0].replace(/[^\p{L}\p{N}]+/gu, " ").replace(/\s+/g, " ").trim();
    }

    function getImdbSeasonTabs() {
        return $('[role="tab"]').filter(function() {
            return $(this).text().trim().match(/^S\d+$/);
        });
    }

    function getImdbInfo() {
        let json = Array.from(document.querySelectorAll('script[type="application/ld+json"]')).map(s => {
            try { return JSON.parse(s.textContent); } catch (e) { return null; }
        }).find(Boolean) || {};
        let title = ($('[data-testid="hero__primary-text"]').first().text() || $('h1').first().text() || document.title.replace(/ - IMDb$/, '')).trim();
        let type = json['@type'] === 'TVSeries' ? 'Tv' : 'Movie';
        let seasonTabs = getImdbSeasonTabs();
        let hasSeasons = seasonTabs.length > 0;
        let season = Number(seasonTabs.filter('[aria-selected="true"]').first().text().trim().replace(/^S/i, '')) || 1;
        let searchTitle = cleanImdbSearchTitle(title);
        let query = type === 'Tv' && hasSeasons ? `${searchTitle} S${String(season).padStart(2, '0')}` : searchTitle;
        return { type, season, hasSeasons, query };
    }

    function getDetailAvid() {
        let avid = "";
        if (location.host.includes("imdb.com")) {
            return getImdbInfo().query;
        }
        if (location.host.includes("mgstage.com")) {
            avid = ($("body").text().match(/品番\s*[：:]\s*([A-Za-z0-9_-]+)/) || [])[1] || "";
        } else if (location.host.includes("dmm.co.jp")) {
            avid = ($("body").text().match(/品番\s*[：:]\s*([A-Za-z0-9_-]+)/) || [])[1] || "";
            if (!avid) avid = (location.href.match(/[?&/]cid=([^&/]+)/) || [])[1] || "";
        } else {
            $(".info p").each(function() {
                let text = $(this).text();
                if (text.includes("識別碼:") || text.includes("识别码:") || text.includes("ID:")) {
                    avid = $(this).find("span").eq(1).text().trim();
                }
            });
        }
        if (!avid) {
            let parts = location.pathname.split('/');
            avid = parts[parts.length - 1] || parts[parts.length - 2];
        }
        return normalizeAvid(avid, location.host.includes("dmm.co.jp"));
    }

    function formatBytes(bytes, decimals = 2) {
        if (bytes === 0) return '0 B';
        const k = 1024;
        const dm = decimals < 0 ? 0 : decimals;
        const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
    }

    function parseSize(sizeStr) {
        if (!sizeStr) return 0;
        let match = sizeStr.match(/([0-9.]+)\s*(GB|MB|KB|B)/i);
        if (!match) return 0;
        let num = parseFloat(match[1]);
        let unit = match[2].toUpperCase();
        if (unit === "GB") return num * 1024 * 1024 * 1024;
        if (unit === "MB") return num * 1024 * 1024;
        if (unit === "KB") return num * 1024;
        return num;
    }

    function isExtraDetailPage() {
        return (location.host.includes("mgstage.com") && location.pathname.includes("/product/product_detail/")) ||
            (location.host.includes("dmm.co.jp") && (location.pathname.includes("/-/detail/") || /[?&/]cid=/.test(location.href))) ||
            (location.host.includes("imdb.com") && location.pathname.includes("/title/tt"));
    }

    function findElementByText(text) {
        let matches = $("body *").filter(function() {
            let ownText = $(this).contents().filter(function() { return this.nodeType === 3; }).text().trim();
            return ownText.includes(text);
        }).get();
        matches.sort(function(a, b) {
            let at = $(a).contents().filter(function() { return this.nodeType === 3; }).text().trim().length;
            let bt = $(b).contents().filter(function() { return this.nodeType === 3; }).text().trim().length;
            return at - bt;
        });
        return $(matches[0]);
    }

    function findSectionAround(anchor) {
        if (!anchor.length) return $();
        let anchorTop = anchor.offset().top;
        let candidates = anchor.parents().addBack().filter(function() {
            let box = $(this);
            if (/^(BODY|HTML)$/.test(this.tagName)) return false;
            if (box.width() < 600 || box.height() < 40) return false;
            return Math.abs(box.offset().top - anchorTop) < 120;
        }).get();
        candidates.sort(function(a, b) {
            let ah = $(a).height() > 80 ? 0 : 1;
            let bh = $(b).height() > 80 ? 0 : 1;
            if (ah !== bh) return ah - bh;
            return ($(a).width() * $(a).height()) - ($(b).width() * $(b).height());
        });
        return $(candidates[0]);
    }

    function mountExtraJackettContainer(jackettContainer, tries) {
        tries = tries || 0;
        let isMgstage = location.host.includes("mgstage.com");
        let isDmm = location.host.includes("dmm.co.jp");
        let isImdb = location.host.includes("imdb.com");
        let anchor = isMgstage ? findElementByText("商品紹介") : findElementByText("この商品を買った人はこんな商品を買っています");
        let target = isImdb ? $('[data-testid="atf-wrapper-bg"]').first() : findSectionAround(anchor);
        let widthTarget = isImdb ? $('main [class*="ipc-page-content-container"]').first() : target;
        if (!target.length && isMgstage) target = $(".common_detail_cover").next();
        if (!target.length && isDmm && tries < 20) {
            setTimeout(function() { mountExtraJackettContainer(jackettContainer, tries + 1); }, 500);
            return;
        }
        if (!target.length) target = $("#center_column, main, article, #mu, #main").first().children().filter(function() { return $(this).width() > 600; }).last();
        jackettContainer.addClass("jackett-extra-section" + (isImdb ? " jackett-imdb-section" : ""));
        if (target.length) {
            let w = isImdb ? Math.max(320, Math.min(window.innerWidth - 300, 1600)) : (widthTarget.length ? widthTarget.outerWidth() : target.outerWidth());
            if (w) jackettContainer.attr("style", "width:" + w + "px !important; max-width:" + w + "px !important;");
            if (isImdb) {
                target.after(jackettContainer.addClass("jackett-site-section jackett-theme-light"));
            } else {
                target.before(jackettContainer.addClass("jackett-site-section jackett-theme-light"));
            }
        } else {
            $("body").append(jackettContainer.addClass("jackett-site-section jackett-theme-light"));
        }
    }
    function initJackettSearch() {
        let avid = getDetailAvid();
        if (!avid) return;

        let jackettContainer = $(`
            <section id="jackett-search-container">
                <div class="jackett-section-head">
                    <h3>Jackett 磁力搜索 <span class="jackett-title-code">${avid}</span></h3>
                    <span id="jackett-loading-status">正在搜索...</span>
                </div>
                <div class="jackett-table-wrap">
                    <table class="table table-hover" id="jackett-table" style="display:none;">
                        <colgroup>
                            <col class="jackett-col-name">
                            <col class="jackett-col-size">
                            <col class="jackett-col-seeders">
                            <col class="jackett-col-actions">
                        </colgroup>
                        <thead>
                            <tr>
                                <th class="jackett-sort jackett-name-head" data-sort="title">磁力名称 <input id="jackett-filter" type="search" placeholder="过滤" autocomplete="off"></th>
                                <th class="jackett-sort" data-sort="size">大小</th>
                                <th class="jackett-sort" data-sort="seeders">种子</th>
                                <th>操作</th>
                            </tr>
                        </thead>
                        <tbody></tbody>
                    </table>
                </div>
            </section>
        `);
        if ($("#magnet-table").length > 0) {
            jackettContainer.addClass("jackett-javbus-section");
            $("#magnet-table").before(jackettContainer);
        } else if ($(".movie").length > 0) {
            $(".movie").after(jackettContainer);
        } else if (isExtraDetailPage()) {
            mountExtraJackettContainer(jackettContainer);
        } else {
            $("body").append(jackettContainer);
        }

        let imdbInfo = location.host.includes("imdb.com") ? getImdbInfo() : null;
        let qbOptions = imdbInfo ? {
            category: imdbInfo.type,
            tags: imdbInfo.type,
            savepath: imdbInfo.type === 'Tv' ? './Tv' : './Movies'
        } : {};
        let searchSeq = 0;
        let jackettResults = [];
        let jackettSort = { key: "seeders", dir: -1 };
        let jackettFilter = "";
        let showJackettStatus = text => {
            if (!$("#jackett-loading-status").length) $(".jackett-section-head").append('<span id="jackett-loading-status"></span>');
            $("#jackett-loading-status").text(text).show();
        };
        let renderJackettResults = () => {
            let tbody = $("#jackett-table tbody");
            tbody.empty();

            jackettResults.filter(item => String(item.Title || "").toLowerCase().includes(jackettFilter)).sort((a, b) => {
                if (jackettSort.key === "title") return String(a.Title || "").localeCompare(String(b.Title || "")) * jackettSort.dir;
                let av = jackettSort.key === "size" ? (a.Size || 0) : (a.Seeders || 0);
                let bv = jackettSort.key === "size" ? (b.Size || 0) : (b.Seeders || 0);
                return (av - bv) * jackettSort.dir;
            }).forEach(item => {
                let sizeText = formatBytes(item.Size || 0);
                let magnetUrl = item.MagnetUri || item.Link;
                let seeders = item.Seeders !== undefined ? item.Seeders : 0;

                let itemTitle = escapeHtml(item.Title);
                let itemLink = escapeHtml(item.Link);
                let tr = $(`
                    <tr>
                        <td><a href="${itemLink}" target="_blank" title="${itemTitle}">${itemTitle}</a></td>
                        <td class="jackett-size-cell">${sizeText}</td>
                        <td class="jackett-seeders-cell" style="color: ${seeders > 0 ? 'green' : 'gray'};">${seeders}</td>
                        <td>
                            <div class="jackett-actions">
                                <button class="btn btn-xs btn-default jackett-copy-btn">复制</button>
                                <button class="btn btn-xs btn-primary jackett-qb-btn">下载到qb</button>
                            </div>
                        </td>
                    </tr>
                `);
                tr.find(".jackett-copy-btn").click(function() {
                    GM_setClipboard(magnetUrl);
                    showAlert("复制成功");
                });

                tr.find(".jackett-qb-btn").click(function() {
                    let btn = $(this);
                    btn.text("添加中...").attr("disabled", true);
                    downloadToQb(magnetUrl, false, qbOptions).then(() => {
                        btn.text("已添加").css("background-color", "green").css("border-color", "green");
                        showAlert("成功添加到 qBittorrent");
                    }).catch(err => {
                        btn.text("重试").attr("disabled", false);
                        showAlert("添加失败: " + err);
                    });
                });

                tbody.append(tr);
            });

            $("#jackett-table").show();
        };
        $("#jackett-table").on("click", ".jackett-sort", function() {
            let key = $(this).data("sort");
            jackettSort.dir = jackettSort.key === key ? -jackettSort.dir : (key === "title" ? 1 : -1);
            jackettSort.key = key;
            renderJackettResults();
        });
        $("#jackett-table").on("input", "#jackett-filter", function(e) {
            e.stopPropagation();
            jackettFilter = this.value.trim().toLowerCase();
            renderJackettResults();
        });
        $("#jackett-table").on("click", "#jackett-filter", function(e) {
            e.stopPropagation();
        });
        let searchJackett = (query, retried) => {
            let seq = ++searchSeq;
            $(".jackett-title-code").text(query);
            let searchUrl = `https://jackett.chunxi.lol/api/v2.0/indexers/all/results?apikey=a4z348fs9gdteuy4ebu2f70aqu6022oj&Query=${encodeURIComponent(query)}`;
            GM_xmlhttpRequest({
                method: "GET",
                url: searchUrl,
                onload: function(response) {
                    if (response.status !== 200) {
                        showJackettStatus("搜索失败，服务器状态码: " + response.status);
                        return;
                    }
                    try {
                        let data = JSON.parse(response.responseText);
                        if (seq !== searchSeq) return;
                        let results = (data.Results || []).filter(item => item.MagnetUri || item.Link);
                        if (results.length === 0) {
                            let retryQuery = location.host.includes("mgstage.com") ? query.replace(/^\d+/, "") : query;
                            if (!retried && retryQuery && retryQuery !== query) {
                                showJackettStatus("未找到相关种子，正在尝试去除开头数字...");
                                searchJackett(retryQuery, true);
                                return;
                            }
                            showJackettStatus("未找到相关种子");
                            return;
                        }

                        jackettResults = results;
                        $("#jackett-loading-status").remove();
                        renderJackettResults();

                    } catch (e) {
                        showJackettStatus("数据解析失败: " + e.message);
                    }
                },
                onerror: function(err) {
                    showJackettStatus("网络错误，无法连接 Jackett");
                }
            });
        };
        searchJackett(avid, false);
        if (imdbInfo && imdbInfo.type === 'Tv' && imdbInfo.hasSeasons) {
            let lastSeason = imdbInfo.season;
            let reloadSeasonSearch = () => setTimeout(function() {
                let info = getImdbInfo();
                if (!info.hasSeasons || info.season === lastSeason) return;
                lastSeason = info.season;
                $("#jackett-table").hide();
                $("#jackett-table tbody").empty();
                showJackettStatus("正在搜索...");
                searchJackett(info.query, false);
            }, 150);
            document.addEventListener('click', function(e) {
                if ($(e.target).closest('[role="tab"]').text().trim().match(/^S\d+$/)) reloadSeasonSearch();
            }, true);
            new MutationObserver(reloadSeasonSearch).observe(document.body, { subtree: true, attributes: true, attributeFilter: ['aria-selected'] });
        }
    }

    function loginToQb() {
        return new Promise((resolve, reject) => {
            let qbUrl = QB_CONFIG.url.replace(/\/$/, "");
            GM_xmlhttpRequest({
                method: "POST",
                url: qbUrl + "/api/v2/auth/login",
                headers: {
                    "Content-Type": "application/x-www-form-urlencoded",
                    "Referer": qbUrl + "/",
                    "Origin": qbUrl
                },
                data: `username=${encodeURIComponent(QB_CONFIG.username)}&password=${encodeURIComponent(QB_CONFIG.password)}`,
                onload: function(res) {
                    if (res.status === 200 && res.responseText.includes("Ok")) {
                        resolve();
                    } else {
                        reject("登录接口响应异常: " + res.status);
                    }
                },
                onerror: function(err) {
                    reject("网络错误，无法连接登录接口");
                }
            });
        });
    }

    function downloadToQb(torrentUrl, isRetry = false, options = {}) {
        return new Promise((resolve, reject) => {
            let qbUrl = QB_CONFIG.url.replace(/\/$/, "");
            let postData = "urls=" + encodeURIComponent(torrentUrl);
            let category = options.category || QB_CONFIG.category;
            let savepath = options.savepath || QB_CONFIG.savepath;
            let tags = options.tags || QB_CONFIG.tags || "";
            if (category) {
                postData += "&category=" + encodeURIComponent(category);
            }
            if (savepath) {
                postData += "&savepath=" + encodeURIComponent(savepath);
            }
            if (tags) {
                postData += "&tags=" + encodeURIComponent(tags);
            }

            GM_xmlhttpRequest({
                method: "POST",
                url: qbUrl + "/api/v2/torrents/add",
                headers: {
                    "Content-Type": "application/x-www-form-urlencoded",
                    "Referer": qbUrl + "/",
                    "Origin": qbUrl
                },
                data: postData,
                onload: function(res) {
                    if (res.status === 200) {
                        resolve();
                    } else if ((res.status === 403 || res.status === 401) && !isRetry) {
                        // 未登录，尝试静默登录
                        console.log("qB未登录，正在尝试使用配置的账号密码自动登录...");
                        loginToQb().then(() => {
                            // 登录成功后重新发送下载请求
                            downloadToQb(torrentUrl, true, options).then(resolve).catch(reject);
                        }).catch(err => {
                            reject("自动登录失败: " + err);
                        });
                    } else {
                        let firstStatus = res.status;
                        console.warn("qBittorrent 新版 API 失败，状态码: " + res.status + ", 内容: " + res.responseText);

                        GM_xmlhttpRequest({
                            method: "POST",
                            url: qbUrl + "/command/download",
                            headers: {
                                "Content-Type": "application/x-www-form-urlencoded",
                                "Referer": qbUrl + "/",
                                "Origin": qbUrl
                            },
                            data: postData,
                            onload: function(res2) {
                                if (res2.status === 200) {
                                    resolve();
                                } else {
                                    reject(`新版API码:${firstStatus}, 旧版API码:${res2.status}`);
                                }
                            },
                            onerror: function(err) {
                                reject(`新版API码:${firstStatus}, 旧版网络错误`);
                            }
                        });
                    }
                },
                onerror: function(err) {
                    reject("网络错误，无法连接 QB");
                }
            });
        });
    }

    function showBigImg(avid,elem) {
        let $selector = $(".pop-up-tag").filter(function() { return $(this).attr("name") === avid + IMG_SUFFIX; });
        if ($selector.length > 0) {
            $selector.show();
            myModal.show();
        } else {
            getAvImg(avid,elem);
        }
    }

    function getAvImg(avid, elem) {
        if ($(elem).hasClass("svg-loading")) {return;}
        $(elem).addClass("svg-loading");
        GM_xmlhttpRequest({
            method: "GET",
            url: 'http://blogjav.net/?s=' + encodeURIComponent(avid),
            onload: function (result) {
                if (result.status !== 200) {
                    showAlert(lang.getAvImg_norespond);
                    $(elem).removeClass("svg-loading");
                    return;
                }
                var doc = result.responseText;
                let a_array = $($.parseHTML(doc)).find(blogjavSelector);
                let imgUrl;
                if(a_array.length){
                    imgUrl= a_array[0].href;
                    for (let i = 0; i < a_array.length; i++) {
                        let tempUrl = a_array[i].href;
                        if (tempUrl.search(/FHD/i) > 0) {
                            imgUrl = tempUrl;
                            break;
                        }
                    }
                }
                if (!imgUrl) {
                    showAlert(lang.getAvImg_none);
                    $(elem).removeClass("svg-loading");
                    return;
                }
                GM_xmlhttpRequest({
                    method: "GET",
                    url: imgUrl,
                    headers: {
                        referrer: "http://pixhost.to/"
                    },
                    onload: function (XMLHttpRequest) {
                        var bodyStr = XMLHttpRequest.responseText;
                        var img_src_arr = /<img .*data-lazy-src="https:\/\/.*pixhost.to\/thumbs\/.*>/.exec(bodyStr);
                        if (img_src_arr) {
                            var src = $(img_src_arr[0]).attr("data-lazy-src").replace('thumbs', 'images').replace('//t', '//img').replace('"', '');
                            var height = $(window).height();
                            var img_tag = $(`<div name="${escapeHtml(avid + IMG_SUFFIX)}" class="pop-up-tag" ><img style="min-height:${height}px;width:100%" src="${escapeHtml(src)}" /></div>`);
                            var downloadBtn = $(`<span class="download-icon" >${download_Svg}</span>`);
                            downloadBtn.click(function () {
                                downloadCover(src, avid);
                                return false;
                            });
                            $(img_tag).prepend(downloadBtn);
                            myModal.append(img_tag);
                            myModal.show();
                        }else if(bodyStr.match("404 Not Found")){
                            showAlert(lang.getAvImg_norespond);
                        }
                        $(elem).removeClass("svg-loading");
                    }
                });
            }
        });
    };

    let myModal;
    let currentWeb ;
    let currentObj ;
    let ConstCode = {
        javbus: {
            domainReg: /(javbus|busfan|fanbus|buscdn|cdnbus|dmmsee|seedmm|busdmm|busjav)\./i,
            excludePages: ['/actresses', 'mdl=favor&sort=1', 'mdl=favor&sort=2', 'mdl=favor&sort=3', 'mdl=favor&sort=4', 'searchstar'],
            halfImg_block_Pages:['/uncensored','javbus.one','mod=uc'],
            menu:{
                position:'#navbar ul:first',
                html:`<li class='dropdown'><a class='dropdown-toggle'>${lang.menuText}</a></li>`
            },
            gridSelector: 'div#waterfall',
            itemSelector: 'div#waterfall div.item',
            widthSelector : '#waterfall-zdy',
            pageNext:'a#next',
            pageSelector:'.pagination',
            getAvItem: function (elem) {
                var photoDiv = elem.find("div.photo-frame")[0];
                var href = elem.find("a")[0].href;
                var img = $(photoDiv).children("img")[0];
                var src = img.src;
                if (src.match(/pics.dmm.co.jp/)) {
                    src = src.replace(/ps.jpg/, "pl.jpg");
                } else {
                    src = src.replace(/thumbs/, "cover").replace(/thumb/, "cover").replace(/.jpg/, "_b.jpg");
                }
                var title = img.title;
                var AVID = elem.find("date").eq(0).text();
                var date = elem.find("date").eq(1).text();
                var itemTag = "";elem.find("div.photo-info .btn").toArray().forEach( x=> itemTag+=x.outerHTML);
                return {AVID: AVID,href: href,src: src,title: title,date: date,itemTag:itemTag};
            }
        },
        javdb: {
            domainReg: /(javdb)[0-9]*\./i,
            excludePages: ['/users/'],
            halfImg_block_Pages:['/uncensored','/western','/video_uncensored','/video_western'],
            menu:{
                position:'#navbar-menu-hero .navbar-start',
                html:`<div class='navbar-item' >${lang.menuText}</div>`
            },
            gridSelector: 'div#videos>.grid',
            itemSelector: 'div#videos>.grid div.grid-item',
            widthSelector : '#waterfall-zdy',
            pageNext: 'a.pagination-next',
            pageSelector:'.pagination-list',
            init_Style: function(){
                var local_color=$(".box").css("background-color");
                if(local_color=="rgb(18, 18, 18)"){
                    GM_addStyle(`.scroll-request span{background:white;}#waterfall-zdy .movie-box-b a:link {color : inherit;}#waterfall-zdy  .movie-box-b{background-color:${local_color};}.alert-zdy {color: black;background-color: white;}`);
                }
            },
            maxWidth: 150,
            getAvItem: function (elem) {
                var href = elem.find("a")[0].href;
                var img = elem.find("div.item-image>img").eq(0);
                var src = img.attr("data-src").replace(/thumbs/, "covers") ;
                var title = elem.find("div.video-title").eq(0).text();
                if(!title) {title = elem.find("div.video-title2").eq(0).text()};
                var AVID = elem.find("div.uid").eq(0).text();
                if(!AVID) {AVID = elem.find("div.uid2").eq(0).text()};
                var date = elem.find("div.meta").eq(0).text();
                var itemTag = elem.find(".tags.has-addons").html();
                return {AVID: AVID,href: href,src: src,title: title,date: date,itemTag:itemTag};
            }
        },
        avmoo: {
            domainReg: /avmoo\./i,
            excludePages: ['/actresses'],
            menu:{
                position:'#navbar ul:first',
                html:`<li class='dropdown'><a class='dropdown-toggle'>${lang.menuText}</a></li>`
            },
            gridSelector: 'div#waterfall',
            itemSelector: 'div#waterfall div.item',
            widthSelector : '#waterfall-zdy',
            pageNext: 'a[name="nextpage"]',
            pageSelector:'.pagination',
            getAvItem: function (elem) {
                var photoDiv = elem.find("div.photo-frame")[0];
                var href = elem.find("a")[0].href;
                var img = $(photoDiv).children("img")[0];
                var src = img.src.replace(/ps.jpg/, "pl.jpg");
                var title = img.title;
                var AVID = elem.find("date").eq(0).text();
                var date = elem.find("date").eq(1).text();
                var itemTag = "";elem.find("div.photo-info .btn").toArray().forEach( x=> itemTag+=x.outerHTML);
                return {AVID: AVID,href: href,src: src,title: title,date: date,itemTag:itemTag};
            }
        },
        javlibrary: {
            domainReg: /javlibrary\./i,
            menu:{
                position:'div#rightcolumn',
                html:`<div  style="position: absolute;top: -1em;right: 10px;color: #000000;background: #ffffff;padding: 5px 5px 5px 5px;font-weight: bold;font-family: Arial;">${lang.menuText}</div>`
            },
            gridSelector: 'div.videothumblist',
            itemSelector: 'div.videos div.video',
            widthSelector : '#waterfall-zdy',
            pageNext: 'a.page.next',
            pageSelector:'.page_selector',
            getAvItem: function (elem) {
                var href = elem.find("a")[0].href;
                var src = elem.find("img")[0].src;
                if(src.indexOf("pixhost")<0){//排除含有pixhost的src
                    src= src.replace(/ps.jpg/, "pl.jpg");
                }
                var title = elem.find("div.title").eq(0).text();
                var AVID = elem.find("div.id").eq(0).text();
                return {AVID: AVID,href: href,src: src,title: title,date: '',itemTag:''};
            },
            init_Style: function(){
                GM_addStyle(`#menu-div{right:0} #waterfall-zdy div{box-sizing: border-box;}`);
            },
        },
        mgstage: {
            domainReg: /mgstage\.com/i,
            itemSelector: '#javbus-zdy-no-list'
        },
        dmm: {
            domainReg: /dmm\.co\.jp/i,
            itemSelector: '#javbus-zdy-no-list'
        },
        imdb: {
            domainReg: /imdb\.com/i,
            itemSelector: '#javbus-zdy-no-list'
        }
    };

    function oldDriverBlock(){
        if(['javbus','avmoo'].includes(currentWeb)){ //屏蔽老司机脚本,改写id
            if ($('.masonry').length > 0) {
                $('.masonry').removeClass("masonry");
            }
            let $waterfall = $('#waterfall');
            if($waterfall.length){
                $waterfall.get(0).id = "waterfall-destroy";
            }
            if($waterfall.find("#waterfall").length){ //javbus首页有2个'waterfall' ID
                $waterfall.find("#waterfall").get(0).id = "";
            }
            //解决 JAV老司机 $pages[0].parentElement.parentElement.id = "waterfall_h";
            //女优作品界面此代码会把id设置到class=row层
            if ($('#waterfall_h.row').length > 0) {
                $('#waterfall_h.row').removeAttr("id");
            }
            let $waterfall_h= $('#waterfall_h');
            if ($waterfall_h.length) {
                $waterfall_h.get(0).id = "waterfall-destroy";
            }
            if(location.pathname.search(/search/) > 0){//解决"改写id后，搜索页面自动跳转到无码页面"的bug
                $('body').append('<div id="waterfall"></div>');
            }
            currentObj.gridSelector = "#waterfall-destroy";
        }
        if(['javlibrary'].includes(currentWeb)){ //屏蔽老司机脚本,改写id
            let $waterfall = $('div.videothumblist');
            if($waterfall.length){
                $waterfall.removeClass("videothumblist");
                $waterfall.find(".videos").removeClass("videos");
                $waterfall.get(0).id = "waterfall-destroy";
            }
            currentObj.gridSelector = "#waterfall-destroy";
        }
    }
    function isMgsDmmListPage() {
        return (location.host.includes("mgstage.com") && location.pathname.includes("/search/cSearch.php")) ||
            (location.host.includes("dmm.co.jp") && location.pathname.includes("/-/list/"));
    }

    function initMgsDmmAutoPager() {
        if (!isMgsDmmListPage()) return;
        let locked = false;
        let findNext = () => Array.from(document.querySelectorAll('a[href]')).find(a =>
            (a.textContent || '').trim() === '次へ' && a.href && a.href !== location.href
        );
        document.addEventListener('wheel', function(e) {
            if (locked || e.deltaY <= 0) return;
            let doc = document.documentElement;
            let nearBottom = window.scrollY + window.innerHeight >= Math.max(doc.scrollHeight, document.body.scrollHeight) - 350;
            if (!nearBottom) return;
            let next = findNext();
            if (!next) return;
            locked = true;
            location.href = next.href;
        }, { passive: true });
    }

    function pageInit() {
        for (var key in ConstCode) {
            var domainReg = ConstCode[key].domainReg;
            if (domainReg && domainReg.test(location.href)) {
                currentWeb = key;
                currentObj = ConstCode[key];
                //排除页面的判断
                if (ConstCode[key].excludePages) {
                    for (var page of ConstCode[key].excludePages) {
                        if (location.href.includes(page)) return;
                    }
                }
                //屏蔽竖图模式的页面判断
                if (ConstCode[key].halfImg_block_Pages) {
                    for (var blockPage of ConstCode[key].halfImg_block_Pages) {
                        if (location.href.includes(blockPage)) {
                            Status.halfImg_block = true;
                            break;
                        };
                    }
                }
                break;
            }
        }
        if (!currentObj) return;
        let $items = $(currentObj.itemSelector);
        if (currentWeb && $items.length) {
            oldDriverBlock();
            $(currentObj.gridSelector).hide();
            var waterfall=$(`<div id= 'waterfall-zdy'></div>`);
            $(currentObj.gridSelector).eq(0).before(waterfall);
            addStyle();//全局样式
            if(currentObj.init_Style){currentObj.init_Style()};
            addMenu(); //添加菜单
            myModal = new Popover();//弹出插件
            //加载图片懒加载插件
            lazyLoad = new LazyLoad({
                callback_loaded: function (img) {
                    $(img).removeClass("minHeight-200");
                    tool_Func.imgCallback(img);
                }
            });
            let elems=getItems($items);
            waterfall.append(elems);
            lazyLoad.update();
            if(Status.get("autoPage") && $(currentObj.pageSelector).length ){
                scroller=new ScrollerPlugin(waterfall,lazyLoad);
            }
        }
    }
    let lazyLoad;
    let scroller;
    class ScrollerPlugin{
        constructor(waterfall,lazyLoad){
            let me=this;
            me.waterfall=waterfall;
            me.lazyLoad=lazyLoad;
            let $pageNext=$(currentObj.pageNext);
            me.nextURL = $pageNext.attr('href');
            me.scroller_status=$(`<div class = "scroller-status"  style="text-align:center;display:none"><div class="scroll-request"><span></span><span></span><span></span><span></span></div><h2 class="scroll-last">${lang.scrollerPlugin_end}</h2></div>`);
            me.waterfall.after(me.scroller_status);
            me.locked=false;
            me.canLoad=true;
            me.$page=$(currentObj.pageSelector);
            me.wheelFunc=me.wheelWatch.bind(me);
            document.addEventListener('wheel',me.wheelFunc);
        }
        wheelWatch (){
            let me = this;
            if (me.$page.get(0).getBoundingClientRect().top - $(window).height() < 300 && (!me.locked) && (me.canLoad)) {
                me.locked=true;
                me.loadNextPage(me.nextURL).then(()=>{me.locked=false});
            }
        }
        async loadNextPage(url){
            this.showStatus('request');
            let respondText = await fetch(url, { credentials: 'same-origin' }).then(respond=>respond.text());
            let $body = $(new DOMParser().parseFromString(respondText, 'text/html'));
            let elems = getItems($body.find(currentObj.itemSelector));
            this.scroller_status.hide();
            this.waterfall.append(elems);
            this.lazyLoad.update();
            this.nextURL = $body.find(currentObj.pageNext).attr('href');
            if(!this.nextURL){
                this.canLoad=false;
                this.showStatus("last");
            }
        }
        showStatus(status){
            this.scroller_status.children().each( (i,e)=>{$(e).hide()});
            this.scroller_status.find(`.scroll-${status}`).show();
            this.scroller_status.show();
        }
        destroy (){
            this.scroller_status.remove();
            document.removeEventListener('wheel',this.wheelFunc);
        }
    }

    function getItems(elems) {
        var elemsHtml = "";
        var imgStyle = Status.isHalfImg() ? halfImgCSS : fullImgCSS;
        var parseFunc = currentObj.getAvItem;
        for (let i = 0; i < elems.length; i++) {
            elemsHtml = elemsHtml + getItem(elems.eq(i), parseFunc,imgStyle);
        }
        var $elems = $(elemsHtml);
        if (!Status.get("toolBar")) {
            $elems.find(".func-div").css("display","none");
        }
        if (!Status.get("copyBtn")) {
            $elems.find(".copy-svg").css("display","none");
        }
        if (Status.get("fullTitle")) {
            $elems.find(".titleNowrap").removeClass("titleNowrap");
        }
        $elems.find("span[name='copy']").click(function () {
            GM_setClipboard($(this).next().text());
            showAlert(lang.copySuccess);
            return false;
        });
        $elems.find(".func-div span[name='download']").click(function () {
            downloadCover($(this).attr("src"), $(this).attr("src-title"));
            return false;
        });
        $elems.find(".func-div span[name='picture']").click(function () {
            showBigImg($(this).attr("AVID"),this);
        });
        return $elems;
    }

    function getItem(tag,parseFunc,imgStyle) {
        if (currentWeb!="javdb" && tag.find(".avatar-box").length) {
            return "";
        }
        var AvItem = parseFunc(tag);
        var href = escapeHtml(AvItem.href);
        var src = escapeHtml(AvItem.src);
        var title = escapeHtml(AvItem.title);
        var avid = escapeHtml(AvItem.AVID);
        var date = escapeHtml(AvItem.date);
        return `<div class="item-b">
                    <div class="movie-box-b">
                    <div class="photo-frame-b">
                        <a  href="${href}" target="_blank"><img style="${imgStyle}" class="lazy minHeight-200"  data-src="${src}" ></a>
                    </div>
                    <div class="photo-info-b">
                        <a name="av-title" href="${href}" target="_blank" title="${title}" class="titleNowrap"><span class="svg-span copy-svg" name="copy">${copy_Svg}</span> <span>${title}</span></a>
                        <div class="info-bottom">
                          <div class="info-bottom-one">
                              <a  href="${href}" target="_blank"><span class="svg-span copy-svg"  name="copy">${copy_Svg}</span><date name="avid">${avid}</date>${date?` / ${date}`:""}</a>
                          </div>
                          <div class="info-bottom-two">
                            <div class="item-tag">${AvItem.itemTag || ""}</div>
                            <div class="func-div">
                            <span name="download" class="svg-span" title="${lang.tool_downloadTip}" src="${src}" src-title="${avid} ${title}">${download_Svg}</span>
                            <span name="picture" class="svg-span" title="${lang.tool_pictureTip}" AVID="${avid}" >${picture_Svg}</span>
                           </div>
                         </div>
                       </div>
                    </div>
                    </div>
                </div>`;
    }

    function addStyle() {
        var columnNum = Status.getColumnNum();
        var waterfallWidth = Status.get("waterfallWidth");
        var css_waterfall = `
/* 自定义一键下载到 QB 按钮的统一样式与 Hover 态完全变色 */
.jackett-copy-btn, .jackett-qb-btn, .native-copy-btn, .native-qb-btn {
    background-color: #2080f0 !important;
    background-image: none !important;
    border-color: #2080f0 !important;
    color: white !important;
    text-align: center !important;
    transition: background-color 0.2s !important;
}
.jackett-copy-btn:hover, .jackett-qb-btn:hover, .native-copy-btn:hover, .native-qb-btn:hover {
    background-color: #1060c0 !important;
    border-color: #1060c0 !important;
    color: white !important;
}
.jackett-copy-btn:disabled, .jackett-qb-btn:disabled, .native-copy-btn:disabled, .native-qb-btn:disabled {
    background-color: #a0c0f0 !important;
    border-color: #a0c0f0 !important;
    cursor: not-allowed !important;
}

/* 强制双磁力表格列宽与总宽度绝对物理对齐 */
#jackett-table, #magnet-table table {
    table-layout: fixed !important;
    width: 100% !important;
    margin: 0 !important;
}
#jackett-table td:first-child, #magnet-table table td:first-child {
    word-break: break-all !important;
    word-wrap: break-word !important;
}
.jackett-site-section {
    --jackett-bg: #ffffff;
    --jackett-panel: #f5f7fb;
    --jackett-line: #d8dee8;
    --jackett-text: #17202a;
    --jackett-muted: #667085;
    --jackett-link: #0b73d9;
    --jackett-head: #c80024;
    width: 100% !important;
    margin: 18px 0 20px !important;
    padding: 14px !important;
    box-sizing: border-box !important;
    border: 1px solid var(--jackett-line) !important;
    border-radius: 6px !important;
    background: var(--jackett-bg) !important;
    color: var(--jackett-text) !important;
    box-shadow: 0 8px 24px rgba(16,24,40,.10) !important;
}
.jackett-site-section.jackett-extra-section {
    max-width: 100% !important;
}
.jackett-site-section.jackett-imdb-section {
    position: relative !important;
    z-index: 10 !important;
    pointer-events: auto !important;
    margin-left: auto !important;
    margin-right: auto !important;
}
.jackett-site-section.jackett-imdb-section,
.jackett-site-section.jackett-imdb-section * {
    pointer-events: auto !important;
}
.jackett-site-section.jackett-imdb-section .jackett-table-wrap {
    max-height: 440px !important;
    overscroll-behavior: contain !important;
}
.jackett-section-head {
    display: flex !important;
    align-items: flex-start !important;
    justify-content: flex-start !important;
    gap: 6px !important;
    flex-direction: column !important;
    margin: 0 0 12px !important;
    padding: 0 0 10px !important;
    border-bottom: 1px solid var(--jackett-line) !important;
}
.jackett-section-head h3 {
    margin: 0 !important;
    color: var(--jackett-head) !important;
    font-size: 16px !important;
    line-height: 1.3 !important;
    font-weight: 700 !important;
}
#jackett-loading-status {
    display: inline-block !important;
    margin-top: 4px !important;
    color: var(--jackett-muted) !important;
    font-size: 12px !important;
}
.jackett-title-code {
    margin-left: 8px !important;
    color: var(--jackett-text) !important;
    font-size: 13px !important;
    font-weight: 700 !important;
}
.jackett-table-wrap {
    max-height: 360px !important;
    overflow-y: scroll !important;
    overflow-x: hidden !important;
    scrollbar-gutter: stable !important;
}
#jackett-table {
    table-layout: fixed !important;
    width: 100% !important;
    margin: 0 !important;
    border-collapse: collapse !important;
    background: var(--jackett-bg) !important;
    color: var(--jackett-text) !important;
    font-size: 13px !important;
}
#jackett-table th,
#jackett-table td {
    padding: 8px 7px !important;
    border-bottom: 1px solid var(--jackett-line) !important;
    background: transparent !important;
    color: var(--jackett-text) !important;
    vertical-align: middle !important;
}
#jackett-table th.jackett-sort {
    cursor: pointer !important;
    user-select: none !important;
}
#jackett-filter {
    width: 120px !important;
    height: 28px !important;
    margin-left: 10px !important;
    padding: 0 10px !important;
    box-sizing: border-box !important;
    border: 1px solid color-mix(in srgb, var(--jackett-line) 78%, var(--jackett-bg)) !important;
    border-radius: 6px !important;
    background: color-mix(in srgb, var(--jackett-bg) 86%, var(--jackett-panel)) !important;
    box-shadow: inset 0 1px 2px rgba(16,24,40,.06) !important;
    color: var(--jackett-text) !important;
    font-size: 12px !important;
    font-weight: 500 !important;
    line-height: 26px !important;
    outline: none !important;
    vertical-align: middle !important;
}
#jackett-filter::placeholder {
    color: color-mix(in srgb, var(--jackett-muted) 78%, var(--jackett-bg)) !important;
}
#jackett-filter:focus {
    border-color: color-mix(in srgb, var(--jackett-link) 60%, var(--jackett-line)) !important;
    background: var(--jackett-bg) !important;
    box-shadow: 0 0 0 2px color-mix(in srgb, var(--jackett-link) 14%, transparent), inset 0 1px 2px rgba(16,24,40,.05) !important;
}
#jackett-table thead tr {
    background: var(--jackett-panel) !important;
}
#jackett-table .jackett-col-name { width: 52% !important; }
#jackett-table .jackett-col-size { width: 10% !important; }
#jackett-table .jackett-col-seeders { width: 8% !important; }
#jackett-table .jackett-col-actions { width: 30% !important; }
.jackett-javbus-section #jackett-table .jackett-col-name { width: 50% !important; }
.jackett-javbus-section #jackett-table .jackett-col-size { width: 15% !important; }
.jackett-javbus-section #jackett-table .jackett-col-seeders { width: 15% !important; }
.jackett-javbus-section #jackett-table .jackett-col-actions { width: 20% !important; }
.jackett-javbus-section .jackett-table-wrap,
.native-magnet-wrap {
    max-height: 360px !important;
    overflow-y: scroll !important;
    overflow-x: hidden !important;
    scrollbar-gutter: stable !important;
}
.jackett-javbus-section #jackett-table,
.native-magnet-wrap #magnet-table {
    width: 100% !important;
}
#jackett-table th:nth-child(1), #jackett-table td:nth-child(1) { text-align: left !important; }
#jackett-table th:nth-child(2), #jackett-table td:nth-child(2),
#jackett-table th:nth-child(3), #jackett-table td:nth-child(3),
#jackett-table th:nth-child(4), #jackett-table td:nth-child(4) { text-align: center !important; }
#jackett-table a {
    color: var(--jackett-link) !important;
}
#jackett-table td:first-child {
    word-break: break-word !important;
    overflow-wrap: anywhere !important;
}
.jackett-size-cell,
.jackett-seeders-cell {
    font-weight: 700 !important;
    white-space: nowrap !important;
}
.jackett-actions {
    display: flex !important;
    align-items: center !important;
    justify-content: center !important;
    gap: 8px !important;
    white-space: nowrap !important;
}
.jackett-copy-btn,
.jackett-qb-btn,
.native-copy-btn,
.native-qb-btn {
    height: 30px !important;
    line-height: 28px !important;
    padding: 0 10px !important;
    font-family: inherit !important;
    font-size: 14px !important;
    font-weight: 700 !important;
}
.jackett-copy-btn,
.native-copy-btn {
    border-radius: 4px !important;
    width: 64px !important;
}
.jackett-qb-btn,
.native-qb-btn {
    border-radius: 4px !important;
    width: 90px !important;
}
@media (max-width: 900px) {
    .jackett-section-head { align-items: flex-start !important; flex-direction: column !important; }
    .jackett-table-wrap { max-height: 300px !important; }
}
${currentObj.widthSelector ? `${currentObj.widthSelector}{
    width:${waterfallWidth}%;
    margin:0 ${waterfallWidth>100?(100-waterfallWidth)/2+'%':'auto'};
    transition:.5s ;
}` : ""}
#waterfall-zdy{
    display:flex;
    flex-direction:row;
    flex-wrap:wrap;
}
#waterfall-zdy .item-b{
    padding:5px;
    width:${100 / columnNum}%;
    transition:.5s ;
    animation: fadeInUp .5s ease-out;
}
#waterfall-zdy .movie-box-b {
    border-radius: 5px;
    background-color:white;
    border: 1px solid rgba(0, 0, 0, 0.2);
    box-shadow: 0 2px 3px 0 rgba(0, 0, 0, 0.1);
    overflow: hidden;
}
#waterfall-zdy .movie-box-b a:link    {  color : black;}
#waterfall-zdy .movie-box-b a:visited {  color : gray;}
.minHeight-200{
    min-height:200px;
}
#waterfall-zdy .movie-box-b .photo-frame-b {
    text-align: center;
}
#waterfall-zdy .movie-box-b .photo-info-b {
    padding: 7px;
}
#waterfall-zdy .movie-box-b .photo-info-b a {
    display: block;
}
#waterfall-zdy .info-bottom,.info-bottom-two{
    display: flex;
    justify-content: space-between;
    align-items: center;
    flex-wrap: wrap;
}
#waterfall-zdy .avatar-box-b {
    display: flex;
    flex-direction: column;
    background-color:white;
    border-radius: 5px;
    align-items: center;
    border: 1px solid rgba(0, 0, 0, 0.2);
}
#waterfall-zdy .avatar-box-b p {
    margin: 0 !important
}
#waterfall-zdy date:first-of-type {
    font-size: 18px !important
}
#waterfall-zdy .func-div {
    float: right;padding: 2px;
    white-space:nowrap;
}
#waterfall-zdy .func-div span {
    margin-right: 2px;
}
#waterfall-zdy .copy-svg {
    vertical-align: middle;
    display: inline-block
}
#waterfall-zdy span.svg-span {
    cursor: pointer;
    opacity: .3;
}
#waterfall-zdy span.svg-span:hover {
    opacity: 1
}
#waterfall-zdy .item-tag {
    display: inline-block;
    white-space:nowrap;
}
#myModal {
    overflow-x: hidden;
    overflow-y: auto;
    display: none;
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    z-index: 1050;
    background-color: rgba(0, 0, 0, 0.5);
}
#myModal #modal-div {
    position: relative;
    width: 80%;
    margin: 0 auto;
    background-color: rgb(6 6 6 / 50%);
    border-radius: 8px;
    animation: fadeInDown .5s;
}
#modal-div .pop-up-tag {
    border-radius: 8px;
    overflow: hidden
}
svg.tool-svg {
    fill: currentColor;
    width: 22px;
    height: 22px;
    vertical-align: middle
}
span.svg-loading {
    display: inline-block;
    animation: svg-loading 2s infinite;
}
#menu-div {
    white-space: nowrap;
    background-color: white;
    color:black;
    display: none;
    min-width: 200px;
    position: absolute;
    top: 100%;
    border-radius: 5px;
    padding: 5px;
    box-shadow: 0 10px 20px 0 rgb(0 0 0 / 50%)
}
#menu-div>div:hover{
    background-color:gainsboro;
}
#menu-div .switch-div,#menu-div .switch-div *{
    margin: 3px;
}
#menu-div .switch-div label{
    display: inline;
}
#menu-div .range-div {
    display: flex;
    flex-direction: row;
    flex-wrap: nowrap;
}
#menu-div .range-div input {
    cursor: pointer;
    width: 80%;max-width:200px;
}
.alert-zdy {
    position: fixed;
    top: 50%;
    left: 50%;
    padding: 12px 20px;
    font-size: 20px;
    color: white;
    background-color: rgb(0,0,0,.75);
    border-radius: 4px;
    animation: itemShow .3s;
    z-index: 1051;
}
.titleNowrap{
    white-space:nowrap;text-overflow: ellipsis;overflow:hidden;
}
.download-icon {
    position: absolute;
    right: 0;
    z-index: 2;
    cursor: pointer
}
.download-icon>svg {
    width: 30px;
    height: 30px;
    fill: aliceblue;
}
@keyframes fadeInUp {
    0% {transform: translate3d(0, 10%, 0);opacity: .5; }
    100% {transform: none; opacity: 1;}
}
@keyframes fadeInDown {
    0% {transform: translate3d(0, -100%, 0);opacity: 0; }
    100% {transform: none; opacity: 1;}
}
@keyframes itemShow {
    0% {transform:scale(0);}
    100% {transform:scale(1);}
}

@keyframes svg-loading{
    0% {transform:scale(1);opacity:1;}
    50% {transform:scale(1.2);opacity:1;}
    100% {transform:scale(1);opacity:1;}
}
.scroll-request {text-align: center;height: 15px; margin: 15px auto;}.scroll-request span {display: inline-block;width: 15px;height: 100%;margin-right: 8px;border-radius: 50%; background: rgb(16, 19, 16); animation: load 1s ease infinite;} @keyframes load { 0% ,100%{transform:scale(1); }50% {transform:scale(0);}}.scroll-request span:nth-child(2) {animation-delay: 0.125s;}.scroll-request span:nth-child(3) {animation-delay: 0.25s;}.scroll-request span:nth-child(4){animation-delay: 0.375s;}
`;
        GM_addStyle(css_waterfall);
    }
    pageInit();
    initMgsDmmAutoPager();

    // 详情页 Jackett 搜索及 QB 下载一键操作
    jQuery(document).ready(function($) {
        let isJavbusDetail = location.host.includes("javbus") && ($(".bigImage").length > 0 || $(".info").length > 0);
        let isExtraDetail = isExtraDetailPage();
        if (isJavbusDetail || isExtraDetail) {
            let exclude = ['/actresses', 'favor', 'search', 'genre', 'star', 'uncensored/genre', 'uncensored/star', 'western'];
            let isExclude = false;
            for (let p of exclude) {
                if (location.pathname.includes(p)) {
                    isExclude = true;
                    break;
                }
            }
            if (!isExclude) {
                addStyle(); // 注入大图脚本所用的全局 CSS 样式
                initJackettSearch();
                if (!isJavbusDetail) return;

                // 异步磁力行加载检测、大小排序与 QB 下载注入
                let noNewRowsCount = 0;
                let nativeTableTimer = setInterval(function() {
                    let table = $("#magnet-table");
                    if (table.length > 0) {
                        if (!table.parent().hasClass("native-magnet-wrap")) {
                            table.wrap('<div class="native-magnet-wrap"></div>');
                        }
                        // 1. 处理表头行，追加 "操作" 栏目名并强制设定每列宽度以与 Jackett 绝对对齐（55% / 12% / 13% / 20%）
                        let headerTr = table.find("tr:first");
                        if (headerTr.length > 0 && !headerTr.hasClass("processed-qb-header")) {
                            headerTr.addClass("processed-qb-header");

                            let cells = headerTr.find("td, th");
                            cells.eq(0).css("width", "50%"); // 磁力名稱列
                            cells.eq(1).css("width", "15%").css("text-align", "center"); // 檔案大小列
                            cells.eq(2).css("width", "15%").css("text-align", "center"); // 分享日期列

                            let lastCell = headerTr.find("td:last, th:last");
                            if (lastCell.text().trim() !== "操作") {
                                if (lastCell.prop("tagName") === "TH") {
                                    headerTr.append('<th style="text-align: center; width: 20%;">操作</th>');
                                } else {
                                    headerTr.append('<td style="text-align: center; font-weight: bold; width: 20%;">操作</td>');
                                }
                            } else {
                                lastCell.css("width", "20%").css("text-align", "center");
                            }
                        }

                        // 2. 检测是否有未处理的新行
                        let unhandledRows = table.find("tr").filter(function() {
                            return $(this).find("a[href^='magnet:']").length > 0 && !$(this).hasClass("processed-qb-row");
                        });

                        if (unhandledRows.length > 0) {
                            noNewRowsCount = 0; // 重置无新行计数器
                            // 3. 有新行时对所有数据行按大小降序排序
                            let rows = table.find("tr").get();
                            let dataRows = rows.filter(row => $(row).find("a[href^='magnet:']").length > 0);

                            dataRows.sort((a, b) => {
                                let sizeA = parseSize($(a).find("td").eq(1).text());
                                let sizeB = parseSize($(b).find("td").eq(1).text());
                                return sizeB - sizeA;
                            });

                            let tbody = table.find("tbody");
                            if (tbody.length > 0) {
                                tbody.append(dataRows);
                            } else {
                                table.append(dataRows);
                            }

                            // 4. 对排序后的新行进行按钮注入（同时注入 复制 和 下载到qb）
                            dataRows.forEach(function(row) {
                                let tr = $(row);
                                if (tr.hasClass("processed-qb-row")) return;
                                tr.addClass("processed-qb-row");

                                // 强力锁定数据行每一列 td 的百分比宽度以实现精确对齐
                                let tds = tr.find("td");
                                tds.eq(0).css("width", "50%");
                                tds.eq(1).css("width", "15%").css("text-align", "center").css("vertical-align", "middle");
                                tds.eq(2).css("width", "15%").css("text-align", "center").css("vertical-align", "middle");

                                let magnetUrl = tr.find("a[href^='magnet:']").attr("href");
                                let td = $('<td style="text-align: center; vertical-align: middle; white-space: nowrap; width: 20%;"></td>');

                                // 复制按钮
                                let copyButton = $('<button class="btn btn-xs btn-default native-copy-btn" style="margin-right: 5px;">复制</button>');
                                copyButton.click(function(e) {
                                    e.preventDefault();
                                    GM_setClipboard(magnetUrl);
                                    showAlert("复制成功");
                                });

                                // 下载到qb按钮
                                let qbButton = $('<button class="btn btn-xs btn-primary native-qb-btn">下载到qb</button>');
                                qbButton.click(function(e) {
                                    e.preventDefault();
                                    var btn = $(this);
                                    btn.text("添加中...").attr("disabled", true);
                                    downloadToQb(magnetUrl).then(() => {
                                        btn.text("已添加").css("background-color", "green").css("border-color", "green");
                                        showAlert("成功添加到 qBittorrent");
                                    }).catch(err => {
                                        btn.text("重试").attr("disabled", false);
                                        showAlert("添加失败: " + err);
                                    });
                                });

                                td.append(copyButton).append(qbButton);
                                tr.append(td);
                            });
                        } else {
                            // 若数据已处理过且多次未出现新数据，安全销毁轮询定时器以优化性能
                            if (table.find(".processed-qb-row").length > 0) {
                                noNewRowsCount++;
                                if (noNewRowsCount >= 5) {
                                    clearInterval(nativeTableTimer);
                                }
                            }
                        }
                    }
                }, 1000);
            }
        }
    });
})();
