#!/usr/bin/env bats

load helpers

verify_begin="podman run --rm -it --label \"RAMALAMA container\" --security-opt=label=disable -e RAMALAMA_TRANSPORT --name"

@test "ramalama --dryrun serve basic output" {
    model=m_$(safename)

    run_ramalama --dryrun serve ${model}
    is "$output" "${verify_begin} ramalama_.*" "dryrun correct"
    is "$output" ".*${model}" "verify model name"

    run_ramalama --dryrun serve --name foobar ${model}
    is "$output" "${verify_begin} foobar .*" "dryrun correct with --name"
    is "$output" ".*${model}" "verify model name"

    run_ramalama --dryrun serve --name foobar MODEL
    is "$output" "${verify_begin} foobar .*" "dryrun correct with --name"

    run_ramalama 22 --nocontainer serve --name foobar MODEL
    is "${lines[0]}"  "Error: --nocontainer and --name options conflict. --name requires a container." "conflict between nocontainer and --name line"
}

@test "ramalama --detach serve" {
    model=m_$(safename)

    run_ramalama --dryrun serve --detach ${model}
    is "$output" "${verify_begin} ramalama_.*" "serve in detach mode"

    run_ramalama --dryrun serve -d ${model}
    is "$output" "${verify_begin} ramalama_.*" "dryrun correct"
}

@test "ramalama serve and stop" {
    model=ollama://tiny-llm:latest
    container1=c_$(safename)
    container2=c_$(safename)

    run_ramalama serve --name ${container1} --detach ${model}
    cid="$output"

    run_ramalama ps
    is "$output" ".*${container1}" "list correct"

    run_ramalama containers --noheading
    is "$output" ".*${container1}" "list correct"
    run_ramalama stop ${container1}

    run_ramalama serve --name ${container2} -d ${model}
    cid="$output"
    run_ramalama containers -n
    is "$output" ".*${cid:0:10}" "list correct with cid"
    run_ramalama ps --noheading
    is "$output" ".*${container2}" "list correct with cid and no heading"
    run_ramalama stop ${cid}
}

@test "ramalama --detach serve and stop all" {
    model=ollama://tiny-llm:latest
    container=c_$(safename)

    run_ramalama stop --all

    run_ramalama serve --detach ${model}
    cid="$output"

    run_ramalama serve -p 8081 --detach ${model}
    cid="$output"

    run_ramalama containers --noheading
    is ${#lines[@]} 2 "two containers should be running"

    run_ramalama stop --all
    run_ramalama containers -n
    is "$output" "" "no more containers should exist"
}

@test "ramalama stop failures" {
    name=m_$(safename)
    run_ramalama 22 stop
    is "$output" "Error: must specify a container name" "name required"

    run_ramalama 125 stop ${name}
    is "$output" "Error: no container with name or ID \"${name}\" found: no such container.*" "missing container"

    run_ramalama stop --ignore ${name}
    is "$output" "" "ignore missing"

    run_ramalama 22 stop --all ${name}
    is "$output" "Error: specifying --all and container name, ${name}, not allowed" "list correct"
}

@test "ramalama serve --generate=quadlet" {
    model=tiny
    name=c_$(safename)

    run_ramalama serve --name=${name} --port 1234 --generate=quadlet ${model}
    is "$output" ".*PublishPort=1234" "PublishPort should match"
    is "$output" ".*Name=${name}" "Quadlet should have name field"
    is "$output" ".*Exec=llama-server --port 1234 -m .*" "Exec line should be correct"
}

# vim: filetype=sh
