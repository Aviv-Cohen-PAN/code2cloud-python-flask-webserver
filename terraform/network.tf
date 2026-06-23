# network.tf

# --------------------------------------------------------------
# VPC (Virtual Private Cloud)
# --------------------------------------------------------------

# Defines the main Virtual Private Cloud (VPC), which is the isolated network for the EKS cluster.
resource "aws_vpc" "k8s_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"

  tags = {
    Name      = "${var.cluster_name}-VPC"
    yor_trace = "44906a5c-1ff5-453f-a3cc-7947c3a8f155"
  }
}

# --------------------------------------------------------------
# Subnets
# --------------------------------------------------------------

# Defines a public subnet in Availability Zone 'a'. Public-facing resources like load balancers go here.
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.k8s_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name                     = "${var.cluster_name}-public-subnet-1"
    "kubernetes.io/role/elb" = "1"
    yor_trace                = "202b8d79-33a3-4b07-8369-b1876e2f14a2"
  }
}

# Defines a public subnet in Availability Zone 'b'.
resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.k8s_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = {
    Name                     = "${var.cluster_name}-public-subnet-2"
    "kubernetes.io/role/elb" = "1"
    yor_trace                = "d888a9f3-b7a5-4c28-be8b-f5457fc964d8"
  }
}

# Defines a private subnet in Availability Zone 'a'. Internal resources like EKS nodes go here.
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.k8s_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name                              = "${var.cluster_name}-private-subnet-1"
    "kubernetes.io/role/internal-elb" = "1"
    yor_trace                         = "014d1598-ae21-4827-92c4-3208eed7f499"
  }
}

# Defines a private subnet in Availability Zone 'b'.
resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.k8s_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name                              = "${var.cluster_name}-private-subnet-2"
    "kubernetes.io/role/internal-elb" = "1"
    yor_trace                         = "9a70f1a6-18ff-4f03-ab73-85cb07c88b2f"
  }
}


# --------------------------------------------------------------
# Gateways
# --------------------------------------------------------------

# Creates an Internet Gateway to allow communication between the VPC and the internet.
resource "aws_internet_gateway" "k8s_igw" {
  vpc_id = aws_vpc.k8s_vpc.id
  tags = {
    Name      = "${var.cluster_name}-IGW"
    yor_trace = "df1b4460-ccde-4cc8-80a1-5ef7d0276c69"
  }
}

# Allocates a static public IP address for the first NAT Gateway.
resource "aws_eip" "nat_eip_1" {
  domain = "vpc"
  tags = { Name = "${var.cluster_name}-NAT1-EIP"
    yor_trace = "def229a4-4a8f-45db-8048-6f0f3236b6b5"
  }
}

# Allocates a static public IP address for the second NAT Gateway.
resource "aws_eip" "nat_eip_2" {
  domain = "vpc"
  tags = { Name = "${var.cluster_name}-NAT2-EIP"
    yor_trace = "4a0efaea-2d67-4857-a025-f63e4d121673"
  }
}

# Creates a NAT Gateway in the first public subnet for outbound internet access from private subnets.
resource "aws_nat_gateway" "nat_gateway_1" {
  allocation_id = aws_eip.nat_eip_1.id
  subnet_id     = aws_subnet.public_1.id
  tags = { Name = "${var.cluster_name}-NAT1"
    yor_trace = "297a2dac-0bc5-43ef-bee4-7f1bfebe5ff9"
  }
  depends_on = [aws_internet_gateway.k8s_igw]
}

# Creates a second NAT Gateway in the second public subnet for high availability.
resource "aws_nat_gateway" "nat_gateway_2" {
  allocation_id = aws_eip.nat_eip_2.id
  subnet_id     = aws_subnet.public_2.id
  tags = { Name = "${var.cluster_name}-NAT2"
    yor_trace = "13a08363-34f4-4f80-8ebd-72dcc6edbf02"
  }
  depends_on = [aws_internet_gateway.k8s_igw]
}


# --------------------------------------------------------------
# Routing
# --------------------------------------------------------------

# Defines a route table for the public subnets.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.k8s_vpc.id
  tags = { Name = "${var.cluster_name}-Public-RT"
    yor_trace = "f06d42f7-7317-4711-bb4f-c177395dfd63"
  }
}

# Adds a route to the public route table that directs internet-bound traffic to the Internet Gateway.
resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.k8s_igw.id
}

# Associates the first public subnet with the public route table.
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

# Associates the second public subnet with the public route table.
resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}


# Defines a dedicated route table for the first private subnet.
resource "aws_route_table" "private_1" {
  vpc_id = aws_vpc.k8s_vpc.id
  tags = { Name = "${var.cluster_name}-Private-RT-1"
    yor_trace = "59071b1c-20de-4797-a743-d2633672eb9a"
  }
}

# Adds a route that directs internet-bound traffic from the private subnet to the first NAT Gateway.
resource "aws_route" "private_1_nat_access" {
  route_table_id         = aws_route_table.private_1.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway_1.id
}

# Associates the first private subnet with its dedicated route table.
resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_1.id
}


# Defines a dedicated route table for the second private subnet.
resource "aws_route_table" "private_2" {
  vpc_id = aws_vpc.k8s_vpc.id
  tags = { Name = "${var.cluster_name}-Private-RT-2"
    yor_trace = "8e6b762a-e854-470f-981f-c2e913634fb7"
  }
}

# Adds a route that directs internet-bound traffic from the private subnet to the second NAT Gateway.
resource "aws_route" "private_2_nat_access" {
  route_table_id         = aws_route_table.private_2.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway_2.id
}

# Associates the second private subnet with its dedicated route table.
resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private_2.id
}