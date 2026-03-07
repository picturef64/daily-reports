#!/bin/bash 

# --- STOP PASSWORD PROMPTS ---
# This tells Gemini and the system to use files instead of the locked Keyring
export GEMINI_FORCE_FILE_STORAGE=true
export GEMINI_FORCE_ENCRYPTED_FILE_STORAGE=false
export GCR_METADATA_TIMEOUT=0
export GNOME_KEYRING_CONTROL=1

# Move to the project folder
cd ~/stockMonitor

# 1. Define filenames with today's Date AND Time
DATE=$(date +%F)
TIME=$(date +%H-%M)
TIMESTAMP="${DATE}_${TIME}"
REPORT_MD="morning_report_$TIMESTAMP.md"
REPORT_PDF="/home/neoone/Documents/Morning_Market_Report_$TIMESTAMP.pdf"
REPO_PATH="/home/neoone/stockMonitor"

# 2. Run Gemini Agent
# Added the full prompt so it correctly finds patterns and lists them
gemini --yolo -p "Search Google for today's top 10 stock market losers. Include the exact time of analysis ($TIME) in the header. Analyze 1-month charts for 'U-shaped' or 'Cup and Handle' patterns. List the Ticker, % drop, and status. Write it into $REPORT_MD"

# # 3. Convert to PDF (Added 'mainfont' to handle currency symbols)
pandoc "$REPORT_MD" -o "$REPORT_PDF" --pdf-engine=xelatex -V mainfont="DejaVu Serif"

# 4. Get the best pick for the notification (Quote-Safe Version)
PICK=$(grep -i "Cup and Handle" "$REPORT_MD" | head -n 1 | cut -d'|' -f2)

# 5. Send Notification
if [ -z "$PICK" ]; then
    notify-send -u critical -i office-chart "Stock Agent" "Report generated at $TIME"
else
    notify-send -u critical -i office-chart "Stock Agent" "New Pattern at $TIME: $PICK"
fi

# --- 6. SYNC TO GITHUB ---
# This part ensures your files actually travel to the cloud
git add .
git commit -m "Auto-Report $TIMESTAMP"
git push origin main
