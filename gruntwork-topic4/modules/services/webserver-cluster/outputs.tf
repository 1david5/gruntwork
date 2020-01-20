output "clb_dns_name" {
  value       = aws_elb.exampleclb.dns_name
  description = "The domain name of the load balancer"
}

output "asg_name" {
  value       = aws_autoscaling_group.my_ASG.name
  description = "The name of the Auto Scaling Group"
}