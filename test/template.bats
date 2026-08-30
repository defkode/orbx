load helpers/test_helper

@test "resolves a user template from ~/.orbx/templates" {
  orbx_source
  mkdir -p "$HOME/.orbx/templates"
  touch "$HOME/.orbx/templates/default.yaml"
  run orbx::resolve_template default
  [ "$status" -eq 0 ]
  [ "$output" = "$HOME/.orbx/templates/default.yaml" ]
}

@test "falls back to the bundled/dev templates dir" {
  orbx_source   # ORBX_BUNDLED_TEMPLATE_DIR is unstamped, so dev fallback applies
  run orbx::resolve_template default
  [ "$status" -eq 0 ]
  [[ "$output" == *"/templates/default.yaml" ]]
}

@test "user template shadows the bundled one" {
  orbx_source
  mkdir -p "$HOME/.orbx/templates"
  touch "$HOME/.orbx/templates/default.yaml"
  run orbx::resolve_template default
  [ "$output" = "$HOME/.orbx/templates/default.yaml" ]
}

@test "unknown template errors" {
  orbx_source
  run orbx::resolve_template does-not-exist
  [ "$status" -ne 0 ]
}

@test "ORBX_TEMPLATE_DIR is searched before the user dir" {
  orbx_source
  mkdir -p "$ORBX_TMP/tpl" "$HOME/.orbx/templates"
  touch "$ORBX_TMP/tpl/default.yaml" "$HOME/.orbx/templates/default.yaml"
  export ORBX_TEMPLATE_DIR="$ORBX_TMP/tpl"
  run orbx::resolve_template default
  [ "$output" = "$ORBX_TMP/tpl/default.yaml" ]
}

@test "resolves a template path relative to \$PWD" {
  orbx_source
  mkdir -p "$PROJECT_DIR/.orbx"
  touch "$PROJECT_DIR/.orbx/rails.yaml"
  cd "$PROJECT_DIR"
  run orbx::resolve_template .orbx/rails.yaml
  [ "$status" -eq 0 ]
  [ "$output" = "$PROJECT_DIR/.orbx/rails.yaml" ]
}

@test "resolves a ./-prefixed template path" {
  orbx_source
  mkdir -p "$PROJECT_DIR/tpl"
  touch "$PROJECT_DIR/tpl/custom.yaml"
  cd "$PROJECT_DIR"
  run orbx::resolve_template ./tpl/custom.yaml
  [ "$status" -eq 0 ]
  [ "$output" = "$PROJECT_DIR/tpl/custom.yaml" ]
}

@test "resolves an absolute template path" {
  orbx_source
  touch "$ORBX_TMP/abs.yaml"
  cd "$PROJECT_DIR"
  run orbx::resolve_template "$ORBX_TMP/abs.yaml"
  [ "$status" -eq 0 ]
  [ "$output" = "$ORBX_TMP/abs.yaml" ]
}

@test "expands a ~/-prefixed template path" {
  orbx_source
  mkdir -p "$HOME/mine"
  touch "$HOME/mine/tpl.yaml"
  cd "$PROJECT_DIR"
  run orbx::resolve_template '~/mine/tpl.yaml'
  [ "$status" -eq 0 ]
  [ "$output" = "$HOME/mine/tpl.yaml" ]
}

@test "a .yml extension is treated as a path too" {
  orbx_source
  touch "$PROJECT_DIR/box.yml"
  cd "$PROJECT_DIR"
  run orbx::resolve_template box.yml
  [ "$status" -eq 0 ]
  [ "$output" = "$PROJECT_DIR/box.yml" ]
}

@test "a missing template path errors and names the path" {
  orbx_source
  cd "$PROJECT_DIR"
  run orbx::resolve_template .orbx/gone.yaml
  [ "$status" -ne 0 ]
  [[ "$output" == *"$PROJECT_DIR/.orbx/gone.yaml"* ]]
}

@test "a bare name with a slash still searches the template dirs" {
  orbx_source
  mkdir -p "$HOME/.orbx/templates/sub"
  touch "$HOME/.orbx/templates/sub/nested.yaml"
  cd "$PROJECT_DIR"
  run orbx::resolve_template sub/nested
  [ "$status" -eq 0 ]
  [ "$output" = "$HOME/.orbx/templates/sub/nested.yaml" ]
}

@test "a committed .orbxrc template path drives orb create" {
  orbx_source
  mkdir -p "$PROJECT_DIR/.orbx"
  touch "$PROJECT_DIR/.orbx/rails.yaml"
  printf '%s\n' 'template = .orbx/rails.yaml' > "$PROJECT_DIR/.orbxrc"
  cd "$PROJECT_DIR"
  run orbx_run up --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"orb create -c $PROJECT_DIR/.orbx/rails.yaml --isolated"* ]]
}
