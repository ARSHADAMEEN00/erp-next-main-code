# ERPNext Accounting Integration via API

## Overview
This guide explains how to integrate your production dashboard with ERPNext's accounting system using standard ERPNext DocTypes via API. This approach leverages ERPNext's built-in accounting logic without creating custom accounting modules.

---

## Why Use ERPNext's Standard DocTypes?

✅ **Benefits:**
- Leverages ERPNext's robust accounting engine
- Automatic GL (General Ledger) entry creation
- Built-in tax calculations and compliance
- Works with all ERPNext financial reports
- Maintains accounting integrity
- No need to recreate accounting logic

---

## Common Accounting Scenarios

### 1. Sales Order Placed → Create Sales Invoice

**Use Case:** When a customer places an order in your production dashboard, create a Sales Invoice in ERPNext.

**API Endpoint:** `POST /api/method/ameen_app.api.create_sales_invoice`

**Request Body:**
```json
{
  "customer": "Customer Name",
  "posting_date": "2026-02-11",
  "items": [
    {
      "item_code": "ITEM-001",
      "qty": 2,
      "rate": 1000,
      "description": "Product Description"
    }
  ]
}
```

**Implementation:**
```python
# Add to: frappe-bench/apps/ameen_app/ameen_app/api.py

@frappe.whitelist(allow_guest=True)
def create_sales_invoice(customer, items, posting_date=None):
    """
    Create a Sales Invoice from external order
    
    Args:
        customer: Customer name or ID
        items: List of items with item_code, qty, rate
        posting_date: Invoice date (optional, defaults to today)
    """
    try:
        if not posting_date:
            posting_date = frappe.utils.today()
        
        # Parse items if sent as JSON string
        if isinstance(items, str):
            import json
            items = json.loads(items)
        
        # Create Sales Invoice
        invoice = frappe.get_doc({
            "doctype": "Sales Invoice",
            "customer": customer,
            "posting_date": posting_date,
            "items": items
        })
        
        invoice.insert(ignore_permissions=True)
        invoice.submit()  # Auto-submit to create GL entries
        frappe.db.commit()
        
        return {
            "status": "success",
            "message": "Sales Invoice created successfully",
            "data": {
                "name": invoice.name,
                "grand_total": invoice.grand_total
            }
        }
    except Exception as e:
        frappe.log_error(f"Error creating sales invoice: {str(e)}", "Create Sales Invoice API")
        frappe.response["status_code"] = 500
        return {"status": "error", "message": str(e)}
```

---

### 2. Payment Received → Create Payment Entry

**Use Case:** When a customer makes a payment, record it in ERPNext.

**API Endpoint:** `POST /api/method/ameen_app.api.create_payment_entry`

**Request Body:**
```json
{
  "party_type": "Customer",
  "party": "Customer Name",
  "paid_amount": 5000,
  "payment_type": "Receive",
  "mode_of_payment": "Cash",
  "reference_no": "TXN123456",
  "reference_date": "2026-02-11"
}
```

**Implementation:**
```python
@frappe.whitelist(allow_guest=True)
def create_payment_entry(party_type, party, paid_amount, payment_type="Receive", 
                         mode_of_payment="Cash", reference_no=None, reference_date=None):
    """
    Create a Payment Entry
    
    Args:
        party_type: "Customer" or "Supplier"
        party: Party name
        paid_amount: Amount paid
        payment_type: "Receive" or "Pay"
        mode_of_payment: Cash, Bank Transfer, etc.
        reference_no: Transaction reference
        reference_date: Payment date
    """
    try:
        if not reference_date:
            reference_date = frappe.utils.today()
        
        payment = frappe.get_doc({
            "doctype": "Payment Entry",
            "payment_type": payment_type,
            "party_type": party_type,
            "party": party,
            "paid_amount": paid_amount,
            "received_amount": paid_amount,
            "mode_of_payment": mode_of_payment,
            "reference_no": reference_no,
            "reference_date": reference_date
        })
        
        payment.insert(ignore_permissions=True)
        payment.submit()
        frappe.db.commit()
        
        return {
            "status": "success",
            "message": "Payment Entry created successfully",
            "data": {
                "name": payment.name,
                "paid_amount": payment.paid_amount
            }
        }
    except Exception as e:
        frappe.log_error(f"Error creating payment entry: {str(e)}", "Create Payment Entry API")
        frappe.response["status_code"] = 500
        return {"status": "error", "message": str(e)}
```

---

### 3. Manual Accounting Entry → Create Journal Entry

**Use Case:** For custom accounting transactions (adjustments, transfers, etc.)

**API Endpoint:** `POST /api/method/ameen_app.api.create_journal_entry`

**Request Body:**
```json
{
  "posting_date": "2026-02-11",
  "accounts": [
    {
      "account": "Debtors - Company",
      "debit_in_account_currency": 5000
    },
    {
      "account": "Sales - Company",
      "credit_in_account_currency": 5000
    }
  ]
}
```

**Implementation:**
```python
@frappe.whitelist(allow_guest=True)
def create_journal_entry(posting_date, accounts, user_remark=None):
    """
    Create a Journal Entry for manual accounting
    
    Args:
        posting_date: Entry date
        accounts: List of account entries with debit/credit
        user_remark: Optional description
    """
    try:
        if isinstance(accounts, str):
            import json
            accounts = json.loads(accounts)
        
        journal = frappe.get_doc({
            "doctype": "Journal Entry",
            "posting_date": posting_date,
            "accounts": accounts,
            "user_remark": user_remark
        })
        
        journal.insert(ignore_permissions=True)
        journal.submit()
        frappe.db.commit()
        
        return {
            "status": "success",
            "message": "Journal Entry created successfully",
            "data": {
                "name": journal.name
            }
        }
    except Exception as e:
        frappe.log_error(f"Error creating journal entry: {str(e)}", "Create Journal Entry API")
        frappe.response["status_code"] = 500
        return {"status": "error", "message": str(e)}
```

