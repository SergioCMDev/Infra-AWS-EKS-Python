import os
import re

input_file = r"k8s/observability/kube-prometheus-stack/crds/crds.yaml"
output_dir = r"k8s/observability/kube-prometheus-stack/crds-split"

os.makedirs(output_dir, exist_ok=True)

with open(input_file, "rb") as f:
    raw = f.read()

if raw.startswith(b"\xff\xfe"):
    content = raw.decode("utf-16-le")
elif raw.startswith(b"\xfe\xff"):
    content = raw.decode("utf-16-be")
elif raw.startswith(b"\xef\xbb\xbf"):
    content = raw.decode("utf-8-sig")
else:
    content = raw.decode("utf-8")

docs = [doc.strip() for doc in re.split(r'^\s*---\s*$', content, flags=re.MULTILINE) if doc.strip()]

for i, doc in enumerate(docs, start=1):
    name_match = re.search(r'^\s*name:\s*(.+)\s*$', doc, flags=re.MULTILINE)
    kind_match = re.search(r'^\s*kind:\s*(.+)\s*$', doc, flags=re.MULTILINE)

    name = name_match.group(1).strip() if name_match else f"crd-{i}"
    kind = kind_match.group(1).strip().lower() if kind_match else "crd"

    safe_name = re.sub(r'[^a-zA-Z0-9._-]+', '-', name).strip('-')
    safe_kind = re.sub(r'[^a-zA-Z0-9._-]+', '-', kind).strip('-')

    output_path = os.path.join(output_dir, f"{safe_name}.{safe_kind}.yaml")

    with open(output_path, "w", encoding="utf-8", newline="\n") as out:
        out.write(doc + "\n")

print(f"CRDs separados en: {output_dir}")
