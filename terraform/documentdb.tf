# Subnet group using default VPC public subnets (free tier friendly)
resource "aws_docdb_subnet_group" "librechat" {
  name       = "librechat-docdb-subnet-group"
  subnet_ids = data.aws_subnets.public.ids
}

# DocumentDB cluster
resource "aws_docdb_cluster" "librechat" {
  cluster_identifier = "librechat-docdb"
  engine             = "docdb"
  engine_version     = "5.0.0"  # MongoDB 5 compatibility
  master_username    = var.documentdb_master_username
  master_password    = var.documentdb_master_password
  skip_final_snapshot = true
  vpc_security_group_ids = [aws_security_group.documentdb.id]
  db_subnet_group_name   = aws_docdb_subnet_group.librechat.name
}

# Single free-tier eligible instance
resource "aws_docdb_cluster_instance" "librechat" {
  identifier        = "librechat-docdb-0"
  cluster_identifier = aws_docdb_cluster.librechat.id
  instance_class     = "db.t4g.medium"  # smallest supported for DocDB 5.0
  engine             = aws_docdb_cluster.librechat.engine
} 