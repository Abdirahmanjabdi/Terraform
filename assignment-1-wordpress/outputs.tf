output "wordpress_public_ip" {
    description = "The public IP address of the WordPress instance"
    value       = aws_instance.wordpress_server.public_ip
}

output "wordpress_url" {
    description = "The URL to access the WordPress instance"
    value       = "http://${aws_instance.wordpress_server.public_ip}"
}