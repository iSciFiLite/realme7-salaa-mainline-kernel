#!/usr/bin/env python3
"""Wrap one flattened device tree in the Android DT table format."""

import argparse
import struct
from pathlib import Path

DT_TABLE_MAGIC = 0xD7B7AB1E
DT_TABLE_HEADER_SIZE = 32
DT_TABLE_ENTRY_SIZE = 32
DT_TABLE_PAGE_SIZE = 2048
FDT_MAGIC = b"\xd0\x0d\xfe\xed"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path, help="flattened DTB")
    parser.add_argument("output", type=Path, help="Android DT table output")
    parser.add_argument("--id", type=lambda v: int(v, 0), default=0)
    parser.add_argument("--rev", type=lambda v: int(v, 0), default=0)
    args = parser.parse_args()

    dtb = args.input.read_bytes()
    if len(dtb) < 40 or dtb[:4] != FDT_MAGIC:
        parser.error(f"{args.input} is not a flattened device tree")
    totalsize = struct.unpack_from(">I", dtb, 4)[0]
    if totalsize > len(dtb):
        parser.error(f"FDT declares {totalsize} bytes, only {len(dtb)} available")
    dtb = dtb[:totalsize]

    entry_offset = DT_TABLE_HEADER_SIZE + DT_TABLE_ENTRY_SIZE
    total_size = entry_offset + len(dtb)
    header = struct.pack(
        ">8I",
        DT_TABLE_MAGIC,
        total_size,
        DT_TABLE_HEADER_SIZE,
        DT_TABLE_ENTRY_SIZE,
        1,
        DT_TABLE_HEADER_SIZE,
        DT_TABLE_PAGE_SIZE,
        0,
    )
    entry = struct.pack(
        ">8I", len(dtb), entry_offset, args.id, args.rev, 0, 0, 0, 0
    )
    args.output.write_bytes(header + entry + dtb)
    print(f"wrote {args.output}: {len(dtb)}-byte FDT in {total_size}-byte DT table")


if __name__ == "__main__":
    main()
