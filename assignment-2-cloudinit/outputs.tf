output "nginx_url" {
  description = "The URL to access your Nginx site"
  value       = "http://${aws_instance.nginx_server.public_ip}"
}