output "traefik_public_ip" {
  value = aws_instance.traefik.public_ip
}

output "monitoring_private_ip" {
  value = aws_instance.monitoring.private_ip
}

output "database_private_ip" {
  value = aws_instance.database.private_ip
}

output "loki_bucket_name" {
  value = aws_s3_bucket.loki_bucket.id
}
