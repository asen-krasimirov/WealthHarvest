# Check if the bucket already exists using a data source
data "aws_s3_bucket" "frontend_bucket" {
  bucket = "my-frontend-bucket"
}

resource "aws_s3_bucket" "frontend_bucket" {
  count = length(data.aws_s3_bucket.frontend_bucket.id) == 0 ? 1 : 0  # Create only if the bucket doesn't exist

  bucket = "my-frontend-bucket"

  website {
    index_document = "index.html"
    error_document = "404.html"
  }
}

resource "aws_s3_bucket_policy" "frontend_policy" {
  bucket = aws_s3_bucket.frontend_bucket[count.index].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "s3:GetObject"
        Effect    = "Allow"
        Resource  = "${aws_s3_bucket.frontend_bucket[count.index].arn}/*"
        Principal = "*"
      }
    ]
  })
}

resource "aws_s3_bucket_acl" "frontend_acl" {
  bucket = aws_s3_bucket.frontend_bucket[count.index].bucket
  acl    = "public-read"
}
