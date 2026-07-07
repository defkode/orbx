load helpers/test_helper

@test "templates lists user and bundled templates, marking the default" {
  orbx_source
  mkdir -p "$HOME/.orbx/templates"
  touch "$HOME/.orbx/templates/python.yaml"
  cd "$PROJECT_DIR"
  run orbx_run templates
  [ "$status" -eq 0 ]
  [[ "$output" == *"python"* ]]
  [[ "$output" == *"default"* ]]
}

@test "config prints the effective config" {
  orbx_source
  cd "$PROJECT_DIR"
  run orbx_run config
  [ "$status" -eq 0 ]
  [[ "$output" == *"template=default"* ]]
}

@test "init scaffolds ./.orbxrc and refuses to clobber" {
  orbx_source
  cd "$PROJECT_DIR"
  run orbx_run init
  [ "$status" -eq 0 ]
  [ -f "$PROJECT_DIR/.orbxrc" ]
  run orbx_run init
  [ "$status" -ne 0 ]           # exists; refuse without --force
  run orbx_run init --force
  [ "$status" -eq 0 ]
}
