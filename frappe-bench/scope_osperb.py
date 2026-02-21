import re
import os

css_path = "/Users/ameenarshad/Projects/Frappe-demo/frappe-bench/apps/ameen_app/ameen_app/public/css/osperb_desk_theme.css"
js_path = "/Users/ameenarshad/Projects/Frappe-demo/frappe-bench/apps/ameen_app/ameen_app/public/js/osperb_desk_theme.js"

with open(js_path, "r") as f:
    js_content = f.read()

# Modify isDesk to isDemo
js_content = js_content.replace(
    "function isDesk() {\n        return window.location.pathname.startsWith(\"/app\");\n    }",
    """function isDemoThemePage() {
        return window.location.pathname.includes("/osperb-demo");
    }"""
)

# Modify init
init_old = """    function init() {
        if (!isDesk()) return;
        if (document.getElementById(RAIL_ID)) return; // already mounted

        createRail();
        createPanel();
        renderSections("Home");
    }"""
init_new = """    function init() {
        if (!isDemoThemePage()) {
             document.body.classList.remove('osperb-theme-active');
             removeIfExists(RAIL_ID);
             removeIfExists(PANEL_ID);
             return;
        }
        document.body.classList.add('osperb-theme-active');
        if (document.getElementById(RAIL_ID)) return; // already mounted

        createRail();
        createPanel();
        renderSections("Home");
    }"""
js_content = js_content.replace(init_old, init_new)

with open(js_path, "w") as f:
    f.write(js_content)


with open(css_path, "r") as f:
    css_content = f.read()

# We need to prepend body.osperb-theme-active to broad selectors so they only affect the demo page
css_fixes = {
    "html,\nbody,\n.app-wrapper,\n.desk-container,\n.layout-main-section-wrapper": 
    "body.osperb-theme-active,\nbody.osperb-theme-active .app-wrapper,\nbody.osperb-theme-active .desk-container,\nbody.osperb-theme-active .layout-main-section-wrapper",
    
    "header.navbar,\n.navbar": 
    "body.osperb-theme-active header.navbar,\nbody.osperb-theme-active .navbar",
    
    ".layout-side-section,\n.desk-sidebar": 
    "body.osperb-theme-active .layout-side-section,\nbody.osperb-theme-active .desk-sidebar",
    
    ".layout-main-section-wrapper {\n    padding-left: 310px !important;\n    /* 74px rail + 236px panel */\n}": 
    "body.osperb-theme-active .layout-main-section-wrapper {\n    padding-left: 310px !important;\n}",
    
    ".card,\n.widget,\n.widget-body,\n.widget-group,\n.dashboard-widget": 
    "body.osperb-theme-active .card,\nbody.osperb-theme-active .widget,\nbody.osperb-theme-active .widget-body,\nbody.osperb-theme-active .widget-group,\nbody.osperb-theme-active .dashboard-widget",
    
    ".btn-primary {": 
    "body.osperb-theme-active .btn-primary {",
    
    ".form-control,\ninput,\nselect,\ntextarea {": 
    "body.osperb-theme-active .form-control,\nbody.osperb-theme-active input,\nbody.osperb-theme-active select,\nbody.osperb-theme-active textarea {",
    
    ".number-widget,\n.number-card {": 
    "body.osperb-theme-active .number-widget,\nbody.osperb-theme-active .number-card {"
}

for old, new in css_fixes.items():
    css_content = css_content.replace(old, new)

with open(css_path, "w") as f:
    f.write(css_content)

