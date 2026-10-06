resource "aws_vpc" "this" {
  # checkov:skip=CKV2_AWS_11:Flow logs need CloudWatch Logs, not emulated locally; enable on real AWS
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(var.tags, { Name = "${var.name}-vpc" })
}

# ---------- Public subnets ----------
resource "aws_subnet" "public" {
  # checkov:skip=CKV_AWS_130:Public subnets intentionally assign public IPs (web tier)
  count                   = length(var.azs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true
  tags = merge(var.tags, {
    Name = "${var.name}-public-${var.azs[count.index]}"
    tier = "public"
  })
}

# ---------- Private subnets ----------
resource "aws_subnet" "private" {
  count             = length(var.azs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = var.azs[count.index]
  tags = merge(var.tags, {
    Name = "${var.name}-private-${var.azs[count.index]}"
    tier = "private"
  })
}

# ---------- Internet Gateway ----------
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name}-igw" })
}

# ---------- Public routing ----------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name}-public-rt" })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ---------- Private routing (no internet route) ----------
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name}-private-rt" })
}

resource "aws_route_table_association" "private" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# ---------- Security group: web tier ----------
resource "aws_security_group" "web" {
  # checkov:skip=CKV_AWS_260:Web tier must accept HTTP from the internet
  # checkov:skip=CKV_AWS_382:Web tier needs outbound internet for updates and APIs
  # checkov:skip=CKV2_AWS_5:SG is exported by the module and attached by consumers
  name        = "${var.name}-web-sg"
  description = "Allow HTTP/HTTPS from the internet"
  vpc_id      = aws_vpc.this.id
  tags        = merge(var.tags, { Name = "${var.name}-web-sg" })

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------- Security group: database tier ----------
resource "aws_security_group" "db" {
  # checkov:skip=CKV2_AWS_5:SG is exported by the module and attached by consumers
  name        = "${var.name}-db-sg"
  description = "Allow Postgres only from the web tier"
  vpc_id      = aws_vpc.this.id
  tags        = merge(var.tags, { Name = "${var.name}-db-sg" })

  ingress {
    description     = "Postgres from web SG only"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    description = "Outbound only inside the VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }
}

# ---------- Security group: SSH admin access ----------
resource "aws_security_group" "ssh" {
  # checkov:skip=CKV2_AWS_5:SG is exported by the module and attached by consumers
  name        = "${var.name}-ssh-sg"
  description = "SSH from admin range only"
  vpc_id      = aws_vpc.this.id
  tags        = merge(var.tags, { Name = "${var.name}-ssh-sg" })

  ingress {
    description = "SSH from admin CIDR"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }
}

# ---------- Lock down the VPC default security group ----------
# Every VPC gets a default SG that allows all traffic between its members.
# Managing it with no rules removes that hidden "allow all".
resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name}-default-sg-locked" })
}
