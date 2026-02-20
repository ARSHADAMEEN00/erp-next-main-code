from passlib.hash import pbkdf2_sha256
import string

target_hash = "$pbkdf2-sha256$29000$GeNcSynFGIOwlpJyLsVYCw$Gp6j1xaPiOkMmq8N.6ZMKLNOunpWH3Y1/qbDyVDPhyQ"

words = [
    "admin", "password", "superadmin", "super",
    "ameen", "ameenarshad", "ameen_site", "erpnext", "frappe",
    "Admin", "Password", "Superadmin", "Super", "Administrator",
    "123", "1234", "12345", "123456", "12345678", "123456789"
]

suffixes = ["", "123", "!@#", "@123", "1234"]
prefixes = ["", "super"]

combinations = []
for p in prefixes:
    for w in words:
        for s in suffixes:
            combinations.append(p + w + s)

combinations = list(set(combinations))

for pwd in combinations:
    if pbkdf2_sha256.verify(pwd, target_hash):
        print(f"FOUND MATCH: {pwd}")
        break
else:
    print("No match found in common passwords.")
