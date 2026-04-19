#!/bin/bash
# Vodacom Payment Integration - Quick Test Commands
# Save this as: test-vodacom.sh
# Make executable: chmod +x test-vodacom.sh
# Run: ./test-vodacom.sh

set -e

FUNCTION_URL="https://vodacompaymentcallback-45f4gu65ha-uc.a.run.app"
PROJECT_ID="chaja-kiganjani"

echo "════════════════════════════════════════════════════════════"
echo "  VODACOM PAYMENT INTEGRATION - QUICK TEST SUITE"
echo "════════════════════════════════════════════════════════════"
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print section headers
print_header() {
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}$1${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Function to run tests with result indicator
run_test() {
  local test_name=$1
  local command=$2
  
  echo -e "\n${YELLOW}Running: $test_name${NC}"
  if eval "$command"; then
    echo -e "${GREEN}✓ PASSED${NC}"
    return 0
  else
    echo -e "${RED}✗ FAILED${NC}"
    return 1
  fi
}

# ════════════════════════════════════════════════════════════
# TEST 1: Unit Tests
# ════════════════════════════════════════════════════════════
print_header "TEST 1: Dart Unit Tests"

run_test "Run Vodacom callback tests" \
  "flutter test test/vodacom_callback_test.dart"

# ════════════════════════════════════════════════════════════
# TEST 2: Cloud Function Health Check
# ════════════════════════════════════════════════════════════
print_header "TEST 2: Cloud Function Accessibility"

echo -e "\n${YELLOW}Checking Cloud Function endpoint...${NC}"
if curl -s -o /dev/null -w "%{http_code}" "$FUNCTION_URL" | grep -q "405"; then
  echo -e "${GREEN}✓ Function is accessible (405 = function exists, GET not allowed)${NC}"
else
  echo -e "${RED}✗ Function not accessible${NC}"
  exit 1
fi

# ════════════════════════════════════════════════════════════
# TEST 3: Test Callback - Success Case
# ════════════════════════════════════════════════════════════
print_header "TEST 3: Callback with INS-0 (Success)"

SUCCESS_PAYLOAD='{
  "output_ResponseCode": "INS-0",
  "output_ResponseDesc": "Request processed successfully",
  "output_TransactionID": "TEST_'$(date +%s)'_001",
  "output_ConversationID": "CONV_TEST_'$(date +%s)'_001",
  "output_ThirdPartyConversationID": "USER_TEST_'$(date +%s)'"
}'

echo -e "\n${YELLOW}Sending success callback...${NC}"
echo -e "Payload: $SUCCESS_PAYLOAD\n"

RESPONSE=$(curl -s -X POST "$FUNCTION_URL" \
  -H "Content-Type: application/json" \
  -d "$SUCCESS_PAYLOAD")

echo -e "Response: $RESPONSE"

if echo "$RESPONSE" | grep -q "success\|confirmed"; then
  echo -e "${GREEN}✓ Success callback handled correctly${NC}"
else
  echo -e "${RED}✗ Unexpected response${NC}"
fi

# ════════════════════════════════════════════════════════════
# TEST 4: Test Callback - Failure Case
# ════════════════════════════════════════════════════════════
print_header "TEST 4: Callback with INS-3 (User Cancelled)"

FAILURE_PAYLOAD='{
  "output_ResponseCode": "INS-3",
  "output_ResponseDesc": "Request cancelled by user",
  "output_TransactionID": "TEST_'$(date +%s)'_002",
  "output_ConversationID": "CONV_TEST_'$(date +%s)'_002",
  "output_ThirdPartyConversationID": "USER_TEST_'$(date +%s)'"
}'

echo -e "\n${YELLOW}Sending failure callback...${NC}"
echo -e "Payload: $FAILURE_PAYLOAD\n"

RESPONSE=$(curl -s -X POST "$FUNCTION_URL" \
  -H "Content-Type: application/json" \
  -d "$FAILURE_PAYLOAD")

echo -e "Response: $RESPONSE"

if echo "$RESPONSE" | grep -q "error\|failed"; then
  echo -e "${GREEN}✓ Failure callback handled correctly${NC}"
else
  echo -e "${YELLOW}⚠ Check response format${NC}"
fi

# ════════════════════════════════════════════════════════════
# TEST 5: Cloud Function Logs
# ════════════════════════════════════════════════════════════
print_header "TEST 5: View Cloud Function Logs"

echo -e "\n${YELLOW}Fetching latest logs (last 20 lines)...${NC}\n"
firebase functions:log --only vodacomPaymentCallback | tail -20

# ════════════════════════════════════════════════════════════
# TEST 6: Firestore Verification
# ════════════════════════════════════════════════════════════
print_header "TEST 6: Firestore Data Verification"

echo -e "\n${YELLOW}Verifying Firestore collections exist...${NC}"
echo -e "Check these collections in Firebase Console:"
echo -e "  • /transactions - Should have test transaction records"
echo -e "  • /users - Check balance field was updated\n"

echo -e "${YELLOW}To view data:${NC}"
echo -e "  1. Go to: https://console.firebase.google.com/project/$PROJECT_ID/firestore/data"
echo -e "  2. Look for recent transaction with status='confirmed'"
echo -e "  3. Verify user balance increased by payment amount\n"

# ════════════════════════════════════════════════════════════
# TEST 7: Performance Check
# ════════════════════════════════════════════════════════════
print_header "TEST 7: Cloud Function Performance"

echo -e "\n${YELLOW}Testing response time...${NC}"

PAYLOAD='{
  "output_ResponseCode": "INS-0",
  "output_ResponseDesc": "Performance test",
  "output_TransactionID": "PERF_'$(date +%s%N)'",
  "output_ConversationID": "CONV_PERF_'$(date +%s%N)'",
  "output_ThirdPartyConversationID": "PERF_'$(date +%s%N)'"
}'

TIME_TAKEN=$(curl -s -o /dev/null -w "%{time_total}" -X POST "$FUNCTION_URL" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

echo -e "Response time: ${TIME_TAKEN}s"

if (( $(echo "$TIME_TAKEN < 3" | bc -l) )); then
  echo -e "${GREEN}✓ Performance is good (< 3s)${NC}"
else
  echo -e "${YELLOW}⚠ Performance is slow (> 3s)${NC}"
fi

# ════════════════════════════════════════════════════════════
# TEST 8: Summary
# ════════════════════════════════════════════════════════════
print_header "TEST SUMMARY"

echo -e "\n${GREEN}Key Testing Commands:${NC}\n"

echo "1. Run Dart unit tests:"
echo -e "   ${BLUE}flutter test test/vodacom_callback_test.dart${NC}\n"

echo "2. View Cloud Function logs:"
echo -e "   ${BLUE}firebase functions:log${NC}\n"

echo "3. Manual callback test with curl:"
echo -e "   ${BLUE}curl -X POST $FUNCTION_URL \\${NC}"
echo -e "   ${BLUE}  -H 'Content-Type: application/json' \\${NC}"
echo -e "   ${BLUE}  -d '{\"output_ResponseCode\": \"INS-0\", ...}'${NC}\n"

echo "4. Monitor Firestore:"
echo -e "   ${BLUE}https://console.firebase.google.com/project/$PROJECT_ID/firestore${NC}\n"

echo "5. Check deployment status:"
echo -e "   ${BLUE}firebase deploy --only functions:vodacomPaymentCallback${NC}\n"

echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Testing complete! Check results above.${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
