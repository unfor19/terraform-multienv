output "s3_bucket_url" {
  value = aws_s3_bucket.app.website_endpoint
}
