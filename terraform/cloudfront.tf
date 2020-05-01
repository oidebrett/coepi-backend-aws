locals {
  url = regex("^(?:(?P<scheme>[^:/?#]+):)?(?://(?P<domain>[^/?#]*))?", "${aws_api_gateway_deployment.tcn_lambda_gateway.invoke_url}")
}

resource "aws_cloudfront_distribution" "coepi_cloudfront" {

  origin {
    domain_name = local.url.domain
    origin_id   = "Custom-${local.url.domain}"

    custom_origin_config {
      origin_protocol_policy = "https-only"
      origin_ssl_protocols = ["TLSv1","TLSv1.1","TLSv1.2"]
      http_port = 80
      https_port = 443
    }
  }
  
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "coepiCloudfront"

  default_cache_behavior {
    target_origin_id = "Custom-${local.url.domain}"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }
  
  # Cache behavior with precedence 0
  ordered_cache_behavior {
    target_origin_id = "Custom-${local.url.domain}"
    path_pattern     = "/tcnreport"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]

    forwarded_values {
      query_string = true
      query_string_cache_keys = ["date", "intervalNumber","intervalLengthMs"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    viewer_protocol_policy = "allow-all"
  }
  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name        = var.appName
    Environment = var.env
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

}

output "cloudfront_base_url" {
  value = "https://${aws_cloudfront_distribution.coepi_cloudfront.domain_name}/v4/tcnreport"
}

