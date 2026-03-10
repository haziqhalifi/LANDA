import os

def resolve_file(filepath, mode="keep_both"):
    with open(filepath, "r", encoding="utf-8") as f:
        lines = f.readlines()
        
    new_lines = []
    in_conflict = False
    side = None
    
    for line in lines:
        if line.startswith("<<<<<<< HEAD"):
            in_conflict = True
            side = "ours"
            continue
        elif line.startswith("======="):
            side = "theirs"
            continue
        elif line.startswith(">>>>>>>"):
            in_conflict = False
            side = None
            continue
            
        if not in_conflict:
            new_lines.append(line)
        else:
            if mode == "keep_both":
                new_lines.append(line)
            elif mode == "keep_ours" and side == "ours":
                new_lines.append(line)
            elif mode == "keep_theirs" and side == "theirs":
                new_lines.append(line)
                
    with open(filepath, "w", encoding="utf-8") as f:
        f.writelines(new_lines)

resolve_file("backend_fastapi/app/main.py", "keep_ours")
resolve_file("frontend_flutter/disaster_resilience_ai/pubspec.lock", "keep_theirs")
resolve_file("backend_fastapi/app/schemas/family.py", "keep_both")
resolve_file("backend_fastapi/app/api/v1/endpoints/family.py", "keep_both")
resolve_file("backend_fastapi/app/api/v1/endpoints/warnings.py", "keep_both")
resolve_file("backend_fastapi/app/db/family.py", "keep_both")

print("Resolved files.")
