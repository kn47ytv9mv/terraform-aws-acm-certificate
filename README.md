# terraform-aws-acm-certificate

Terraform module for an ACM certificate with optional DNS validation.
DNS validation records themselves are not created by this module — pair it
with [`terraform-aws-route53-record`](https://github.com/kn47ytv9mv/terraform-aws-route53-record).

## Cost

Public certificates, which is what this module creates, carry no
charge. Cost applies only to certificates issued through AWS Private
Certificate Authority, which this module does not use.

## Usage

```hcl
module "certificate" {
  source = "kn47ytv9mv/acm-certificate/aws"

  domain_name = "example.com"
}
```

Or directly from this repository:

```hcl
module "certificate" {
  source = "github.com/kn47ytv9mv/terraform-aws-acm-certificate"

  domain_name = "example.com"
}
```

With DNS validation, paired with `terraform-aws-route53-record`. This is
one `certificate` module call, not two — its `validation_record_fqdns`
argument is wired from the `validation_records` module, which is in turn
built from this same `certificate` module's own `domain_validation_options`
output. This is not circular: the underlying certificate resource itself
does not depend on the validation records, only the *validation* resource
inside this module does, so Terraform can still order
cert → DNS records → validation correctly:

```hcl
module "certificate" {
  source = "kn47ytv9mv/acm-certificate/aws"

  domain_name = "example.com"

  validation_record_fqdns = values(module.validation_records.fqdns)
}

locals {
  domains = ["example.com"]

  validation = {
    for dvo in module.certificate.domain_validation_options :
    dvo.domain_name => dvo
  }
}

module "validation_records" {
  source = "kn47ytv9mv/route53-record/aws"

  records = {
    for domain in local.domains : domain => {
      zone_id = var.route53_zone_id
      name    = local.validation[domain].resource_record_name
      type    = local.validation[domain].resource_record_type
      records = [local.validation[domain].resource_record_value]
    }
  }
}
```

**`local.domains` must list the domains literally**, rather than being
derived from `domain_validation_options`. Terraform needs every
`records` key at plan time, and everything ACM computes — the record
names, types, and values — is unknown until after apply. Keying off
those values fails the plan outright with *"the for_each map includes
keys derived from resource attributes that cannot be determined until
apply"*. Writing the domains out keeps the keys known and leaves only
the values to resolve during apply, which is what Terraform requires.
The list is the same set of names given to `domain_name` and
`subject_alternative_names`.

**Use `validated_arn`, not `arn`, for anything that must not attach until
validation completes** — e.g. an HTTPS listener's `certificate_arn`.
`arn` is available the moment the certificate resource is created,
before ACM has validated it; AWS's load balancer API rejects attaching
a certificate that is still `PENDING_VALIDATION`. `validated_arn` is
`null` unless `validation_record_fqdns` was provided, and only resolves
once `aws_acm_certificate_validation` completes, so depending on it
forces the correct ordering:

```hcl
module "https" {
  source = "kn47ytv9mv/alb-listener/aws"

  load_balancer_arn = module.alb.arn
  port              = 443
  protocol          = "HTTPS"

  certificate_arn  = module.certificate.validated_arn
  target_group_arn = module.target_group.arn
}
```

## Requirements

| Name | Version |
|---|---|
| terraform | >= 1.0 |
| aws | ~> 6.61 |

## Providers

| Name | Version |
|---|---|
| aws | ~> 6.61 |

## Inputs

| Name | Description | Default | Required |
|---|---|---|---|
| domain_name | Domain name for the certificate. | `null` | no |
| subject_alternative_names | Additional domain names to include on the certificate. | `null` | no |
| validation_method | Method to use for domain validation (e.g. `'DNS'` or `'EMAIL'`). | `"DNS"` | no |
| validation_record_fqdns | FQDNs of the DNS validation records for this certificate (e.g. from `terraform-aws-route53-record`, built from this module's `domain_validation_options` output). If provided, this module waits for and confirms certificate validation; if null, the certificate is created but left unvalidated by this module. | `null` | no |
| tags | A map of tags to assign to the certificate. | `null` | no |

## Outputs

| Name | Description |
|---|---|
| id | The ID of the certificate. |
| arn | The ARN of the certificate. |
| status | The certificate's validation status. |
| validated_arn | The ARN of the certificate, but only once validation has completed (`null` until then, or always `null` if `validation_record_fqdns` was never provided). |
| domain_validation_options | Domain validation objects (name/type/value) for building DNS validation records. |

## License

MIT — see [LICENSE.md](LICENSE.md).
