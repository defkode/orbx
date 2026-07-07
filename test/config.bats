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
