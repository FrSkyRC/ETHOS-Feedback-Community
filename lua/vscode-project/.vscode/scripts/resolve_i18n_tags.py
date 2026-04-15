# i18n/resolve_i18n_tags.py
#!/usr/bin/env python3
"""
Resolve @i18n(...)@ tags into translated strings.

\1

Options:
  --list-transforms        List available transforms and exit

Tag syntax
-----------
@i18n(KEY[, basic_modifier])[:transform(args)...]@

Examples:
  @i18n(app.msg_reload_settings)@
  @i18n(app.msg_reload_settings,upper)@
  @i18n(app.msg_reload_settings):truncate(10)@
  @i18n(app.msg_reload_settings):upperfirst():suffix("!")@

Rules:
- KEY is a dotted path into the JSON translations.
- basic_modifier is optional: "upper" or "lower" (legacy support).
- Any number of transforms may be chained after the closing parenthesis,
  separated by colons. They are applied left → right.
- Arguments to transforms are comma-separated. Strings may be quoted
  with "..." or '...'. Numbers are parsed as int/float. true/false → bool.

Built-in transforms
-------------------
Case:
  upper()       – uppercase
  lower()       – lowercase
  upperfirst()  – first char uppercase, rest lowercase
  capitalize()  – first char uppercase, rest unchanged
  title()       – title case (capitalize each word)
  swapcase()    – invert case

Whitespace:
  trim() / ltrim() / rtrim() – strip whitespace
  collapse_ws()              – collapse multiple spaces/newlines to one space

Length / padding:
  truncate(n[, ellipsis])    – cut to length n, optional ellipsis
  slice(start[, end])        – substring (Python slicing)
  padleft(width[, char])     – left-pad
  padright(width[, char])    – right-pad
  center(width[, char])      – center with padding

Find / replace:
  replace(old,new[,count])   – literal replace
  remove(pattern)            – regex remove
  keep(pattern)              – keep only regex matches
  strip_prefix(pfx)          – remove prefix if present
  strip_suffix(sfx)          – remove suffix if present
  prefix(s) / suffix(s)      – add before/after

Escaping:
  escape_html()              – replace <, >, & with HTML entities
  escape_json()              – escape backslashes and quotes

Notes:
- Unknown transforms are ignored (logged in stats).
- Errors inside a transform do not stop processing; they are recorded.
- After transforms, output is sanitized for safe insertion
  (newlines → "
", double quotes escaped).

CLI examples
------------
  # Preview changes without writing:
  python resolve_i18n_tags.py --json scripts/rfsuite/i18n/en.json --root src --dry-run

  # Apply replacements in-place:
  python resolve_i18n_tags.py --json scripts/rfsuite/i18n/en.json --root src
"""
#!/usr/bin/env python3
import argparse, json, re, sys, os
from pathlib import Path
import shlex
import html
import re as _re

# --- replace your TAG_RE with this (note: IGNORECASE for transforms) ---
TAG_RE = re.compile(
    r'@i18n\(\s*([^)@,]+?)\s*(?:,\s*(upper|lower))?\s*\)'      # @i18n(key[, basic_mod])
    r'((?::[a-z_]+(?:\([^@]*?\))?)*)@',                        # :t1(...):t2 ...
    flags=re.IGNORECASE
)

def _coerce_atom(s: str):
    # try int -> float -> bareword -> string
    try:
        return int(s)
    except ValueError:
        try:
            return float(s)
        except ValueError:
            if s.lower() in ('true', 'false'):
                return s.lower() == 'true'
            return s  # leave as string

