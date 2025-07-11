#!/usr/bin/env bats

load helpers

# bats test_tags=distro-integration
@test "ramalama info" {
    #FIXME jq version on mac does not like regex handling
    skip_if_darwin
    run_ramalama 2 info bogus
    is "$output" ".*ramalama: error: unrecognized arguments: bogus"

    run_ramalama version
    version=$(cut -f3 -d " " <<<"$output")

    run_ramalama version
    is "$output" "ramalama version $version"

    run_ramalama -q version
    is "$output" "$version"

    run_ramalama info

    # FIXME Engine  (podman|docker|'')
    tests="
Image   | "quay.io/ramalama/.*"
Runtime | "llama.cpp"
Version | "${version}"
Store   | \\\("${HOME}/.local/share/ramalama"\\\|"/var/lib/ramalama"\\\)
"

    defer-assertion-failures

    while read field expect; do
	actual=$(echo "$output" | jq -r ".$field")
	dprint "# actual=<$actual> expect=<$expect>"
	is "$actual" "$expect" "jq .$field"
	    done < <(parse_table "$tests")

    image=i_$(safename):1.0
    runtime=vllm
    engine=e_$(safename)
    store=s_$(safename)

    RAMALAMA_IMAGE=$image run_ramalama --store $store --runtime $runtime --engine $engine info
    tests="
Engine.Name | $engine
Image   | $image
Runtime | $runtime
Store   | $(pwd)/$store
"

    defer-assertion-failures

    while read field expect; do
	actual=$(echo "$output" | jq -r ".$field")
	dprint "# actual=<$actual> expect=<$expect>"
	is "$actual" "$expect" "jq .$field"
    done < <(parse_table "$tests")

}

@test "ramalama info --store" {
      randdir=$(random_string 20)
      store=$(pwd)/${randdir}
      run_ramalama --store ./${randdir} info
      actual=$(echo "$output" | jq -r ".Store")
      is "$actual" "$store" "Verify relative paths translated to absolute path"
}

# vim: filetype=sh
