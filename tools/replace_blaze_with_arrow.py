#!/usr/bin/env python3
"""Replace blaze enemy scenes with arrow in formation*.tscn files."""
import re
from pathlib import Path

FORMATIONS_DIR = Path(__file__).resolve().parent.parent / "scenes" / "enemies" / "formations"
ARROW_EXT = (
    '[ext_resource type="PackedScene" uid="uid://5qq7y15vdal6" '
    'path="res://scenes/enemies/types/arrow.tscn" id="{id}"]\n'
)
BLAZE_EXT_RE = re.compile(
    r'^\[ext_resource type="PackedScene" uid="[^"]+" '
    r'path="res://scenes/enemies/types/blaze_\d+\.tscn" id="([^"]+)"\]\s*$'
)
BLAZE_NODE_RE = re.compile(r'(\[node name=")blaze [^"]+(")')
INSTANCE_RE = re.compile(r'instance=ExtResource\("([^"]+)"\)')


def process_file(path: Path) -> bool:
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines(keepends=True)

    blaze_ids: list[str] = []
    new_lines: list[str] = []
    first_blaze_idx: int | None = None
    arrow_id: str | None = None
    has_arrow = False

    for line in lines:
        if 'path="res://scenes/enemies/types/arrow.tscn"' in line:
            has_arrow = True
            match = re.search(r'id="([^"]+)"', line)
            if match:
                arrow_id = match.group(1)
            new_lines.append(line)
            continue

        match = BLAZE_EXT_RE.match(line.rstrip("\n"))
        if match:
            blaze_ids.append(match.group(1))
            if first_blaze_idx is None:
                first_blaze_idx = len(new_lines)
            continue

        new_lines.append(line)

    if not blaze_ids:
        return False

    if arrow_id is None:
        arrow_id = blaze_ids[0]
        insert_at = first_blaze_idx if first_blaze_idx is not None else 0
        new_lines.insert(insert_at, ARROW_EXT.format(id=arrow_id))

    blaze_id_set = set(blaze_ids)
    out_lines: list[str] = []
    for line in new_lines:
        line = BLAZE_NODE_RE.sub(r"\1arrow\2", line)

        def repl_instance(match: re.Match[str]) -> str:
            resource_id = match.group(1)
            if resource_id in blaze_id_set:
                return f'instance=ExtResource("{arrow_id}")'
            return match.group(0)

        line = INSTANCE_RE.sub(repl_instance, line)
        out_lines.append(line)

    new_text = "".join(out_lines)
    if new_text == text:
        return False

    path.write_text(new_text, encoding="utf-8", newline="")
    return True


def main() -> None:
    skip = {"formation1.tscn"}
    changed: list[str] = []

    for path in sorted(FORMATIONS_DIR.glob("formation*.tscn")):
        if path.name in skip:
            continue
        if process_file(path):
            changed.append(path.name)

    print(f"Updated {len(changed)} files:")
    for name in changed:
        print(f"  {name}")


if __name__ == "__main__":
    main()
