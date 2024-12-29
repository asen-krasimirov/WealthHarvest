# Create the S3 bucket
resource "aws_s3_bucket" "frontend_bucket_wealthharvest" {
  bucket = "my-frontend-bucket"

  website {
    index_document = "index.html"
    error_document = "404.html"
  }
}

# Create the policy for the bucket
resource "aws_s3_bucket_policy" "frontend_policy" {
  bucket = aws_s3_bucket.frontend_bucket_wealthharvest.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "s3:GetObject"
        Effect    = "Allow"
        Resource  = "${aws_s3_bucket.frontend_bucket_wealthharvest.arn}/*"
        Principal = "*"
      }
    ]
  })
}

# Set the ACL for the bucket
resource "aws_s3_bucket_acl" "frontend_acl" {
  bucket = aws_s3_bucket.frontend_bucket_wealthharvest.bucket
  acl    = "public-read"
}
