# Terraform AWS Web Server Cluster Module

This Terraform module provisions a scalable and load-balanced web server cluster on AWS. It creates a Launch Template, Auto Scaling Group, Application Load Balancer, Target Group, Listener Rules, and the required Security Groups. The web servers are dynamically configured with values from a remote database state using a startup script (user_data.sh).

# Features

* Auto Scaling Group of EC2 instances with a launch template
* Application Load Balancer with listener and listener rule
* Target Group with health checks
*Security Groups for ALB and EC2 instances
*Remote state integration for database values

# Usage

module "webserver-cluster" {
  source = "./path-to-your-module"

  cluster_name              = "my-cluster"
  instance_type             = "t2.micro"
  server_port               = 8080
  min_size                  = 2
  max_size                  = 5
  db_remote_state_bucket    = "your-db-state-bucket"
  db_remote_state_key       = "path/to/terraform.tfstate"
}


# Required Variables
* Name	Description	Type
* cluster_name	A name used to tag resources	string
* instance_type	EC2 instance type	string
* server_port	Port the application server listens on	number
* min_size	Minimum size of the Auto Scaling Group	number
* max_size	Maximum size of the Auto Scaling Group	number
* db_remote_state_bucket	S3 bucket where the DB state is stored	string
* db_remote_state_key	Path to the DB state file in the bucket	string


# Notes

* Make sure user_data.sh exists in the same module directory and uses the variables passed in properly.
* The remote DB Terraform state must output address and port.
* The ALB is configured to return a 404 response by default unless a path rule matches.

