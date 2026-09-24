variable "domain_name" {
  default     = null
  description = "Domain name for the certificate."
}

variable "subject_alternative_names" {
  default     = null
  description = "Additional domain names to include on the certificate."
}

variable "validation_method" {
  default     = "DNS"
  description = "Method to use for domain validation (e.g. 'DNS' or 'EMAIL')."
}

variable "validation_record_fqdns" {
  default     = null
  description = "FQDNs of the DNS validation records for this certificate (e.g. from terraform-aws-route53-record, built from this module's domain_validation_options output). If provided, this module waits for and confirms certificate validation; if null, the certificate is created but left unvalidated by this module."
}

variable "tags" {
  default     = null
  description = "A map of tags to assign to the certificate."
}
