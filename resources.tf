resource "aws_acm_certificate" "resource" {
  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = var.validation_method

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}

resource "aws_acm_certificate_validation" "resource" {
  count = var.validation_record_fqdns != null ? 1 : 0

  certificate_arn         = aws_acm_certificate.resource.arn
  validation_record_fqdns = var.validation_record_fqdns
}

output "id" {
  description = "The ID of the certificate."
  value       = aws_acm_certificate.resource.id
}

output "arn" {
  description = "The ARN of the certificate."
  value       = aws_acm_certificate.resource.arn
}

output "status" {
  description = "The certificate's validation status."
  value       = aws_acm_certificate.resource.status
}

output "validated_arn" {
  description = "The ARN of the certificate, but only once validation has completed (null until then, or always null if validation_record_fqdns was never provided)."
  value       = one(aws_acm_certificate_validation.resource[*].certificate_arn)
}

output "domain_validation_options" {
  description = "Domain validation objects (name/type/value) for building DNS validation records."
  value       = aws_acm_certificate.resource.domain_validation_options
}