def _parse_chain(chain: str):
    """
    chain like ':truncate(10):suffix("…"):replace("x","y",1)'
    -> [('truncate',[10],{}), ('suffix',['…'],{}), ('replace',['x','y',1],{})]
    """
    if not chain:
        return []
    out = []
    # find all segments like :name(args?)
    for seg in filter(None, chain.split(':')):
        m = _re.match(r'([a-z_][a-z0-9_]*)\s*(?:\((.*)\))?$', seg, flags=_re.IGNORECASE)
        if not m:
            continue
        name, argstr = m.group(1).lower(), (m.group(2) or '').strip()
        args = []
        if argstr:
            # shlex handles quotes and commas inside quotes poorly by default;
            # split on commas at top level (no nested parens in our simple grammar).
            parts = []
            current = ''
            depth = 0
            for ch in argstr:
                if ch == '(':
                    depth += 1
                    current += ch
                elif ch == ')':
                    depth = max(0, depth - 1)
                    current += ch
                elif ch == ',' and depth == 0:
                    parts.append(current.strip())
                    current = ''
                else:
                    current += ch
            if current.strip():
                parts.append(current.strip())
            # now strip quotes with shlex (supports "…" or '…')
            for p in parts:
                parsed = shlex.split(p) if p else []
                if len(parsed) == 1:
                    args.append(_coerce_atom(parsed[0]))
                elif len(parsed) == 0:
                    args.append('')
                else:
                    # if someone wrote unescaped spaces not in quotes, join them
                    args.append(_coerce_atom(' '.join(parsed)))
        out.append((name, args, {}))
    return out

def _upperfirst(s: str) -> str:
    return s[:1].upper() + s[1:].lower() if s else s

def _truncate(s: str, n: int, ellipsis: str | None = None) -> str:
    if n < 0: 
        return s
    if len(s) <= n:
        return s
    if ellipsis:
        if n <= len(ellipsis):
            return ellipsis[:n]
        return s[: n - len(ellipsis)] + ellipsis
    return s[:n]

def _collapse_ws(s: str) -> str:
    return _re.sub(r'\s+', ' ', s).strip()

def _slice(s: str, start: int, end: int | None = None) -> str:
    return s[start:end]  # Python slicing semantics

def _ensure_char(c: str) -> str:
    return c[0] if isinstance(c, str) and c else ' '

TRANSFORMS = {
    # case
    'upper': lambda s: s.upper(),
    'lower': lambda s: s.lower(),
    'upperfirst': _upperfirst,
    'capitalize': lambda s: s[:1].upper() + s[1:],
    'title': lambda s: s.title(),
    'swapcase': lambda s: s.swapcase(),

    # trim / spacing
    'trim': lambda s: s.strip(),
    'ltrim': lambda s: s.lstrip(),
    'rtrim': lambda s: s.rstrip(),
    'collapse_ws': _collapse_ws,

    # length / slicing / padding
    'truncate': lambda s, n, ellipsis=None: _truncate(s, int(n), ellipsis),
    'slice': _slice,
    'padleft': lambda s, width, char=' ': s.rjust(int(width), _ensure_char(char)),
    'padright': lambda s, width, char=' ': s.ljust(int(width), _ensure_char(char)),
    'center': lambda s, width, char=' ': s.center(int(width), _ensure_char(char)),

    # find / replace
    'replace': lambda s, old, new, count=None: s.replace(str(old), str(new), int(count) if count is not None else -1),
    'remove': lambda s, pattern: _re.sub(str(pattern), '', s),
    'keep': lambda s, pattern: ' '.join(_re.findall(str(pattern), s)),
    'strip_prefix': lambda s, p: s[len(p):] if s.startswith(str(p)) else s,
    'strip_suffix': lambda s, p: s[:-len(p)] if len(p) and s.endswith(str(p)) else s,
    'prefix': lambda s, p: str(p) + s,
    'suffix': lambda s, p: s + str(p),

    # escaping
    'escape_html': lambda s: html.escape(s, quote=True),
    'escape_json': lambda s: s.replace('\\', '\\\\').replace('"', r'\"'),
}

