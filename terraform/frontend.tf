# Try to find the existing bucket (if it exists)
data "aws_s3_bucket" "existing_bucket" {
  bucket = "frontendbucketwealthharvest"
}

# Create the S3 bucket if it doesn't already exist
resource "aws_s3_bucket" "new_bucket" {
  count = length(data.aws_s3_bucket.existing_bucket.id) == 0 ? 1 : 0

  bucket = "frontendbucketwealthharvest"
}

# Configure the website for the S3 bucket if it is newly created
resource "aws_s3_bucket_website_configuration" "website_config" {
  count = length(data.aws_s3_bucket.existing_bucket.id) == 0 ? 1 : 0

  bucket = aws_s3_bucket.new_bucket[count.index].bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "404.html"
  }
}

# Create the policy for the bucket if it is newly created
resource "aws_s3_bucket_policy" "frontend_policy" {
  count = length(data.aws_s3_bucket.existing_bucket.id) == 0 ? 1 : 0

  bucket = aws_s3_bucket.new_bucket[count.index].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "s3:GetObject"
        Effect    = "Allow"
        Resource  = "${aws_s3_bucket.new_bucket[count.index].arn}/*"
        Principal = "*"
      }
    ]
  })
}

# Set the ACL for the bucket if it is newly created
resource "aws_s3_bucket_acl" "frontend_acl" {
  count = length(data.aws_s3_bucket.existing_bucket.id) == 0 ? 1 : 0

  bucket = aws_s3_bucket.new_bucket[count.index].bucket
  acl    = "public-read"
}
