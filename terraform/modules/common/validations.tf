check "required_tags_present" {
  assert {
    condition     = length(setsubtract(toset(var.required_tag_keys), toset(keys(local.tags)))) == 0
    error_message = "One or more required_tag_keys are missing from generated tags."
  }
}
