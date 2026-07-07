load helpers/test_helper

@test "sanitize lowercases and dashes non-alnum" {
  orbx_source
  [ "$(orbx::sanitize_name 'My App!')" = "my-app" ]
}

@test "sanitize collapses repeats and trims dashes" {
  orbx_source
  [ "$(orbx::sanitize_name '__Foo  Bar__')" = "foo-bar" ]
}

@test "derive_name uses the basename of PWD" {
  orbx_source
  cd "$PROJECT_DIR"
  [ "$(orbx::derive_name)" = "korelo" ]
}

@test "derive_name errors on an unusable directory" {
  orbx_source
  cd /
  run orbx::derive_name
  [ "$status" -ne 0 ]
}
