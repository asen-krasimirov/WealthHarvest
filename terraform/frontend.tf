# Create the S3 bucket
resource "aws_s3_bucket" "frontendbucketwealthharvest" {
  bucket = "frontendbucketwealthharvest"

  website {
    index_document = "index.html"
    error_document = "404.html"
  }
}

# Create the policy for the bucket
resource "aws_s3_bucket_policy" "frontend_policy" {
  bucket = aws_s3_bucket.frontendbucketwealthharvest.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "s3:GetObject"
        Effect    = "Allow"
        Resource  = "${aws_s3_bucket.frontendbucketwealthharvest.arn}/*"
        Principal = "*"
      }
    ]
  })
}

# Set the ACL for the bucket
resource "aws_s3_bucket_acl" "frontend_acl" {
  bucket = aws_s3_bucket.frontendbucketwealthharvest.bucket
  acl    = "public-read"
}
