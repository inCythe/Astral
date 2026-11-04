// ============================================================================
// Astral web preview — runtime
// ----------------------------------------------------------------------------
// Reads window.ASTRAL_SPEC (web/window-spec.js) and builds the window with DOM
// + CSS, without Roblox. The approach mirrors the playground in
// docs.mspaint.cc: the UI is described as data, a renderer turns that data into
// a window, and the theme is plain design tokens.
//
// Everything is measured in the library's own pixels (see Astral.lua), so the
// browser window is a 1:1 copy of the Roblox one. Small screens only get a
// single uniform `transform: scale()`, which is the fix for the mobile scaling
// drift: same size, same aspect ratio, just smaller.
// ============================================================================

(function () {
    "use strict";

    var SPEC = window.ASTRAL_SPEC;
    var ICONS = window.LUCIDE_ICONS || {};

    if (!SPEC) {
        throw new Error("web/window-spec.js must define window.ASTRAL_SPEC");
    }

    // ---------------------------------------------------------------- utils --

    var NS = "http://www.w3.org/2000/svg";

    function el(tag, cls, props) {
        var node = document.createElement(tag);
        if (cls) node.className = cls;
        if (props) {
            Object.keys(props).forEach(function (k) {
                if (k === "text") node.textContent = props[k];
                else if (k === "html") node.innerHTML = props[k];
                else if (k === "style") Object.assign(node.style, props[k]);
                else if (k.slice(0, 2) === "on") node.addEventListener(k.slice(2).toLowerCase(), props[k]);
                else if (props[k] !== undefined && props[k] !== null) node.setAttribute(k, props[k]);
            });
        }
        return node;
    }

    function svgIcon(name, cls) {
        var body = ICONS[name];
        if (!body) return null;
        var svg = document.createElementNS(NS, "svg");
        svg.setAttribute("viewBox", "0 0 24 24");
        svg.setAttribute("fill", "none");
        svg.setAttribute("stroke", "currentColor");
        svg.setAttribute("stroke-width", "2");
        svg.setAttribute("stroke-linecap", "round");
        svg.setAttribute("stroke-linejoin", "round");
        svg.setAttribute("aria-hidden", "true");
        if (cls) svg.setAttribute("class", cls);
        svg.innerHTML = body;
        return svg;
    }

    function icon(name, cls) {
        var node = svgIcon(name, cls);
        if (!node) return el("span", cls || "");
        return node;
    }

    function clamp(value, min, max) {
        return Math.min(max, Math.max(min, value));
    }

    function rgb(css) {
        return "rgb(" + css[0] + ", " + css[1] + ", " + css[2] + ")";
    }

    // Library:GetBetterColor — Add * 2 on the dark theme.
    function better(color, add) {
        var delta = add * 2;
        return [
            clamp(Math.round(color[0] + delta), 0, 255),
            clamp(Math.round(color[1] + delta), 0, 255),
            clamp(Math.round(color[2] + delta), 0, 255),
        ];
    }

    function hexToRgb(hex) {
        var m = /^#?([0-9a-f]{6})$/i.exec(hex || "");
        if (!m) return [255, 255, 255];
        var n = parseInt(m[1], 16);
        return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
    }

    function escapeHtml(text) {
        return String(text)
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;");
    }

    // Tiny RichText subset: <b>, <i>, <font color="#rrggbb">.
    function rich(text) {
        var out = [];
        var re = /<(\/?)(b|i|font)((?:\s+color\s*=\s*"[^"]*")?)\s*>/gi;
        var last = 0;
        var m;
        while ((m = re.exec(text))) {
            out.push(escapeHtml(text.slice(last, m.index)));
            var tag = m[2].toLowerCase();
            if (tag === "font") {
                if (m[1]) {
                    out.push("</span>");
                } else {
                    var color = (/color\s*=\s*"([^"]+)"/i.exec(m[3]) || [])[1] || "";
                    out.push(
                        '<span style="color:' + (/^#[0-9a-f]{3,8}$/i.test(color) ? color : "inherit") + '">'
                    );
                }
            } else {
                out.push("<" + m[1] + tag + ">");
            }
            last = re.lastIndex;
        }
        out.push(escapeHtml(text.slice(last)));
        return out.join("");
    }

    // --------------------------------------------------------------- theme ---

    var THEME = SPEC.Theme || {};
    var COLOR = {
        background: rgb(better(THEME.BackgroundColor || [13, 13, 16], -1)),
        panel: rgb(THEME.BackgroundColor || [13, 13, 16]),
        container: rgb(better(THEME.BackgroundColor || [13, 13, 16], 1)),
        bottom: rgb(better(THEME.BackgroundColor || [13, 13, 16], 4)),
        main: rgb(THEME.MainColor || [21, 21, 25]),
        outline: rgb(THEME.OutlineColor || [36, 36, 42]),
        accent: rgb(THEME.AccentColor || [66, 135, 245]),
        accentCss: "#4287f5",
        font: rgb(THEME.FontColor || [255, 255, 255]),
        red: rgb(THEME.RedColor || [255, 64, 64]),
    };

    // --------------------------------------------------------------- state ---

    var state = {
        activeTab: null,
        records: [],
        dpi: 5,
        autoScale: true,
        forceCheckbox: false,
        values: {},
    };

    var root = document.getElementById("astral-root");
    var stage = document.getElementById("stage");
    var readout = document.getElementById("readout");

    var win, layer, sidebarScroll, contentScroll, tabInfoName, tabInfoDesc, searchInput, searchOverlay, searchScroll;
    var tooltip;
    var contentScrollbar = null;
    var pages = {};
    var tabs = {};

    // ------------------------------------------------------------- geometry --

    var WIN_W = SPEC.Size.X;
    var WIN_H = SPEC.Size.Y;
    var SIDEBAR = SPEC.SidebarWidth || Math.ceil(WIN_W * 0.22);

    function applyTheme() {
        var vars = {
            "--background": COLOR.background,
            "--panel": COLOR.panel,
            "--container": COLOR.container,
            "--bottom": COLOR.bottom,
            "--main": COLOR.main,
            "--outline": COLOR.outline,
            "--accent": COLOR.accent,
            "--font": COLOR.font,
            "--red": COLOR.red,
            "--corner": (SPEC.CornerRadius || 6) + "px",
            "--sidebar-width": SIDEBAR + "px",
        };
        Object.keys(vars).forEach(function (k) {
            document.documentElement.style.setProperty(k, vars[k]);
        });
    }

    // ------------------------------------------------------------- tooltip ---

    function showTooltip(node, text) {
        if (!text) return;
        tooltip.textContent = text;
        tooltip.classList.add("is-visible");
        positionTooltip(node);
    }

    function positionTooltip(node) {
        var r = toWindowPx(node.getBoundingClientRect());
        var t = tooltip.getBoundingClientRect();
        var scale = win.getBoundingClientRect().width / WIN_W;
        var w = t.width / scale;
        var h = t.height / scale;
        var left = clamp(r.left, 4, WIN_W - w - 4);
        var top = r.top - h - 6;
        if (top < 4) top = r.top + r.height + 6;
        tooltip.style.left = left + "px";
        tooltip.style.top = top + "px";
    }

    function hideTooltip() {
        tooltip.classList.remove("is-visible");
    }

    // ---------------------------------------------------------- conversions --

    // Rect in window-local pixels (undoes the uniform scale).
    function toWindowPx(rect) {
        var w = win.getBoundingClientRect();
        var scale = w.width / WIN_W;
        return {
            left: (rect.left - w.left) / scale,
            top: (rect.top - w.top) / scale,
            width: rect.width / scale,
            height: rect.height / scale,
        };
    }

    // ---------------------------------------------------------- build window --

    function buildWindow() {
        win = el("div", "astral-window", { id: "astral-window" });
        win.style.width = WIN_W + "px";
        win.style.height = WIN_H + "px";

        // --- title bar -----------------------------------------------------
        var titlebar = el("div", "titlebar");

        var title = el("div", "window-title");
        title.appendChild(icon("sparkles", "title-icon"));
        title.appendChild(el("span", "", { text: SPEC.Title }));
        titlebar.appendChild(title);

        var topRight = el("div", "topbar-right");
        var tabInfo = el("div", "tab-info");
        tabInfoName = el("div", "tab-info-name");
        tabInfoDesc = el("div", "tab-info-desc");
        tabInfo.appendChild(tabInfoName);
        tabInfo.appendChild(tabInfoDesc);
        topRight.appendChild(tabInfo);

        var searchbox = el("div", "searchbox");
        searchbox.appendChild(icon("search", "search-icon"));
        searchInput = el("input", "", {
            type: "text",
            placeholder: SPEC.SearchPlaceholder || "Search",
            spellcheck: "false",
            autocomplete: "off",
        });
        searchbox.appendChild(searchInput);
        topRight.appendChild(searchbox);
        titlebar.appendChild(topRight);

        var controls = el("div", "window-controls");
        var minBtn = el("button", "ctrl-btn", { type: "button", title: "Minimise" });
        minBtn.appendChild(icon("minus"));
        minBtn.addEventListener("click", function () {
            win.classList.add("is-minimized");
            showRestore();
        });
        var closeBtn = el("button", "ctrl-btn close", { type: "button", title: "Close" });
        closeBtn.appendChild(icon("x"));
        closeBtn.addEventListener("click", function () {
            win.classList.add("is-minimized");
            showRestore();
        });
        controls.appendChild(minBtn);
        controls.appendChild(closeBtn);
        titlebar.appendChild(controls);

        win.appendChild(titlebar);
        win.appendChild(el("div", "titlebar-line"));

        // --- sidebar -------------------------------------------------------
        var sidebar = el("div", "sidebar");
        sidebarScroll = el("div", "sidebar-scroll");
        sidebar.appendChild(sidebarScroll);
        win.appendChild(sidebar);
        win.appendChild(el("div", "sidebar-divider"));

        // --- content -------------------------------------------------------
        var content = el("div", "content");
        contentScroll = el("div", "content-scroll");
        content.appendChild(contentScroll);
        win.appendChild(content);

        // --- footer --------------------------------------------------------
        win.appendChild(el("div", "bottom-bg"));
        win.appendChild(el("div", "bottom-line"));
        win.appendChild(el("div", "footer", { text: SPEC.Footer }));

        // --- overlay layer (dropdowns, rings, tooltips) --------------------
        layer = el("div", "window-layer");
        layer.style.position = "absolute";
        layer.style.inset = "0";
        layer.style.pointerEvents = "none";
        layer.style.zIndex = "55";
        win.appendChild(layer);

        tooltip = el("div", "tooltip");
        layer.appendChild(tooltip);

        root.appendChild(win);
    }

    function showRestore() {
        if (document.getElementById("restore-chip")) return;
        var chip = el("button", "pill", {
            id: "restore-chip",
            type: "button",
            text: "Restore Astral window",
            style: { position: "absolute", left: "50%", bottom: "18px", transform: "translateX(-50%)", zIndex: "20" },
        });
        chip.addEventListener("click", function () {
            win.classList.remove("is-minimized");
            chip.remove();
        });
        stage.appendChild(chip);
    }

    // -------------------------------------------------------------- sidebar --

    function buildSidebar() {
        state.closedSections = {};

        SPEC.TabSections.forEach(function (sectionSpec) {
            var body = el("div", "tab-section-body");
            if (sectionSpec.Open === false) body.hidden = true;

            var header = el("div", "tab-section-header", {
                "data-open": sectionSpec.Open === false ? "false" : "true",
            });
            header.appendChild(el("span", "", { text: sectionSpec.Name }));
            header.appendChild(icon("chevron-down", "chev"));
            header.addEventListener("click", function () {
                var open = header.getAttribute("data-open") !== "false";
                header.setAttribute("data-open", open ? "false" : "true");
                body.hidden = open;
            });

            var wrapper = el("div", "tab-section");
            wrapper.appendChild(header);
            wrapper.appendChild(body);

            sectionSpec.Tabs.forEach(function (tabSpec) {
                var button = el("div", "tab", { "data-tab": tabSpec.Name });
                button.appendChild(icon(tabSpec.Icon, "tab-icon"));
                button.appendChild(el("div", "tab-label", { text: tabSpec.Name }));
                button.addEventListener("click", function () {
                    selectTab(tabSpec.Name);
                });
                body.appendChild(button);
                tabs[tabSpec.Name] = { button: button, spec: tabSpec, section: wrapper };
            });

            sidebarScroll.appendChild(wrapper);
        });
    }

    function selectTab(name) {
        var tab = tabs[name];
        if (!tab) return;
        if (state.activeTab === name && pages[name] && !pages[name].hidden) return;

        Object.keys(tabs).forEach(function (key) {
            tabs[key].button.classList.toggle("is-active", key === name);
        });
        Object.keys(pages).forEach(function (key) {
            pages[key].hidden = key !== name;
        });

        // Unfold a collapsed sidebar section when its tab is selected.
        var header = tab.section.firstChild;
        if (header && header.getAttribute("data-open") === "false") {
            header.setAttribute("data-open", "true");
            tab.section.lastChild.hidden = false;
        }

        state.activeTab = name;
        tabInfoName.textContent = tab.spec.Name;
        tabInfoDesc.textContent = tab.spec.Description || "";
        contentScroll.scrollTop = 0;
        closeDropdown();
        hideSearchOverlay();

        if (contentScrollbar) {
            requestAnimationFrame(function () {
                contentScrollbar.update();
                contentScrollbar.reveal();
            });
        }
    }

    // -------------------------------------------------------------- content --

    function buildContent() {
        SPEC.TabSections.forEach(function (sectionSpec) {
            sectionSpec.Tabs.forEach(function (tabSpec) {
                var page = el("div", "tab-page", { hidden: "" });
                buildTabSections(page, tabSpec);
                contentScroll.appendChild(page);
                pages[tabSpec.Name] = page;
            });
        });
    }

    function buildTabSections(page, tabSpec) {
        var sections = tabSpec.Sections || [];
        var index = 0;

        while (index < sections.length) {
            var spec = sections[index];
            var row = el("div", "section-row");

            if (spec.Side === 1 || spec.Side === 2) {
                // One row holds at most a left/right pair, exactly like
                // Tab:AddLeftSection + AddRightSection produce a single row.
                var group = [spec];
                index += 1;
                if (index < sections.length && (sections[index].Side === 1 || sections[index].Side === 2)) {
                    group.push(sections[index]);
                    index += 1;
                }
                // Keep the left column first regardless of declaration order.
                group.sort(function (a, b) {
                    return (a.Side || 1) - (b.Side || 1);
                });
                group.forEach(function (sectionSpec) {
                    row.appendChild(buildSection(sectionSpec, tabSpec));
                });
                // A left-only or right-only section still occupies half a row in
                // the library, so leave the other half empty.
                if (group.length === 1) {
                    row.appendChild(el("div", "", { style: { flex: "1 1 0" } }));
                }
            } else {
                row.appendChild(buildSection(spec, tabSpec));
                index += 1;
            }

            page.appendChild(row);
        }
    }

    function buildSection(spec, tabSpec) {
        var box = el("div", "section");

        var header = el("div", "section-header");
        if (spec.IconName) header.appendChild(icon(spec.IconName, "section-icon"));
        header.appendChild(el("div", "section-title", { text: spec.Name }));
        header.appendChild(icon("chevron-down", "chev"));
        header.addEventListener("click", function () {
            box.classList.toggle("is-folded");
        });

        var body = el("div", "section-body");
        (spec.Elements || []).forEach(function (elementSpec, elementIndex) {
            var record = {
                tab: tabSpec.Name,
                section: spec.Name,
                spec: elementSpec,
                index: elementIndex,
            };
            record.node = buildElement(record);
            body.appendChild(record.node);
            state.records.push(record);
        });

        box.appendChild(header);
        box.appendChild(body);
        return box;
    }

    // ------------------------------------------------------------- elements --

    function keyFor(record) {
        return record.tab + "\u0000" + record.section + "\u0000" + record.index;
    }

    function buildElement(record) {
        var spec = record.spec;
        var node;

        switch (spec.Type) {
            case "Toggle":
            case "Checkbox":
                node = buildToggle(record);
                break;
            case "Slider":
                node = buildSlider(record);
                break;
            case "Dropdown":
                node = buildDropdown(record);
                break;
            case "Input":
                node = buildInput(record);
                break;
            case "Button":
                node = buildButton(record);
                break;
            case "Label":
                node = buildLabel(record);
                break;
            case "Divider":
                node = buildDivider(record);
                break;
            case "KeyPicker":
                node = buildKeyPicker(record);
                break;
            case "ColorPicker":
                node = buildColorPicker(record);
                break;
            default:
                node = el("div", "el");
                node.textContent = "Unsupported element: " + spec.Type;
        }

        if (spec.Tooltip) {
            node.addEventListener("mouseenter", function () {
                showTooltip(node, spec.Tooltip);
            });
            node.addEventListener("mouseleave", hideTooltip);
        }

        record.root = node;
        return node;
    }

    function applyDisabled(node, spec) {
        if (spec.Disabled) node.classList.add("is-disabled");
        if (spec.Risky) node.classList.add("is-risky");
    }

    // --- toggle / checkbox ----------------------------------------------------

    function variantOf(spec, record) {
        if (spec.Type === "Checkbox") return "Checkbox";
        if (spec.Type === "Toggle" && state.forceCheckbox && spec.Id !== "AutoScale") return "Checkbox";
        return "Switch";
    }

    function buildToggle(record) {
        var spec = record.spec;
        var key = keyFor(record);
        if (state.values[key] === undefined) state.values[key] = spec.Default === true;

        var node = el("div", "el el-toggle");
        applyDisabled(node, spec);

        node.appendChild(el("div", "el-text", { text: spec.Text }));

        var controlSlot = el("div", "", { style: { display: "flex", alignItems: "center", flex: "0 0 auto" } });
        node.appendChild(controlSlot);

        function paint() {
            controlSlot.textContent = "";
            var on = state.values[key] === true;
            var variant = variantOf(spec, record);
            var control;

            if (variant === "Checkbox") {
                control = el("div", "checkbox", { "data-on": on ? "true" : "false" });
                control.appendChild(icon("check"));
            } else {
                control = el("div", "switch", { "data-on": on ? "true" : "false" });
                control.appendChild(el("div", "knob"));
            }

            if (spec.Disabled) control.style.opacity = "0.6";
            controlSlot.appendChild(control);
        }

        function toggle() {
            if (spec.Disabled) return;
            state.values[key] = !state.values[key];
            paint();
            if (spec.Id === "AutoScale") {
                state.autoScale = state.values[key];
                requestScale();
            }
            if (spec.Text === "Force ALL toggles to render as checkboxes") {
                state.forceCheckbox = state.values[key];
                state.records.forEach(function (other) {
                    if (other.paintToggle && other.spec.Type === "Toggle") other.paintToggle();
                });
            }
        }

        node.addEventListener("click", toggle);
        record.paintToggle = paint;
        paint();
        return node;
    }

    // --- slider ---------------------------------------------------------------

    function decimals(spec) {
        return Math.max(0, Math.min(6, Math.round(spec.Rounding || 0)));
    }

    function formatValue(spec, value) {
        var text = formatNumber(value, decimals(spec));
        return (spec.Prefix || "") + text + (spec.Suffix || "");
    }

    function formatNumber(value, places) {
        var text = Number(value).toFixed(places);
        if (places > 0) text = text.replace(/\.?0+$/, "");
        return text;
    }

    function buildSlider(record) {
        var spec = record.spec;
        var key = keyFor(record);
        var min = spec.Min !== undefined ? spec.Min : 0;
        var max = spec.Max !== undefined ? spec.Max : 100;

        if (state.values[key] === undefined) {
            state.values[key] = clamp(spec.Default !== undefined ? spec.Default : min, min, max);
        }

        var hasValueBox = spec.Editable === true && (spec.EditableStyle || "ValueBox") === "ValueBox" && !spec.Compact;
        var node = el("div", "el el-slider" + (hasValueBox ? " has-valuebox" : ""));
        applyDisabled(node, spec);

        var top = el("div", "slider-top");
        top.appendChild(el("div", "el-text", { text: spec.Text }));

        var valueBox = null;
        if (hasValueBox) {
            valueBox = el("input", "slider-valuebox", {
                type: "text",
                inputmode: "decimal",
                spellcheck: "false",
            });
            valueBox.addEventListener("focus", function () {
                valueBox.select();
            });
            valueBox.addEventListener("change", function () {
                var parsed = parseFloat(valueBox.value);
                if (!isFinite(parsed)) parsed = state.values[key];
                state.values[key] = clamp(parsed, min, max);
                paint();
                onSliderChanged(record);
            });
            valueBox.addEventListener("keydown", function (event) {
                if (event.key === "Enter") valueBox.blur();
            });
            top.appendChild(valueBox);
        }

        var bar = el("div", "slider-bar");
        var fill = el("div", "slider-fill");
        var label = el("div", "slider-text");
        bar.appendChild(fill);
        bar.appendChild(label);

        node.appendChild(top);
        node.appendChild(bar);

        if (spec.Compact) {
            node.style.height = "15px";
            node.style.justifyContent = "flex-end";
            top.remove();
        }

        function paint() {
            var value = state.values[key];
            var ratio = max > min ? (value - min) / (max - min) : 0;
            fill.style.width = clamp(ratio, 0, 1) * 100 + "%";
            label.textContent = formatValue(spec, value);
            if (valueBox) valueBox.value = formatNumber(value, decimals(spec));
        }

        function setFromPointer(event) {
            var rect = bar.getBoundingClientRect();
            var ratio = clamp((event.clientX - rect.left) / rect.width, 0, 1);
            var raw = min + ratio * (max - min);
            var step = Math.pow(10, decimals(spec));
            state.values[key] = clamp(Math.round(raw * step) / step, min, max);
            paint();
            onSliderChanged(record);
        }

        var dragging = false;

        bar.addEventListener("pointerdown", function (event) {
            if (spec.Disabled) return;
            dragging = true;
            try {
                bar.setPointerCapture(event.pointerId);
            } catch (error) {
                /* synthetic events have no active pointer */
            }
            setFromPointer(event);
        });
        bar.addEventListener("pointermove", function (event) {
            if (dragging) setFromPointer(event);
        });
        bar.addEventListener("pointerup", function (event) {
            dragging = false;
            try {
                if (bar.hasPointerCapture(event.pointerId)) bar.releasePointerCapture(event.pointerId);
            } catch (error) {
                /* ignore */
            }
        });

        record.paintSlider = paint;
        paint();
        return node;
    }

    // Dragging the UI Scale slider takes over as a manual override, exactly like
    // Example.lua does (Library.AutoDPIScale becomes false).
    function onSliderChanged(record) {
        if (record.spec.Id !== "UIScale") return;
        state.dpi = state.values[keyFor(record)];
        if (state.autoScale) {
            state.autoScale = false;
            syncScaleControls();
        }
        requestScale();
    }

    // --- dropdown -------------------------------------------------------------

    var openDropdown = null;

    function closeDropdown() {
        if (openDropdown) {
            openDropdown.panel.remove();
            openDropdown = null;
        }
    }

    function dropdownValueText(spec, value) {
        if (spec.Multi) {
            var picked = Object.keys(value || {}).filter(function (k) {
                return value[k];
            });
            return picked.length ? picked.join(", ") : "None";
        }
        return value === undefined || value === null || value === "" ? "None" : String(value);
    }

    function buildDropdown(record) {
        var spec = record.spec;
        var key = keyFor(record);

        if (state.values[key] === undefined) {
            if (spec.Multi) state.values[key] = Object.assign({}, spec.Default || {});
            else state.values[key] = spec.Default !== undefined ? spec.Default : (spec.Values || [""])[0];
        }

        var node = el("div", "el el-dropdown");
        applyDisabled(node, spec);

        if (spec.Text) node.appendChild(el("div", "el-text", { text: spec.Text }));

        var display = el("div", "dropdown-display");
        var valueLabel = el("div", "value");
        display.appendChild(valueLabel);
        display.appendChild(icon("chevron-down", "chev"));
        node.appendChild(display);

        function paint() {
            valueLabel.textContent = dropdownValueText(spec, state.values[key]);
        }

        function openPanel() {
            if (openDropdown) closeDropdown();

            var panel = el("div", "dropdown-panel");
            var optionList = el("div", "dropdown-options");
            var filter = "";

            function renderOptions() {
                optionList.textContent = "";
                (spec.Values || []).forEach(function (option) {
                    if (filter && option.toLowerCase().indexOf(filter) === -1) return;

                    var selected = spec.Multi
                        ? state.values[key][option] === true
                        : String(state.values[key]) === String(option);

                    var row = el("div", "dropdown-option", {
                        "data-selected": selected ? "true" : "false",
                        "data-multi": spec.Multi ? "true" : "false",
                    });
                    var tick = icon("check", "tick");
                    if (tick) row.appendChild(tick);
                    row.appendChild(el("span", "", { text: option }));

                    row.addEventListener("click", function () {
                        if (spec.Multi) {
                            state.values[key][option] = !state.values[key][option];
                            paint();
                            renderOptions();
                        } else {
                            state.values[key] = option;
                            paint();
                            closeDropdown();
                        }
                    });

                    optionList.appendChild(row);
                });
            }

            if (spec.Searchable) {
                var search = el("input", "dropdown-search", {
                    type: "text",
                    placeholder: "Search…",
                    spellcheck: "false",
                });
                search.addEventListener("input", function () {
                    filter = search.value.toLowerCase();
                    renderOptions();
                });
                search.addEventListener("keydown", function (event) {
                    if (event.key === "Escape") closeDropdown();
                });
                panel.appendChild(search);
            }

            panel.appendChild(optionList);
            renderOptions();

            var r = toWindowPx(display.getBoundingClientRect());
            panel.style.right = "auto";
            panel.style.width = Math.max(120, r.width) + "px";
            panel.style.left = clamp(r.left, 4, WIN_W - parseFloat(panel.style.width) - 4) + "px";

            layer.appendChild(panel);
            layer.style.pointerEvents = "none";
            panel.style.pointerEvents = "auto";

            var panelHeight = panel.getBoundingClientRect().height / (win.getBoundingClientRect().width / WIN_W);
            var top = r.top + r.height + 3;
            if (top + panelHeight > WIN_H - 6) {
                top = Math.max(6, r.top - panelHeight - 3);
            }
            panel.style.top = top + "px";

            openDropdown = { panel: panel, display: display };

            if (spec.Searchable) {
                var input = panel.querySelector(".dropdown-search");
                if (input) input.focus();
            }
        }

        display.addEventListener("click", function () {
            if (spec.Disabled) return;
            if (openDropdown && openDropdown.display === display) closeDropdown();
            else openPanel();
        });

        paint();
        return node;
    }

    // --- input ---------------------------------------------------------------

    function buildInput(record) {
        var spec = record.spec;
        var key = keyFor(record);
        if (state.values[key] === undefined) state.values[key] = spec.Default || "";

        var node = el("div", "el el-input");
        applyDisabled(node, spec);

        node.appendChild(el("div", "el-text", { text: spec.Text }));

        var input = el("input", "", {
            type: "text",
            placeholder: spec.Placeholder || "",
            spellcheck: "false",
            value: state.values[key],
        });
        input.addEventListener("input", function () {
            state.values[key] = input.value;
        });
        node.appendChild(input);
        return node;
    }

    // --- button --------------------------------------------------------------

    function buildButton(record) {
        var spec = record.spec;

        var node = el("div", "el el-button");
        var button = el("button", "btn" + (spec.Risky ? " is-risky" : ""), {
            type: "button",
            disabled: spec.Disabled ? "" : null,
        });

        if (spec.Icon) {
            var glyph = icon(spec.Icon);
            if (glyph) button.appendChild(glyph);
        }
        button.appendChild(el("span", "", { text: spec.Text }));

        button.addEventListener("click", function () {
            runDemoAction(spec, record);
        });

        node.appendChild(button);
        return node;
    }

    // --- label / divider -----------------------------------------------------

    function buildLabel(record) {
        var spec = record.spec;
        var node = el("div", "el el-label" + (spec.DoesWrap ? " wrap" : ""), {
            html: rich(spec.Text),
        });
        if (spec.Size) node.style.fontSize = spec.Size + "px";
        return node;
    }

    function buildDivider(record) {
        var spec = record.spec;
        var node = el("div", "el el-divider");
        node.appendChild(el("div", "line"));
        if (spec.Text) {
            node.appendChild(el("div", "el-text", { text: spec.Text }));
            node.appendChild(el("div", "line"));
        }
        return node;
    }

    // --- key picker ----------------------------------------------------------

    var KEY_NAMES = {
        ControlRight: "RightControl",
        ControlLeft: "LeftControl",
        ShiftRight: "RightShift",
        ShiftLeft: "LeftShift",
        AltRight: "RightAlt",
        AltLeft: "LeftAlt",
        Space: "Space",
        Escape: "Escape",
        Enter: "Return",
        Backspace: "Backspace",
        Tab: "Tab",
        ArrowUp: "Up",
        ArrowDown: "Down",
        ArrowLeft: "Left",
        ArrowRight: "Right",
        CapsLock: "CapsLock",
    };

    function keyNameFromEvent(event) {
        if (KEY_NAMES[event.code]) return KEY_NAMES[event.code];
        if (/^Key[A-Z]$/.test(event.code)) return event.code.slice(3);
        if (/^Digit[0-9]$/.test(event.code)) return event.code.slice(5);
        if (/^F[0-9]{1,2}$/.test(event.code)) return event.code;
        if (event.key && event.key.length === 1) return event.key.toUpperCase();
        return event.code || "Unknown";
    }

    function buildKeyPicker(record) {
        var spec = record.spec;
        var key = keyFor(record);
        if (state.values[key] === undefined) state.values[key] = spec.Default || "";

        var node = el("div", "el el-keypicker");
        node.appendChild(el("div", "el-text", { text: spec.Text }));

        var box = el("div", "keybox", { "data-listening": "false" });
        node.appendChild(box);

        function paint() {
            box.textContent = state.values[key] || "None";
            box.setAttribute("data-listening", "false");
        }

        box.addEventListener("click", function (event) {
            event.stopPropagation();
            box.textContent = "… press a key";
            box.setAttribute("data-listening", "true");

            function onKey(event) {
                event.preventDefault();
                event.stopPropagation();
                if (event.key === "Escape") {
                    paint();
                } else {
                    state.values[key] = keyNameFromEvent(event);
                    paint();
                }
                window.removeEventListener("keydown", onKey, true);
            }

            window.addEventListener("keydown", onKey, true);
        });

        paint();
        return node;
    }

    // --- color picker --------------------------------------------------------

    function buildColorPicker(record) {
        var spec = record.spec;
        var key = keyFor(record);
        if (state.values[key] === undefined) state.values[key] = spec.Default || "#ffffff";

        var node = el("div", "el el-colorpicker");
        node.appendChild(el("div", "el-text", { text: spec.Text }));

        var swatch = el("div", "swatch");
        swatch.style.background = state.values[key];

        var input = el("input", "", { type: "color", value: state.values[key] });
        input.addEventListener("input", function () {
            state.values[key] = input.value;
            swatch.style.background = input.value;
        });
        swatch.appendChild(input);
        node.appendChild(swatch);
        return node;
    }

    // --- demo actions --------------------------------------------------------

    function runDemoAction(spec, record) {
        if (spec.Id === "ResetScale") {
            state.dpi = 5;
            state.autoScale = true;
            syncScaleControls();
            requestScale();
            return;
        }

        if (spec.Text === "SetValue (Basic Toggle)") {
            var basic = findRecord(function (r) {
                return r.spec.Id === "BasicToggle";
            });
            if (basic) {
                var key = keyFor(basic);
                state.values[key] = !state.values[key];
                basic.paintToggle();
            }
            return;
        }

        if (spec.Text === "SetText (Basic Toggle)") {
            var label = findRecord(function (r) {
                return r.spec.Id === "BasicToggle";
            });
            if (label) {
                var textNode = label.root.querySelector(".el-text");
                var on = state.values[keyFor(label)];
                textNode.textContent = on ? "Now ON" : "Now OFF";
            }
            return;
        }

        if (spec.Text === "SetDisabled (Disabled Toggle)") {
            var disabled = findRecord(function (r) {
                return r.spec.Disabled && r.spec.Type === "Toggle";
            });
            if (disabled && disabled.root) {
                disabled.root.classList.toggle("is-disabled");
            }
            return;
        }

        if (spec.Text === "SetMin (10)" || spec.Text === "SetMax (200)") {
            var slider = findRecord(function (r) {
                return r.spec.Type === "Slider" && r.spec.Text === "Speed";
            });
            if (slider) {
                if (spec.Text === "SetMin (10)") slider.spec.Min = 10;
                else slider.spec.Max = 200;
                slider.paintSlider();
            }
        }
    }

    function findRecord(predicate) {
        for (var i = 0; i < state.records.length; i += 1) {
            if (predicate(state.records[i])) return state.records[i];
        }
        return null;
    }

    // ------------------------------------------------------- scale controls ---

    function syncScaleControls() {
        var slider = findRecord(function (r) {
            return r.spec.Id === "UIScale";
        });
        if (slider) {
            state.values[keyFor(slider)] = state.dpi;
            slider.paintSlider();
        }
        var auto = findRecord(function (r) {
            return r.spec.Id === "AutoScale";
        });
        if (auto) {
            state.values[keyFor(auto)] = state.autoScale;
            auto.paintToggle();
        }
    }

    // ------------------------------------------------------------- scaling ---

    function fitScale(viewportW, viewportH) {
        // Mirrors Library:CalculateAutoBaseScale — 5% margin per side, uniform.
        var marginX = Math.max(viewportW * 0.05, 12);
        var marginY = Math.max(viewportH * 0.05, 12);
        var fit = Math.min((viewportW - marginX * 2) / WIN_W, (viewportH - marginY * 2) / WIN_H);
        return clamp(fit, 0.25, 1);
    }

    function windowScale(viewportW, viewportH) {
        var fit = fitScale(viewportW, viewportH);
        var multiplier = state.dpi / 5;
        var scale = fit * multiplier;

        // Library:SetDPIScale — auto mode caps the rendered window at what fits.
        if (state.autoScale) scale = Math.min(scale, fit);

        return clamp(scale, 0.25, 2);
    }

    function applyScale() {
        var width = parseFloat(stage.style.width) || stage.clientWidth;
        var height = parseFloat(stage.style.height) || stage.clientHeight;

        var scale = windowScale(width, height);
        document.documentElement.style.setProperty("--window-scale", String(scale));

        var wrap = stage.parentElement;
        var pad = 36;
        var zoom = Math.min(1, (wrap.clientWidth - pad) / width, (wrap.clientHeight - pad) / height);
        document.documentElement.style.setProperty("--stage-scale", String(zoom));

        var w = Math.round(WIN_W * scale);
        var h = Math.round(WIN_H * scale);
        readout.innerHTML =
            "<span><b>" + w + "×" + h + "</b> window</span>" +
            '<span class="dot"></span>' +
            "<span><b>" + Math.round(scale * 100) + "%</b> scale</span>" +
            '<span class="dot"></span>' +
            "<span>" + width + "×" + height + " viewport</span>" +
            '<span class="dot"></span>' +
            "<span>" + (state.autoScale ? "auto fit 5%" : "manual") + "</span>";
    }

    var scaleQueued = false;

    function requestScale() {
        // Apply synchronously: rAF is paused while the tab is hidden, and a
        // device switch should never leave the readout stale.
        if (scaleQueued) return;
        scaleQueued = true;
        applyScale();
        if (openDropdown) closeDropdown();
        scaleQueued = false;
    }

    // ----------------------------------------------------------- scrollbars --

    function attachScrollbar(scroller, host, options) {
        var opts = options || {};
        var wrap = el("div", "sb-wrap");
        wrap.style.position = "absolute";
        wrap.style.inset = "0";
        wrap.style.pointerEvents = "none";
        wrap.style.zIndex = "24";

        var track = el("div", "sb-track");
        var thumb = el("div", "sb-thumb");
        track.style.top = "0";
        track.style.height = "100%";
        wrap.appendChild(track);
        wrap.appendChild(thumb);
        host.appendChild(wrap);

        var hideTimer = null;
        var visible = false;

        function setVisible(next) {
            visible = next;
            wrap.classList.toggle("is-visible", next);
            if (hideTimer) {
                clearTimeout(hideTimer);
                hideTimer = null;
            }
            if (next) {
                hideTimer = setTimeout(function () {
                    if (!wrap.classList.contains("is-hovered") && !wrap.classList.contains("is-dragging")) {
                        setVisible(false);
                    }
                }, 1600);
            }
        }

        function update() {
            var scrollHeight = scroller.scrollHeight;
            var clientHeight = scroller.clientHeight;
            var overflow = scrollHeight - clientHeight;

            if (overflow <= 1) {
                wrap.style.display = "none";
                return;
            }
            wrap.style.display = "";

            var ratio = clientHeight / scrollHeight;
            var thumbHeight = Math.max(opts.minThumb || 24, clientHeight * ratio);
            var maxTop = clientHeight - thumbHeight;
            var top = overflow > 0 ? (scroller.scrollTop / overflow) * maxTop : 0;

            thumb.style.height = thumbHeight + "px";
            thumb.style.top = top + "px";
        }

        function reveal() {
            update();
            setVisible(true);
        }

        scroller.addEventListener("scroll", function () {
            update();
            setVisible(true);
        });

        host.addEventListener("mouseenter", function () {
            wrap.classList.add("is-hovered");
        });
        host.addEventListener("mouseleave", function () {
            wrap.classList.remove("is-hovered");
        });

        track.addEventListener("mouseenter", function () {
            if (!visible) reveal();
        });

        var drag = null;

        thumb.addEventListener("pointerdown", function (event) {
            event.preventDefault();
            event.stopPropagation();
            drag = { startY: event.clientY, startTop: scroller.scrollTop };
            try {
                thumb.setPointerCapture(event.pointerId);
            } catch (error) {
                /* synthetic events have no active pointer */
            }
            wrap.classList.add("is-dragging");
            setVisible(true);
        });

        thumb.addEventListener("pointermove", function (event) {
            if (!drag) return;
            var scale = (host.getBoundingClientRect().height || 1) / host.clientHeight;
            var delta = (event.clientY - drag.startY) / (scale || 1);
            var ratio = scroller.clientHeight / scroller.scrollHeight;
            scroller.scrollTop = drag.startTop + delta / Math.max(ratio, 0.001);
            update();
        });

        thumb.addEventListener("pointerup", function (event) {
            drag = null;
            wrap.classList.remove("is-dragging");
            try {
                if (thumb.hasPointerCapture(event.pointerId)) thumb.releasePointerCapture(event.pointerId);
            } catch (error) {
                /* ignore */
            }
        });

        new ResizeObserver(function () {
            update();
        }).observe(scroller);

        update();
        return { update: update, reveal: reveal };
    }

    // ------------------------------------------------------- search overlay ---

    function buildSearchIndex() {
        state.searchIndex = state.records
            .map(function (record) {
                var spec = record.spec;
                var text =
                    spec.Text ||
                    (spec.Type === "ColorPicker"
                        ? "Color picker"
                        : spec.Type === "Divider"
                          ? "Divider"
                          : spec.Type === "KeyPicker"
                            ? "Key picker"
                            : spec.Type);
                return {
                    record: record,
                    text: String(text),
                    crumb: record.tab + " › " + record.section,
                };
            })
            .filter(function (entry) {
                return entry.record.spec.Type !== "Divider";
            });
    }

    function openSearchOverlay() {
        var box = searchInput.parentElement.getBoundingClientRect();
        var r = toWindowPx(box);
        searchOverlay.classList.add("is-open");

        var width = 300;
        var left = clamp(r.left, 4, WIN_W - width - 4);
        searchOverlay.style.width = width + "px";
        searchOverlay.style.left = left + "px";
        searchOverlay.style.top = r.top + r.height + 4 + "px";
        searchOverlay.style.height = Math.min(400, WIN_H - (r.top + r.height + 10)) + "px";
    }

    function hideSearchOverlay() {
        searchOverlay.classList.remove("is-open");
        state.searchActive = 0;
    }

    function renderSearchResults(query) {
        var needle = query.trim().toLowerCase();
        searchScroll.textContent = "";

        if (!needle) {
            searchOverlay.classList.remove("is-open");
            return;
        }

        var matches = state.searchIndex.filter(function (entry) {
            return entry.text.toLowerCase().indexOf(needle) !== -1;
        });

        openSearchOverlay();
        state.searchMatches = matches;
        state.searchActive = 0;

        if (!matches.length) {
            searchScroll.appendChild(el("div", "search-empty", { text: "No results for “" + query + "”" }));
            return;
        }

        matches.forEach(function (entry, index) {
            var row = el("div", "search-row" + (index === 0 ? " is-active" : ""));
            row.appendChild(el("span", "crumb", { text: entry.crumb }));
            row.appendChild(el("span", "name", { html: highlightMatch(entry.text, needle) }));
            row.addEventListener("click", function () {
                jumpTo(entry.record);
                searchInput.value = "";
                hideSearchOverlay();
            });
            searchScroll.appendChild(row);
        });
    }

    function highlightMatch(text, needle) {
        var lower = text.toLowerCase();
        var at = lower.indexOf(needle);
        if (at === -1) return escapeHtml(text);
        return (
            escapeHtml(text.slice(0, at)) +
            "<b>" +
            escapeHtml(text.slice(at, at + needle.length)) +
            "</b>" +
            escapeHtml(text.slice(at + needle.length))
        );
    }

    function moveSearchActive(delta) {
        var rows = searchScroll.querySelectorAll(".search-row");
        if (!rows.length) return;
        state.searchActive = (state.searchActive + delta + rows.length) % rows.length;
        rows.forEach(function (row, index) {
            row.classList.toggle("is-active", index === state.searchActive);
        });
        var active = rows[state.searchActive];
        if (active) active.scrollIntoView({ block: "nearest" });
    }

    function jumpTo(record) {
        selectTab(record.tab);

        var sectionBox = record.root.closest(".section");
        if (sectionBox && sectionBox.classList.contains("is-folded")) {
            sectionBox.classList.remove("is-folded");
        }

        // Synchronous: the flash ring must not depend on a frame that a hidden
        // tab may never produce.
        var scroller = contentScroll;
        var node = record.root;
        var target = node.offsetTop - scroller.clientHeight / 2 + node.offsetHeight / 2;
        scroller.scrollTop = Math.max(0, target);
        flash(node);
    }

    function flash(node) {
        var ring = el("div", "flash-ring");
        var r = toWindowPx(node.getBoundingClientRect());
        ring.style.left = r.left - 3 + "px";
        ring.style.top = r.top - 3 + "px";
        ring.style.width = r.width + 6 + "px";
        ring.style.height = r.height + 6 + "px";
        layer.appendChild(ring);
        requestAnimationFrame(function () {
            ring.classList.add("is-flashing");
        });
        setTimeout(function () {
            ring.remove();
        }, 800);
    }

    // ---------------------------------------------------------------- events --

    function bindSearch() {
        searchInput.addEventListener("input", function () {
            renderSearchResults(searchInput.value);
        });
        searchInput.addEventListener("focus", function () {
            if (searchInput.value.trim()) renderSearchResults(searchInput.value);
        });
        searchInput.addEventListener("keydown", function (event) {
            if (event.key === "ArrowDown") {
                event.preventDefault();
                moveSearchActive(1);
            } else if (event.key === "ArrowUp") {
                event.preventDefault();
                moveSearchActive(-1);
            } else if (event.key === "Enter") {
                var match = state.searchMatches && state.searchMatches[state.searchActive];
                if (match) {
                    jumpTo(match.record);
                    searchInput.value = "";
                    hideSearchOverlay();
                }
            } else if (event.key === "Escape") {
                hideSearchOverlay();
                searchInput.blur();
            }
        });
        searchInput.addEventListener("blur", function () {
            setTimeout(function () {
                if (!searchOverlay.matches(":hover")) hideSearchOverlay();
            }, 120);
        });
    }

    function bindGlobalEvents() {
        // Explicit focus classes: `:focus` only matches while the browser
        // window itself is focused, which made the ring vanish on a blurred
        // window. Pointer-down is the reliable trigger; focusin keeps Tab
        // navigation working.
        function setFocusClass(target, on) {
            if (!target || target.tagName !== "INPUT") return;
            target.classList.toggle("is-focused", on);
            var box = target.closest(".searchbox");
            if (box) box.classList.toggle("is-focused", on);
        }

        function clearFocusClasses() {
            win.querySelectorAll("input.is-focused").forEach(function (input) {
                setFocusClass(input, false);
            });
            win.querySelectorAll(".searchbox.is-focused").forEach(function (box) {
                box.classList.remove("is-focused");
            });
        }

        win.addEventListener("pointerdown", function (event) {
            clearFocusClasses();
            setFocusClass(event.target, true);
        }, true);

        win.addEventListener("focusin", function (event) {
            setFocusClass(event.target, true);
        });

        win.addEventListener("focusout", function (event) {
            setFocusClass(event.target, false);
        });

        document.addEventListener("pointerdown", function (event) {
            if (openDropdown && !openDropdown.panel.contains(event.target) && !event.target.closest(".dropdown-display")) {
                closeDropdown();
            }
            if (
                searchOverlay.classList.contains("is-open") &&
                !searchOverlay.contains(event.target) &&
                event.target !== searchInput
            ) {
                hideSearchOverlay();
            }
        });

        window.addEventListener("keydown", function (event) {
            if (event.key === "Escape") closeDropdown();
        });

        window.addEventListener("resize", requestScale);
    }

    function bindToolbar() {
        document.querySelectorAll("[data-device]").forEach(function (button) {
            button.addEventListener("click", function () {
                applyDevice(button.getAttribute("data-device"));
            });
        });

        // Deep links for sharing a view: #device=932x430&tab=Settings
        var hash = location.hash.replace(/^#/, "");
        var params = {};
        hash.split("&").forEach(function (pair) {
            var bits = pair.split("=");
            if (bits[0]) params[bits[0]] = decodeURIComponent(bits[1] || "");
        });

        if (params.device && /^\d+x\d+$/.test(params.device)) {
            applyDevice(params.device);
        }
        if (params.tab && tabs[params.tab]) {
            selectTab(params.tab);
        }
    }

    function applyDevice(preset) {
        var size = preset.split("x");
        stage.style.width = size[0] + "px";
        stage.style.height = size[1] + "px";
        document.querySelectorAll("[data-device]").forEach(function (other) {
            other.setAttribute("aria-pressed", String(other.getAttribute("data-device") === preset));
        });
        requestScale();
    }

    // ------------------------------------------------------------------ boot --

    function boot() {
        applyTheme();
        buildWindow();

        // search overlay lives in the window layer so it scales with the window
        searchOverlay = el("div", "search-overlay");
        searchScroll = el("div", "search-overlay-scroll");
        searchOverlay.appendChild(searchScroll);
        layer.appendChild(searchOverlay);

        buildSidebar();
        buildContent();
        buildSearchIndex();
        bindSearch();
        bindGlobalEvents();
        bindToolbar();

        attachScrollbar(sidebarScroll, sidebarScroll.parentElement, { minThumb: 28 });
        contentScrollbar = attachScrollbar(contentScroll, contentScroll.parentElement, { minThumb: 24 });

        // first tab wins, like AutoShow picking the first tab in the library
        var firstTab = null;
        SPEC.TabSections.forEach(function (section) {
            if (!firstTab && section.Tabs.length) firstTab = section.Tabs[0].Name;
        });
        if (firstTab) {

            // Hash may already have selected a tab; otherwise open the first.
            if (!state.activeTab) selectTab(firstTab);
        }

        applyScale();
        window.addEventListener("resize", function () {
            applyScale();
            if (contentScrollbar) contentScrollbar.update();
        });

        // Section folding and tab switches change content height.
        var observer = new MutationObserver(function () {
            requestAnimationFrame(function () {
                if (contentScrollbar) contentScrollbar.update();
            });
        });
        observer.observe(contentScroll, {
            childList: true,
            subtree: true,
            attributes: true,
            attributeFilter: ["hidden", "class"],
        });

        document.addEventListener("scroll", hideTooltip, true);
    }

    boot();
})();
