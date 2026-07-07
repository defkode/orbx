load helpers/test_helper

@test "up --dry-run prints the full orb create line and runs nothing" {
  orbx_source
  mkdir -p "$HOME/.orbx/templates"
  touch "$HOME/.orbx/templates/default.yaml"
  export USER=tomasz
  cd "$PROJECT_DIR"
  run orbx_run up --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"orb create -c $HOME/.orbx/templates/default.yaml --isolated"* ]]
  [[ "$output" == *"--mount $PROJECT_DIR:/home/tomasz/code/korelo"* ]]
  [[ "$output" == *"ubuntu:26.04 korelo"* ]]
  # dry-run must not have invoked orb
  [ ! -s "$ORB_STUB_LOG" ]
}

@test "up --dry-run honors --arch, --name, --no-mount, --template" {
  orbx_source
  mkdir -p "$HOME/.orbx/templates"
  touch "$HOME/.orbx/templates/base.yaml"
  cd "$PROJECT_DIR"
  run orbx_run up --dry-run --arch amd64 --name custom --no-mount --template base
  [ "$status" -eq 0 ]
  [[ "$output" == *"--arch amd64"* ]]
  [[ "$output" == *"base.yaml"* ]]
  [[ "$output" == *"ubuntu:26.04 custom"* ]]
  [[ "$output" != *"--mount"* ]]
}

@test "up --dry-run adds an explicit --mount alongside the auto \$PWD mount" {
  orbx_source
  mkdir -p "$HOME/.orbx/templates"
  touch "$HOME/.orbx/templates/default.yaml"
  export USER=tomasz
  cd "$PROJECT_DIR"
  run orbx_run up --dry-run --mount /host/data:/vm/data
  [ "$status" -eq 0 ]
  [[ "$output" == *"--mount $PROJECT_DIR:/home/tomasz/code/korelo"* ]]
  [[ "$output" == *"--mount /host/data:/vm/data"* ]]
}
