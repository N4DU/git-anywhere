#!/usr/bin/env bash
# open.sh — Temporary GitHub work session

set -eo pipefail

B='\033[1m'
C='\033[0;36m'
G='\033[0;32m'
D='\033[2m'
R='\033[0m'

OPEN_ABS="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"

echo
echo -e "${B}  ┌──────────────────────────────────────┐${R}"
echo -e "${B}  │  Temp session · GitHub               │${R}"
echo -e "${B}  └──────────────────────────────────────┘${R}"
echo
printf "  ${D}GitHub user:${R}  "; read -r GHUSER
printf "  ${D}Token:${R}        "; read -rs TOKEN; echo
printf "  ${D}Repository:${R}   "; read -r REPO

echo
echo -e "  ${D}── cloning ──────────────────────────────────────────${R}"
git clone "https://${TOKEN}@github.com/${GHUSER}/${REPO}.git" 2>&1 | sed 's/^/    /'
echo -e "  ${D}────────────────────────────────────────────────────${R}"

cd "$REPO"
git config --local credential.helper ""

echo
printf "  ${D}Name  (git):${R}  "; read -r GITNAME
printf "  ${D}Email (git):${R}  "; read -r EMAIL

git config --local user.name  "$GITNAME"
git config --local user.email "$EMAIL"

echo
printf "  Add 'open.sh' and 'close.sh' to .gitignore? ${D}[y/n]${R}  "
read -r ANS
if [[ "$ANS" =~ ^[yY]$ ]]; then
    for entry in "open.sh" "close.sh"; do
        if [ -f .gitignore ] && grep -qxF "$entry" .gitignore 2>/dev/null; then
            echo -e "  ${D}↳ '$entry' already listed${R}"
        else
            echo "$entry" >> .gitignore
            echo -e "  ${G}↳ '$entry' added${R}"
        fi
    done
fi

# ── Generate close.sh ──────────────────────────────────────────────────────
# ${GHUSER}, ${REPO}, ${OPEN_ABS} and ${PPID} are embedded now.
# ${PPID} here is the terminal bash PID — used to close it even after exec bash.
cat > close.sh << EOF
#!/usr/bin/env bash
# close.sh — Cleans up the session and closes the terminal

CLOSE_ABS="\$(cd -- "\$(dirname -- "\$0")" && pwd)/\$(basename -- "\$0")"
TERM_PID="${PPID}"

RED='\033[0;31m'
YEL='\033[1;33m'
GRN='\033[0;32m'
DIM='\033[2m'
B='\033[1m'
R='\033[0m'

echo
echo -e "\${RED}\${B}  ╔═════════════════════════════════════════════╗\${R}"
echo -e "\${RED}\${B}  ║  ⚠  WARNING                                ║\${R}"
echo -e "\${RED}\${B}  ║  Uncommitted / unpushed work               ║\${R}"
echo -e "\${RED}\${B}  ║  will be gone when you delete              ║\${R}"
echo -e "\${RED}\${B}  ║  the repo folder.                          ║\${R}"
echo -e "\${RED}\${B}  ╚═════════════════════════════════════════════╝\${R}"
echo
printf "  \${YEL}Confirm close? \${DIM}[y/n]\${R}  "; read -r CONF

if [[ ! "\$CONF" =~ ^[yY]\$ ]]; then
    echo -e "\n  Cancelled. Keep working.\n"
    exit 0
fi

echo
git remote set-url origin "https://github.com/${GHUSER}/${REPO}.git"
echo -e "  \${GRN}✓\${R}  remote URL — token removed"

git config --local --unset user.name         2>/dev/null || :
git config --local --unset user.email        2>/dev/null || :
git config --local --unset credential.helper 2>/dev/null || :
echo -e "  \${GRN}✓\${R}  git config — identity cleared"

truncate -s 0 "\${HISTFILE:-\$HOME/.bash_history}" 2>/dev/null || :
history -c 2>/dev/null || :
echo -e "  \${GRN}✓\${R}  history — wiped"

echo
echo -e "  Session closed. Delete the \${B}${REPO}/\${R} folder when done."
echo -e "  \${DIM}Closing terminal in 3 seconds...\${R}\n"
sleep 3

PARENT=\$PPID
rm -f -- "\$CLOSE_ABS"
kill -9 "\$PARENT"   2>/dev/null || :
kill -9 "\$TERM_PID" 2>/dev/null || :
EOF

chmod +x close.sh
echo "close.sh" >> .git/info/exclude

# ── Done ───────────────────────────────────────────────────────────────────
echo
echo -e "  ${D}────────────────────────────────────────────────────${R}"
echo -e "  ${G}${B}✓${R}  ${B}${REPO}${R}  ${D}·${R}  ${GITNAME} ${D}<${EMAIL}>${R}"
echo -e "  ${D}git commit · git push · git pull — all set.${R}"
echo -e "  Close session:  ${B}./close.sh${R}"
echo -e "  ${D}────────────────────────────────────────────────────${R}"
echo

rm -f -- "$OPEN_ABS"
exec bash