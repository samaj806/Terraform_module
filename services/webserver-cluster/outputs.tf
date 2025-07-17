output "alb_dns_name" {
  value       = aws_lb.load-balancer.dns_name
  description = "The public IP address of the web server"
}

output "asg_name" {
  value       = aws_autoscaling_group.server_increase.name
  description = "The name of the Auto Scaling group."
}

output "servers-dns_name" {
  value       = aws_lb.load-balancer.dns_name
  description = "The domain name of the load balancer."
}

output "alb_security_group_id" {
  value       = aws_security_group.alb.id
  description = "The ID of the Security Group attached to the load balancer. "
}