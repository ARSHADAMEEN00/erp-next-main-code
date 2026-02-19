# How to Show or Hide Modules in ERPNext/Frappe

If you need to restore or hide specific modules (like Manufacturing, CRM, Projects, Support, etc.) in the sidebar, follow these steps:

### 1. Identify the Module Name

The modules are identified by their Workspace name, typically matching their display label.
Common modules include:

- `Accounting`
- `Buying`
- `Selling`
- `Stock`
- `Assets`
- `Manufacturing`
- `Projects`
- `Support`
- `CRM`
- `HR`
- `Payroll`
- `Quality`
- `Website`
- `Integrations`
- `Users`
- `Tools`
- `Build`

### 2. Edit the Management Script

Open the script at [`apps/frappe/frappe/manage_modules.py`](./apps/frappe/frappe/manage_modules.py).
Add or remove modules from the `keep_modules` list:

```python
    keep_modules = [
        "Accounting",
        "Buying",
        "Selling",
        "Stock",
        "Assets",
        "Home",
        "Osperb ERP",
        "Manufacturing", # <--- Add this line to show Manufacturing
        "Projects"       # <--- Add this line to show Projects
    ]
```

**Note:** If a module is NOT in this list, it will be HIDDEN when you run the script.

### 3. Run the Command

After saving your changes to the file, open your terminal in the `frappe-bench` directory and run:

```bash
bench --site ameenSite execute frappe.manage_modules.execute
```

This command will update the visibility settings in the database and clear the cache.

### 4. Refresh Your Browser

Go back to your ERPNext site and refresh the page. The sidebar should now reflect your changes.
If icons persist/disappear unexpectedly, try running `bench clear-cache` or `bench restart`.
