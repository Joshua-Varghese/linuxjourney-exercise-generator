#!/bin/bash
#
# chmod_lab.sh — Hands-on practice lab for "Modifying Permissions" (chmod)
#
# Covers:
#   - Reading permission strings (ls -l)
#   - Symbolic mode: u/g/o/a with +/-/=
#   - Numeric (octal) mode: 4/2/1 sums, e.g. 755, 644, 600
#   - Combining multiple changes in one command
#   - Recursive chmod (-R) on directories
#   - Making a script executable
#
# Usage:
#   ./chmod_lab.sh setup     # create the practice sandbox + exercises
#   ./chmod_lab.sh check     # check your progress against each exercise
#   ./chmod_lab.sh reset     # wipe and recreate the sandbox (start over)
#   ./chmod_lab.sh hint N    # show a hint for exercise N (1-8)
#
set -uo pipefail

LAB_DIR="$HOME/chmod_lab"

# ---------- colors ----------
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# ---------- setup ----------
setup_lab() {
    echo -e "${BLUE}Setting up chmod practice lab in ${LAB_DIR}...${NC}"
    mkdir -p "$LAB_DIR"
    cd "$LAB_DIR" || exit 1

    # Exercise 1: myfile — add execute for user (symbolic +)
    echo "This is myfile." > myfile
    chmod 644 myfile

    # Exercise 2: shared_notes.txt — remove write for group (symbolic -)
    echo "Shared notes." > shared_notes.txt
    chmod 664 shared_notes.txt

    # Exercise 3: config.conf — set exact permissions with = (rw for user, r for group/others)
    echo "setting=value" > config.conf
    chmod 777 config.conf

    # Exercise 4: deploy.sh — make executable (numeric mode, 755)
    cat > deploy.sh << 'EOF'
#!/bin/bash
echo "Deploying..."
EOF
    chmod 644 deploy.sh

    # Exercise 5: secret.key — private, owner-only (600)
    echo "SUPER-SECRET-KEY-DATA" > secret.key
    chmod 644 secret.key

    # Exercise 6: public_page.html — world-readable, owner-writable (644)
    echo "<h1>Public page</h1>" > public_page.html
    chmod 600 public_page.html

    # Exercise 7: combo.txt — add execute for user AND remove write for others (one command, two changes)
    echo "combo target" > combo.txt
    chmod 646 combo.txt

    # Exercise 8: project_dir/ — recursive chmod 755 on a directory tree
    mkdir -p project_dir/subdir
    echo "a" > project_dir/file_a.txt
    echo "b" > project_dir/subdir/file_b.txt
    chmod -R 777 project_dir

    echo -e "${GREEN}Lab created.${NC}"
    echo ""
    print_instructions
}

print_instructions() {
cat << 'EOF'
=====================================================================
  CHMOD PRACTICE LAB — 8 exercises
  Location: ~/chmod_lab
=====================================================================

Run:  cd ~/chmod_lab   then try each exercise below.
Check your work anytime with:  ./chmod_lab.sh check
Stuck? Run:  ./chmod_lab.sh hint <number>

---------------------------------------------------------------------
1) myfile            — currently rw-r--r--
   Goal: add EXECUTE permission for the user (owner) only.
   Target: rwxr--r--   (symbolic mode, use +)

2) shared_notes.txt   — currently rw-rw-r--
   Goal: remove WRITE permission for the group.
   Target: rw-r--r--   (symbolic mode, use -)

3) config.conf        — currently rwxrwxrwx
   Goal: set it EXACTLY to rw-r--r-- (owner read/write, everyone else read-only).
   Target: rw-r--r--   (symbolic mode, use =)

4) deploy.sh          — currently rw-r--r--
   Goal: make it a runnable script: owner full access, group/others read+execute.
   Target: rwxr-xr-x  → numeric mode: 755

5) secret.key         — currently rw-r--r--
   Goal: lock it down — only the owner can read/write, nobody else has any access.
   Target: rw-------  → numeric mode: 600

6) public_page.html   — currently rw-------
   Goal: make it a normal public file — owner read/write, everyone else read-only.
   Target: rw-r--r--  → numeric mode: 644

7) combo.txt          — currently rw-r--rw-
   Goal (ONE command): add execute for the user AND remove write for others.
   Target: rwxr--r--  (hint: chmod u+x,o-w combo.txt)

8) project_dir/       — a directory with a file and a subdirectory, all currently 777
   Goal: recursively set the whole tree to 755 (owner full, group/others read+execute).
   Use the -R flag: chmod -R 755 project_dir