TRANSFORM_HELP = {
    # case
    'upper':        'upper() – uppercase',
    'lower':        'lower() – lowercase',
    'upperfirst':   'upperfirst() – first char uppercase, rest lowercase',
    'capitalize':   'capitalize() – first char uppercase, rest unchanged',
    'title':        'title() – title case (capitalize each word)',
    'swapcase':     'swapcase() – invert case',

    # whitespace
    'trim':         'trim() – strip leading/trailing whitespace',
    'ltrim':        'ltrim() – strip leading whitespace',
    'rtrim':        'rtrim() – strip trailing whitespace',
    'collapse_ws':  'collapse_ws() – collapse multiple spaces/newlines to one space',

    # length / padding
    'truncate':     'truncate(n[, ellipsis]) – cut to length n, optional ellipsis',
    'slice':        'slice(start[, end]) – substring (Python slicing)',
    'padleft':      'padleft(width[, char]) – left-pad',
    'padright':     'padright(width[, char]) – right-pad',
    'center':       'center(width[, char]) – center with padding',

    # find / replace
    'replace':      'replace(old,new[,count]) – literal replace',
    'remove':       'remove(pattern) – regex remove',
    'keep':         'keep(pattern) – keep only regex matches',
    'strip_prefix': 'strip_prefix(pfx) – remove prefix if present',
    'strip_suffix': 'strip_suffix(sfx) – remove suffix if present',
    'prefix':       'prefix(s) – add before',
    'suffix':       'suffix(s) – add after',

    # escaping
    'escape_html':  'escape_html() – replace <, >, & with HTML entities',
    'escape_json':  'escape_json() – escape backslashes and quotes',
}
def print_transform_list():
    keys = sorted(TRANSFORM_HELP.keys())
    print("[i18n] Available transforms:")
    for k in keys:
        print("  - " + TRANSFORM_HELP[k])

def apply_transform_pipeline(s: str, basic_mod: str | None, chain: str, stats: dict) -> str:
    # basic_mod from @i18n(key, upper|lower)
    if basic_mod:
        fn = TRANSFORMS.get(basic_mod.lower())
        if fn:
            s = fn(s)

    for name, args, _ in _parse_chain(chain):
        fn = TRANSFORMS.get(name)
        if not fn:
            stats.setdefault('unknown_transform', {}).setdefault(name, 0)
            stats['unknown_transform'][name] += 1
            continue
        try:
            s = fn(s, *args)
        except Exception as e:
            stats.setdefault('transform_errors', []).append(f"{name}({args}) -> {e}")
    return s


def load_translations(path: Path) -> dict:
    with path.open('r', encoding='utf-8') as f:
        return json.load(f)

def resolve_key(tree: dict, dotted: str):
    """
    Walk dotted path. If the leaf is a dict like
    { english: "...", translation: "...", reverse_text: true/false },
    prefer 'translation', fall back to 'english'. Otherwise cast to str.
    """
    node = tree
    for part in dotted.split('.'):
        if not isinstance(node, dict) or part not in node:
            return None
        node = node[part]

    # Leaf handling
    if isinstance(node, dict):
        reverse_flag = node.get('reverse_text') if isinstance(node.get('reverse_text'), bool) else None
        # common schema: english/translation/needs_translation
        if 'translation' in node and isinstance(node['translation'], (str, int, float)):
            return str(node['translation']), reverse_flag
        if 'english' in node and isinstance(node['english'], (str, int, float)):
            return str(node['english']), reverse_flag
        # if dict but not the expected shape, refuse
        return None

    if node is None:
        return None

    # Primitive leaf
    return str(node), None

def apply_modifier(s: str, mod: str | None):
    if not mod:
        return s
    if mod == 'upper':
        return s.upper()
    if mod == 'lower':
        return s.lower()
    return s  # unknown modifier, ignore

def _sanitize_for_insertion(s: str) -> str:
    """
    Ensure:
      - any CRLF/CR become LF,
      - literal backslash-n sequences are written for line breaks,
      - double quotes are escaped.
    """
    # Normalize all newlines to LF
    s = s.replace("\r\n", "\n").replace("\r", "\n")
    # Turn actual LF characters into the two-character sequence \n
    s = s.replace("\n", r"\n")
    # Escape double quotes
    s = s.replace('"', r'\"')
    return s

def _reverse_text_for_hebrew_display(s: str) -> str:
    # Reverse each logical line to compensate for environments that render RTL text backwards.
    normalized = s.replace("\r\n", "\n").replace("\r", "\n")
    return "\n".join(line[::-1] for line in normalized.split("\n"))

def _contains_hebrew_chars(s: str) -> bool:
    return _re.search(r'[\u0590-\u05FF]', s) is not None

def _should_reverse_text(text: str, reverse_flag: bool | None) -> bool:
    if reverse_flag is True:
        return True
    if reverse_flag is False:
        return False
    return _contains_hebrew_chars(text)

