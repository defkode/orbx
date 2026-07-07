load helpers/test_helper

@test "parse ignores blanks/comments and trims whitespace" {
  orbx_source
  local f="$ORBX_TMP/cfg"
  printf '%s\n' '# a comment' '' '  template =  default  ' 'arch=amd64' > "$f"
  run orbx::parse_config_file "$f"
  [ "$status" -eq 0 ]
  [[ "$output" == *"template=default"* ]]
  [[ "$output" == *"arch=amd64"* ]]
  [[ "$output" != *"comment"* ]]
}

@test "parse strips trailing inline comments" {
  orbx_source
  local f="$ORBX_TMP/cfg"
  printf '%s\n' 'image = ubuntu:26.04   # base image' > "$f"
  run orbx::parse_config_file "$f"
  [[ "$output" == "image=ubuntu:26.04" ]]
}

@test "parse of a missing file is empty and succeeds" {
  orbx_source
  run orbx::parse_config_file "$ORBX_TMP/nope"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "effective config: defaults when no files exist" {
  orbx_source
  cd "$PROJECT_DIR"
  run orbx::effective_config
  [[ "$output" == *"template=default"* ]]
  [[ "$output" == *"image=ubuntu:26.04"* ]]
  [[ "$output" == *"mount=true"* ]]
}

@test "effective config: project overrides global overrides default" {
  orbx_source
  mkdir -p "$HOME/.orbx"
  printf '%s\n' 'template=globaltpl' 'image=ubuntu:24.04' > "$HOME/.orbx/config"
  cd "$PROJECT_DIR"
  printf '%s\n' 'template=projtpl' > "$PROJECT_DIR/.orbxrc"
  run orbx::effective_config
  [[ "$output" == *"template=projtpl"* ]]     # project wins
  [[ "$output" == *"image=ubuntu:24.04"* ]]   # global wins over default
}

@test "effective config: unknown keys are preserved" {
  orbx_source
  mkdir -p "$HOME/.orbx"
  printf '%s\n' 'future_key=xyz' > "$HOME/.orbx/config"
  cd "$PROJECT_DIR"
  run orbx::effective_config
  [[ "$output" == *"future_key=xyz"* ]]
}
