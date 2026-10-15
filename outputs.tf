output "s3_bucket_name" {
    description = "Name of the S3 Bucket"
    value = aws_s3_bucket.my_bucket.id
}

output "s3_bucket_arn" {
    description = "ARN of the practice S3 bucket"
    value       = aws_s3_bucket.basic.arn
}