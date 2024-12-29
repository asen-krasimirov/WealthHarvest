# Try to find the existing bucket (if it exists)
data "aws_s3_bucket" "existing_bucket" {
  bucket = "my-frontend-bucket"
}

# Create the S3 bucket if it doesn't already exist
resource "aws_s3_bucket" "frontend_bucket" {
  count = length(data.aws_s3_bucket.existing_bucket.id) == 0 ? 1 : 0

  bucket = "my-frontend-bucket"

  website {
    index_document = "index.html"
    error_document = "404.html"
  }

  acl = "public-read"  # Allow public read access
}

# Create the policy only if the bucket is newly created
resource "aws_s3_bucket_policy" "frontend_policy" {
  count = length(data.aws_s3_bucket.existing_bucket.id) == 0 ? 1 : 0

  bucket = aws_s3_bucket.frontend_bucket[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "s3:GetObject"
        Effect    = "Allow"
        Resource  = "${aws_s3_bucket.frontend_bucket[0].arn}/*"
        Principal = "*"
      }
    ]
  })
}

# Set the ACL only if the bucket is newly created
resource "aws_s3_bucket_acl" "frontend_acl" {
  count = length(data.aws_s3_bucket.existing_bucket.id) == 0 ? 1 : 0

  bucket = aws_s3_bucket.frontend_bucket[0].bucket
  acl    = "public-read"
}
