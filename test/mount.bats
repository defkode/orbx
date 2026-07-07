load helpers/test_helper

@test "path under HOME is re-rooted under the machine user's home" {
  orbx_source
  export USER=tomasz
  run orbx::mount_target "$HOME/code/korelo"
  [ "$output" = "/home/tomasz/code/korelo" ]
}

@test "path outside HOME maps to the identical absolute path" {
  orbx_source
  run orbx::mount_target "/opt/data/thing"
  [ "$output" = "/opt/data/thing" ]
}

@test "default argument is PWD" {
  orbx_source
  export USER=tomasz
  cd "$PROJECT_DIR"
  run orbx::mount_target
  [ "$output" = "/home/tomasz/code/korelo" ]
}
