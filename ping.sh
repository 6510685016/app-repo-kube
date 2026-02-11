#!/bin/bash
 
# HA Test Script - Support concurrent users
 
URL="${1:-}"
USERS="${2:-1}"
REQUESTS="${3:-10}"
 
if [ -z "$URL" ]; then
    echo "Usage: $0 <URL> [concurrent_users] [requests_per_user]"
    exit 1
fi
 
echo "============================================"
echo "URL:              $URL"
echo "Concurrent Users: $USERS"
echo "Requests/User:    $REQUESTS"
echo "Total Requests:   $((USERS * REQUESTS))"
echo "============================================"
echo ""
 
# Temp file for results
RESULT_FILE=$(mktemp)
 
# Function for each user
do_requests() {
    user_id=$1
    for i in $(seq 1 $REQUESTS); do
        status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$URL")
        echo "$status" >> "$RESULT_FILE"
        if [ "$status" = "200" ]; then
            echo "[User $user_id] Request $i: OK"
        else
            echo "[User $user_id] Request $i: FAIL ($status)"
        fi
    done
}
 
echo "Starting..."
echo ""
 
# Start all users in parallel
for u in $(seq 1 $USERS); do
    do_requests $u &
done
 
# Wait for all to finish
wait
 
echo ""
echo "============================================"
echo "Results:"
echo "============================================"
 
total=$(wc -l < "$RESULT_FILE")
success=$(grep -c "200" "$RESULT_FILE" 2>/dev/null || echo 0)
fail=$((total - success))
 
echo "Total:   $total"
echo "Success: $success"
echo "Failed:  $fail"
 
if [ "$total" -gt 0 ]; then
    rate=$((success * 100 / total))
    echo "Rate:    ${rate}%"
fi
 
rm -f "$RESULT_FILE"