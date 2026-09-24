mock_provider "aws" {}

run "cert_without_validation_stays_unvalidated" {
  command = apply

  variables {
    domain_name = "example.com"
  }

  assert {
    condition     = output.validated_arn == null
    error_message = "validated_arn should stay null when validation_record_fqdns is unset."
  }
}

run "cert_with_validation_record_fqdns_gets_validated" {
  command = apply

  variables {
    domain_name             = "example.com"
    validation_record_fqdns = ["_abc123.example.com."]
  }

  assert {
    condition     = length(aws_acm_certificate_validation.resource) == 1
    error_message = "Supplying validation_record_fqdns should create exactly one validation resource."
  }

  assert {
    condition     = output.validated_arn != null
    error_message = "validated_arn should resolve once validation_record_fqdns is supplied and validation completes."
  }
}

run "domain_validation_options_output_is_populated" {
  command = apply

  variables {
    domain_name = "example.com"
  }

  assert {
    condition     = output.domain_validation_options != null
    error_message = "domain_validation_options should be populated so a caller can build DNS validation records from it."
  }
}

run "readme_default_minimal" {
  command = plan

  variables {
    domain_name = "example.com"
  }

  assert {
    condition     = aws_acm_certificate.resource.domain_name == "example.com"
    error_message = "domain_name should pass through to the certificate resource."
  }

  assert {
    condition     = length(aws_acm_certificate_validation.resource) == 0
    error_message = "No validation_record_fqdns means no validation resource should be created."
  }
}

run "readme_validated_certificate_example" {
  command = plan

  variables {
    domain_name             = "example.com"
    validation_record_fqdns = ["_x1.example.com"]
  }
}
