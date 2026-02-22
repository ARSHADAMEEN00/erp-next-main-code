import json

def execute():
    # Read the HTML file
    with open("/Users/ameenarshad/Projects/Frappe-demo/frappe-bench/apps/ameen_app/ameen_app/ameen_app/page/osperb_demo/osperb_demo.html", "r") as f:
        html_content = f.read()

    js_code = f"""
frappe.pages['osperb-demo'].on_page_load = function(wrapper) {{
	var page = frappe.ui.make_app_page({{
		parent: wrapper,
		title: 'Osperb Demo',
		single_column: true
	}});

	// Clean out any existing stuff and drop HTML directly inside wrapper
	$(wrapper).find('.layout-main-section').html({json.dumps(html_content)});
	
	// Hide page head just in case
	setTimeout(() => {{
		$(wrapper).find('.page-head').hide();
	}}, 100);
}}
"""
    
    with open("/Users/ameenarshad/Projects/Frappe-demo/frappe-bench/apps/ameen_app/ameen_app/ameen_app/page/osperb_demo/osperb_demo.js", "w") as f:
        f.write(js_code)

if __name__ == "__main__":
    execute()
