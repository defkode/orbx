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
