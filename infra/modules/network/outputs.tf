output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "igw_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.this.id
}

output "web_sg_id" {
  description = "Security group for the web tier"
  value       = aws_security_group.web.id
}

output "db_sg_id" {
  description = "Security group for the database tier"
  value       = aws_security_group.db.id
}

output "ssh_sg_id" {
  description = "Security group for SSH access"
  value       = aws_security_group.ssh.id
}
