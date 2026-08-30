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

@test "templates lists \$ORBX_TEMPLATE_DIR entries and labels the source env" {
  orbx_source
  mkdir -p "$ORBX_TMP/tpl"
  touch "$ORBX_TMP/tpl/boxed.yaml"
  export ORBX_TEMPLATE_DIR="$ORBX_TMP/tpl"
  cd "$PROJECT_DIR"
  run orbx_run templates
  [ "$status" -eq 0 ]
  [[ "$output" =~ boxed[[:space:]]+env ]]
}

@test "templates: \$ORBX_TEMPLATE_DIR shadows a same-named user template" {
  orbx_source
  mkdir -p "$ORBX_TMP/tpl" "$HOME/.orbx/templates"
  touch "$ORBX_TMP/tpl/default.yaml" "$HOME/.orbx/templates/default.yaml"
  export ORBX_TEMPLATE_DIR="$ORBX_TMP/tpl"
  cd "$PROJECT_DIR"
  run orbx_run templates
  [ "$status" -eq 0 ]
  [[ "$output" =~ default[[:space:]]+env ]]
  [[ ! "$output" =~ default[[:space:]]+user ]]
}

@test "templates lists a project-local path template as active" {
  orbx_source
  mkdir -p "$PROJECT_DIR/.orbx"
  touch "$PROJECT_DIR/.orbx/rails.yaml"
  printf '%s\n' 'template = .orbx/rails.yaml' > "$PROJECT_DIR/.orbxrc"
  cd "$PROJECT_DIR"
  run orbx_run templates
  [ "$status" -eq 0 ]
  [[ "$output" =~ \.orbx/rails\.yaml[[:space:]]+project[[:space:]]+\(active\) ]]
  [[ "$output" == *"default"* ]]                                   # search path still listed
  [[ ! "$output" =~ default[[:space:]]+built-in[[:space:]]+\(active\) ]]
}

@test "templates flags a project template whose file is missing" {
  orbx_source
  printf '%s\n' 'template = .orbx/gone.yaml' > "$PROJECT_DIR/.orbxrc"
  cd "$PROJECT_DIR"
  run orbx_run templates
  [ "$status" -eq 0 ]
  [[ "$output" =~ \.orbx/gone\.yaml[[:space:]]+project[[:space:]]+\(active,\ missing\) ]]
}

@test "templates still marks a bare-name active template" {
  orbx_source
  mkdir -p "$HOME/.orbx/templates"
  touch "$HOME/.orbx/templates/python.yaml"
  printf '%s\n' 'template = python' > "$PROJECT_DIR/.orbxrc"
  cd "$PROJECT_DIR"
  run orbx_run templates
  [ "$status" -eq 0 ]
  [[ "$output" =~ python[[:space:]]+user[[:space:]]+\(active\) ]]
}
