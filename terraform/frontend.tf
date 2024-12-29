resource "aws_s3_bucket" "frontend_bucket" {
  bucket = "my-frontend-bucket"
  acl    = "public-read"  # Allow public read access

  website {
    index_document = "index.html"
    error_document = "404.html"
  }
}

resource "aws_s3_bucket_policy" "frontend_policy" {
  bucket = aws_s3_bucket.frontend_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "s3:GetObject"
        Effect    = "Allow"
        Resource  = "${aws_s3_bucket.frontend_bucket.arn}/*"
        Principal = "*"
      }
    ]
  })
}

# Remove the block public ACL settings to allow public access
resource "aws_s3_bucket_public_access_block" "frontend_bucket_access_block" {
  bucket = aws_s3_bucket.frontend_bucket.id

  block_public_acls = false  # Allow public ACLs
  ignore_public_acls = false  # Allow public ACLs
}