---------------------------------------------------------------------
Reminders:
  Numeric values:  read=4  write=2  execute=1  (sum them per who: owner/group/other)
  Symbolic who:     u=user  g=group  o=others  a=all
  Symbolic ops:     +  add     -  remove     =  set exactly
  Check current permissions any time with:  ls -l
=====================================================================
EOF
}

# ---------- hints ----------
show_hint() {
    local n="$1"
    case "$n" in
        1) echo -e "${YELLOW}Hint:${NC} chmod u+x myfile" ;;
        2) echo -e "${YELLOW}Hint:${NC} chmod g-w shared_notes.txt" ;;
        3) echo -e "${YELLOW}Hint:${NC} chmod u=rw,g=r,o=r config.conf   (or chmod a=r,u+w config.conf)" ;;
        4) echo -e "${YELLOW}Hint:${NC} chmod 755 deploy.sh" ;;
        5) echo -e "${YELLOW}Hint:${NC} chmod 600 secret.key" ;;
        6) echo -e "${YELLOW}Hint:${NC} chmod 644 public_page.html" ;;
        7) echo -e "${YELLOW}Hint:${NC} chmod u+x,o-w combo.txt   (comma-separated = one command, two changes)" ;;
        8) echo -e "${YELLOW}Hint:${NC} chmod -R 755 project_dir" ;;
        *) echo "No hint available for exercise '$n'. Use a number 1-8." ;;
    esac
}

# ---------- checker ----------
# perm_octal PATH -> prints 3-digit octal e.g. 644
perm_octal() {
    stat -c "%a" "$1" 2>/dev/null | tail -c 4
}

check_one() {
    local desc="$1" path="$2" expected="$3"
    if [ ! -e "$path" ]; then
        echo -e "  ${RED}✗${NC} $desc — file not found (did you run setup?)"
        return
    fi
    local actual
    actual=$(perm_octal "$path")
    if [ "$actual" == "$expected" ]; then
        echo -e "  ${GREEN}✓${NC} $desc — correct ($actual)"
    else
        echo -e "  ${RED}✗${NC} $desc — expected $expected, got $actual"
    fi
}

check_lab() {
    if [ ! -d "$LAB_DIR" ]; then
        echo -e "${RED}Lab not found. Run './chmod_lab.sh setup' first.${NC}"
        exit 1
    fi
    cd "$LAB_DIR" || exit 1
    echo -e "${BLUE}Checking your exercises...${NC}\n"

    check_one "1) myfile add u+x           " "myfile"            "744"
    check_one "2) shared_notes.txt g-w     " "shared_notes.txt"  "644"
    check_one "3) config.conf u=rw,g=r,o=r " "config.conf"       "644"
    check_one "4) deploy.sh -> 755         " "deploy.sh"         "755"
    check_one "5) secret.key -> 600        " "secret.key"        "600"
    check_one "6) public_page.html -> 644  " "public_page.html"  "644"
    check_one "7) combo.txt u+x,o-w        " "combo.txt"         "744"

    # Exercise 8: recursive check across the whole tree
    local ok=1
    for f in project_dir project_dir/file_a.txt project_dir/subdir project_dir/subdir/file_b.txt; do
        [ "$(perm_octal "$f")" != "755" ] && ok=0
    done
    if [ "$ok" -eq 1 ]; then
        echo -e "  ${GREEN}✓${NC} 8) project_dir recursive 755 — correct"
    else
        echo -e "  ${RED}✗${NC} 8) project_dir recursive 755 — not all files/dirs are 755 yet"
    fi

    echo ""
    echo -e "${BLUE}Tip:${NC} run 'ls -l' (or 'ls -lR project_dir') to see current permissions."
}

reset_lab() {
    echo -e "${YELLOW}Removing existing lab at ${LAB_DIR}...${NC}"
    rm -rf "$LAB_DIR"
    setup_lab
}

# ---------- main ----------
case "${1:-}" in
    setup)
        setup_lab
        ;;
    check)
        check_lab
        ;;
    reset)
        reset_lab
        ;;
    hint)
        show_hint "${2:-}"
        ;;
    instructions|help|"")
        if [ -d "$LAB_DIR" ]; then
            print_instructions
        else
            echo "Run './chmod_lab.sh setup' first to create the lab, then './chmod_lab.sh help' to see the exercises again."
        fi
        ;;
    *)
        echo "Usage: $0 {setup|check|reset|hint <N>|help}"
        exit 1
        ;;
esac