---

## Prerequisites Setup

### 1. Create Customer/Supplier Master Data

Before creating transactions, ensure customers exist in ERPNext.

**API to Create Customer:**
```python
@frappe.whitelist(allow_guest=True)
def create_customer(customer_name, customer_type="Individual", customer_group="Individual"):
    """
    Create a new Customer in ERPNext
    """
    try:
        if frappe.db.exists("Customer", customer_name):
            return {
                "status": "success",
                "message": "Customer already exists",
                "data": {"name": customer_name}
            }
        
        customer = frappe.get_doc({
            "doctype": "Customer",
            "customer_name": customer_name,
            "customer_type": customer_type,
            "customer_group": customer_group,
            "territory": "All Territories"
        })
        
        customer.insert(ignore_permissions=True)
        frappe.db.commit()
        
        return {
            "status": "success",
            "message": "Customer created successfully",
            "data": {"name": customer.name}
        }
    except Exception as e:
        frappe.log_error(f"Error creating customer: {str(e)}", "Create Customer API")
        frappe.response["status_code"] = 500
        return {"status": "error", "message": str(e)}
```

### 2. Create Items

**API to Create Item:**
```python
@frappe.whitelist(allow_guest=True)
def create_item(item_code, item_name, item_group="Products", stock_uom="Nos", standard_rate=0):
    """
    Create a new Item in ERPNext
    """
    try:
        if frappe.db.exists("Item", item_code):
            return {
                "status": "success",
                "message": "Item already exists",
                "data": {"name": item_code}
            }
        
        item = frappe.get_doc({
            "doctype": "Item",
            "item_code": item_code,
            "item_name": item_name,
            "item_group": item_group,
            "stock_uom": stock_uom,
            "standard_rate": standard_rate,
            "is_stock_item": 0  # Set to 1 if inventory tracking needed
        })
        
        item.insert(ignore_permissions=True)
        frappe.db.commit()
        
        return {
            "status": "success",
            "message": "Item created successfully",
            "data": {"name": item.name}
        }
    except Exception as e:
        frappe.log_error(f"Error creating item: {str(e)}", "Create Item API")
        frappe.response["status_code"] = 500
        return {"status": "error", "message": str(e)}
```

---

## Complete Workflow Example

### Scenario: Order Placed in Production Dashboard

**Step 1: Ensure Customer Exists**
```javascript
// In your React app
const response = await fetch('/api/method/ameen_app.api.create_customer', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
        customer_name: 'John Doe',
        customer_type: 'Individual'
    })
});
```

**Step 2: Create Sales Invoice**
```javascript
const invoiceResponse = await fetch('/api/method/ameen_app.api.create_sales_invoice', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
        customer: 'John Doe',
        posting_date: '2026-02-11',
        items: [
            {
                item_code: 'SERVICE-001',
                qty: 1,
                rate: 5000,
                description: 'Web Development Service'
            }
        ]
    })
});
```

**Step 3: Record Payment (if paid immediately)**
```javascript
const paymentResponse = await fetch('/api/method/ameen_app.api.create_payment_entry', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
        party_type: 'Customer',
        party: 'John Doe',
        paid_amount: 5000,
        payment_type: 'Receive',
        mode_of_payment: 'Cash',
        reference_no: 'ORDER-12345'
    })
});
```

---

## Testing with Postman

### Test Sales Invoice Creation

**URL:** `http://127.0.0.1:8000/api/method/ameen_app.api.create_sales_invoice`

**Method:** POST

**Body (form-data):**
```
customer: Test Customer
posting_date: 2026-02-11
items: [{"item_code": "ITEM-001", "qty": 2, "rate": 1000}]
```

---

## Security Considerations

### For Production:

1. **Remove `allow_guest=True`** and implement proper authentication
2. **Add API Key validation**:
```python
@frappe.whitelist()
def create_sales_invoice(customer, items, posting_date=None):
    # Validate API key
    api_key = frappe.get_request_header("Authorization")
    if not validate_api_key(api_key):
        frappe.throw("Invalid API Key")
    
    # Rest of the code...
```

3. **Use Token-based authentication** with Frappe's built-in OAuth

---

## Implementation Checklist

- [ ] Add API functions to `ameen_app/api.py`
- [ ] Clear cache: `bench --site ameenSite clear-cache`
- [ ] Test with Postman
- [ ] Create master data (Customers, Items)
- [ ] Test complete workflow
- [ ] Add error handling and logging
- [ ] Implement authentication for production
- [ ] Document API endpoints for frontend team

---

## Next Steps

When you're ready to implement:

1. Copy the API functions to your `api.py` file
2. Run `bench --site ameenSite clear-cache`
3. Test each endpoint with Postman
4. Integrate with your React dashboard
5. Monitor ERPNext's Error Log for any issues

---

## Support Resources

- **ERPNext API Documentation**: https://frappeframework.com/docs/user/en/api
- **ERPNext Accounting Docs**: https://docs.erpnext.com/docs/user/manual/en/accounts
- **Frappe Framework Docs**: https://frappeframework.com/docs

---

**Created:** 2026-02-11  
**For:** Ameen App - ERPNext Integration  
**Status:** Documentation - Ready for Implementation
