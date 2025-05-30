output "agent_controller_url" {
  description = "URL of Aembit Agent Controller"
  value = "https://${aws_instance.example_instance.private_dns}:5443"
}
