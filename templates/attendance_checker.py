import os
print("\n--- Student Attendance Tracker Active ---")
print(f"Current Directory Location: {os.getcwd()}")
os.makedirs("reports", exist_ok=True)
with open("reports/attendance.log", "w") as f:
f.write("Log Session Started.\n")
with open("reports/absent.log", "w") as f:
 f.write("Absence scan clean.\n")
print("Live session logs created inside reports/ folder.")
input("\nPress [Enter] to stop application execution loop...")
