#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail


if [[ "$#" != 1 ]]; then
  echo "Usage: $0 <ROLLOUTS_DEMO_BASE_URL>"
  exit 1
fi

ROLLOUTS_DEMO_URL="$1"

# Create temp dir for test output
TEST_DIR="$(mktemp -d /tmp/rollouts-demo-integration-test.XXXXXX)"
trap 'rm -rf "${TEST_DIR}"' EXIT

# Helper function for making requests
req() {
  curl \
    --silent \
    --show-error \
    --fail \
    "$@"
}

test_landing_page() {
  echo -n "Test landing page... "
  TEST_FILE="${TEST_DIR}/landing-page.html"

  if ! req "${ROLLOUTS_DEMO_URL}" \
    | tee "${TEST_FILE}" \
    | grep --fixed-strings --line-regexp '<!DOCTYPE html>' \
    > /dev/null
  then
    echo "FAIL: Did not find html doctype declaration in landing page"
    echo "--> Full response:"
    cat "${TEST_FILE}"
    echo "<-- End response."
    echo
    return 1
  fi

  echo "PASS"
  return 0
}

test_color_api() {
  echo -n "Test color API... "

  RESP="$(req "${ROLLOUTS_DEMO_URL}/color")"

  case "${RESP}" in
    '"red"'|'"orange"'|'"yellow"'|'"green"'|'"blue"'|'"purple"')
      ;;
    *)
      echo "FAIL: Unexpected color response: ${RESP}"
      return 1
      ;;
  esac

  echo "PASS"
  return 0
}

echo "Running integration tests using URL: ${ROLLOUTS_DEMO_URL}"
test_landing_page
test_color_api
