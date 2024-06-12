resource "aws_vpc" "main" {
  cidr_block = var.VpcCidr

  tags = {
    Name = var.VpcName
  }
}

resource "aws_subnet" "public" {
  count             = 1
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-${count.index}"
  }
}

resource "aws_subnet" "private" {
  count             = 1
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 2)

  tags = {
    Name = "private-subnet-${count.index}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_eip" "ip-ngw" {
}

resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.ip-ngw.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = var.NGWName
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = var.CidrInternet
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = var.PublicRTName
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = var.CidrInternet
    nat_gateway_id = aws_nat_gateway.ngw.id
  }

  tags = {
    Name = var.PrivateRTName
  }
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
