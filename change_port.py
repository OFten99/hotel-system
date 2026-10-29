# -*- coding: utf-8 -*-
"""将酒店系统 Web 端口改为 5001（避免与医院系统 5000 冲突）"""
from pathlib import Path

p = Path(__file__).resolve().parent / "web_app" / "app.py"
txt = p.read_text(encoding="utf-8")
old = 'app.run(host="127.0.0.1", port=5000, debug=True)'
new = 'app.run(host="127.0.0.1", port=5001, debug=True)'
assert old in txt, "未找到目标行"
p.write_text(txt.replace(old, new), encoding="utf-8")
print("已改端口 5000 -> 5001")