def replace_tags_in_text(text: str, translations: dict, stats: dict):
    def _sub(m: re.Match):
        key = m.group(1).strip()
        basic_mod = m.group(2)  # upper|lower
        chain = m.group(3) or ''  # like ':truncate(10):suffix("…")'

        resolved = resolve_key(translations, key)
        if resolved is None:
            stats.setdefault('unresolved', {}).setdefault(key, 0)
            stats['unresolved'][key] += 1
            return m.group(0)  # leave tag untouched
        resolved_text, reverse_flag = resolved
        # apply pipeline then sanitize for insertion into code
        resolved_text = apply_transform_pipeline(str(resolved_text), basic_mod, chain, stats)
        if _should_reverse_text(resolved_text, reverse_flag):
            resolved_text = _reverse_text_for_hebrew_display(resolved_text)
        resolved_text = _sanitize_for_insertion(resolved_text)
        return resolved_text

    new_text, n = TAG_RE.subn(_sub, text)
    return new_text, n

def process_file(path: Path, translations: dict, dry_run=False):
    before = path.read_text(encoding='utf-8')
    stats = {}
    new_text, n = replace_tags_in_text(before, translations, stats)

    if n == 0:
        return 0, stats.get('unresolved', {})

    if dry_run:
        print(f"[i18n] DRY-RUN would update {path} — {n} replacement(s)")
        return n, stats.get('unresolved', {})

    # check writability (best-effort on Windows)
    writable = os.access(path, os.W_OK) and os.access(path.parent, os.W_OK)
    if not writable:
        print(f"[i18n] NOTE: {path} looks protected (Program Files?) — you may need to run elevated or deploy to a staging folder first.")

    # attempt write with good diagnostics
    try:
        path.write_text(new_text, encoding='utf-8')
    except PermissionError as e:
        print(f"[i18n] FAILED to write (permission): {path} — {e}")
        return 0, stats.get('unresolved', {})
    except OSError as e:
        print(f"[i18n] FAILED to write (os error): {path} — {e}")
        return 0, stats.get('unresolved', {})

    # verify the write actually stuck
    try:
        after = path.read_text(encoding='utf-8')
    except Exception as e:
        print(f"[i18n] WARNING: couldn’t read back for verify: {path} — {e}")
        after = None

    if after is None or after == before:
        print(f"[i18n] WARNING: write verification shows no change: {path}")
        return 0, stats.get('unresolved', {})

    return n, stats.get('unresolved', {})

def iter_source_files(root: Path, exts=('.lua', '.ts', '.tsx', '.js', '.jsx', '.json', '.md', '.txt')):
    for p in root.rglob('*'):
        if p.is_file() and p.suffix.lower() in exts:
            yield p

def main():
    ap = argparse.ArgumentParser(description="Resolve @i18n(...)@ tags in a codebase")
    ap.add_argument('--list-transforms', action='store_true', help='List available transforms and exit')
    ap.add_argument('--json', required=True, help='Path to en.json')
    ap.add_argument('--root', required=True, help='Root of codebase to scan')
    ap.add_argument('--dry-run', action='store_true', help='Do not write changes')
    args = ap.parse_args()

    if args.list_transforms:
        print_transform_list()
        return

    translations = load_translations(Path(args.json))
    root = Path(args.root)
    total_files_changed = 0
    total_replacements = 0
    unresolved_agg = {}

    for f in iter_source_files(root):
        replaced, unresolved = process_file(f, translations, dry_run=args.dry_run)
        if replaced:
            total_files_changed += 1
            total_replacements += replaced
        # aggregate unresolved
        for k, c in unresolved.items():
            unresolved_agg[k] = unresolved_agg.get(k, 0) + c

    print(f"[i18n] DONE — files changed: {total_files_changed}, total replacements: {total_replacements}")

    if unresolved_agg:
        print("[i18n] unresolved keys:")
        # show top offenders first
        for k, c in sorted(unresolved_agg.items(), key=lambda kv: (-kv[1], kv[0])):
            print(f"  {k}: {c} occurrence(s)")

if __name__ == "__main__":
    sys.exit(main())
