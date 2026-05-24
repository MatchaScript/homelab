.PHONY: tools vendor generate clean check fmt update

JSONNETFMT_ARGS := -n 2 --max-blank-lines 2 --string-style s --comment-style s

tools:
	@command -v jb >/dev/null || { echo >&2 "missing: jb -- install with: go install github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb@latest"; exit 1; }
	@command -v jsonnet >/dev/null || { echo >&2 "missing: jsonnet -- install with: go install github.com/google/go-jsonnet/cmd/jsonnet@latest"; exit 1; }
	@command -v jsonnetfmt >/dev/null || { echo >&2 "missing: jsonnetfmt -- install with: go install github.com/google/go-jsonnet/cmd/jsonnetfmt@latest"; exit 1; }
	@command -v promtool >/dev/null || { echo >&2 "missing: promtool -- https://prometheus.io/download/"; exit 1; }

vendor: tools
	@test -d vendor || jb install

generate: vendor
	@./scripts/generate.sh

clean:
	@rm -rf vendor/ tmp/ base/dashboards/*.json base/prometheusrules/*.yaml

check: generate
	@git diff --exit-code -- base/

fmt: tools
	@find lib -name '*.libsonnet' -o -name '*.jsonnet' | xargs -n 1 jsonnetfmt $(JSONNETFMT_ARGS) -i

update: tools
	@jb update
