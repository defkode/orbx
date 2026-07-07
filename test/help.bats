load helpers/test_helper

@test "--help lists the commands" {
  orbx_source
  run orbx_run --help
  [ "$status" -eq 0 ]
  for word in up shell run status logs stop down list ip templates config init; do
    [[ "$output" == *"$word"* ]] || { echo "missing: $word"; false; }
  done
}

@test "missing orb is reported clearly" {
  orbx_source
  # Simulate orb being absent without disturbing PATH/bash resolution.
  ORBX_ORB_BIN=orb-not-installed run orbx_run up
  [ "$status" -ne 0 ]
  [[ "$output" == *"orb"* ]]
  [[ "$output" == *"orbstack.dev"* ]]
}

@test "template not found lists remedy" {
  orbx_source
  cd "$PROJECT_DIR"
  run orbx_run up --template nope --dry-run
  [ "$status" -ne 0 ]
  [[ "$output" == *"orbx templates"* ]]
}
