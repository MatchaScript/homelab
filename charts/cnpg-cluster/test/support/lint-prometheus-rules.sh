#!/usr/bin/env bash
# Render the chart with monitoring enabled and validate every PromQL expr in
# the generated PrometheusRule via `promtool check rules`. Mirrors the
# prometheus-operator validating webhook locally so PromQL regressions are
# caught at lint time before the chart can ship.
set -euo pipefail

CHART_DIR="${CHART_DIR:?CHART_DIR must be set}"
TEST_DIR="${TEST_DIR:?TEST_DIR must be set}"

VALUES_FILE="${TEST_DIR}/support/lint-monitoring-values.yaml"

for tool in helm yq promtool; do
  command -v "$tool" >/dev/null \
    || { echo "lint-prom: '$tool' not found in PATH" >&2; exit 2; }
done

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

helm template lint-prom "$CHART_DIR" --values "$VALUES_FILE" \
  > "$WORK/rendered.yaml"

yq ea 'select(.kind == "PrometheusRule") | .spec' "$WORK/rendered.yaml" \
  > "$WORK/rules.yaml"

if [ ! -s "$WORK/rules.yaml" ]; then
  echo "lint-prom: no PrometheusRule rendered — check monitoring is enabled in lint values" >&2
  exit 1
fi

promtool check rules "$WORK/rules.yaml"
