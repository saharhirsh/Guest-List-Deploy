variable "state_bucket_name" {
  description = "S3 bucket name for Terraform state"
  type        = string
}

variable "create_state_backend" {
  description = "Whether to create the state backend bucket and configs"
  type        = bool
  default     = false
}

# S3 bucket for Terraform state (נוצר רק אם create_state_backend=true)
resource "aws_s3_bucket" "tf_state" {
  count  = var.create_state_backend ? 1 : 0
  bucket = var.state_bucket_name
}

# Versioning = automatic history/backups of the state
resource "aws_s3_bucket_versioning" "versioning" {
  count  = var.create_state_backend ? 1 : 0
  bucket = aws_s3_bucket.tf_state[0].id
  versioning_configuration { status = "Enabled" }
}

# Default encryption at rest
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  count  = var.create_state_backend ? 1 : 0
  bucket = aws_s3_bucket.tf_state[0].id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "pab" {
  count                   = var.create_state_backend ? 1 : 0
  bucket                  = aws_s3_bucket.tf_state[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# (Optional) Archive old versions after 30 days (cheap backups)
resource "aws_s3_bucket_lifecycle_configuration" "lc" {
  count  = var.create_state_backend ? 1 : 0
  bucket = aws_s3_bucket.tf_state[0].id

  rule {
    id     = "archive-old-versions"
    status = "Enabled"

    filter { prefix = "" } # ✅ תיקון: חובה להגדיר filter או prefix

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "DEEP_ARCHIVE"
    }
  }
}
