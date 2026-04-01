variable "server_port" {
  description = "The port the srver will use for HTTP requests."
  type        = number
  default     = 8080
}


variable "cluster_name" {
  description = "The name to use for all the cluster resources."
  type        = string
}

variable "db_remote_state_bucket" {
  description = "The name of the s3 bucket for the database's remote state."
  type        = string
}

variable "db_remote_state_key" {
  description = "The path for the database's remote state in s3."
  type        = string
}

variable "instance_type" {
  description = "The type of EC2 instance to run."
  type        = string
}

variable "min_size" {
  description = "The minimum number of EC2 instance in the ASG."
  type        = number
}

variable "max_size" {
  description = "The maximum number of EC2 instance in the ASG."
  type        = number
}

# Allows user to specify custom tags

variable "custom_tags" {
  description = "Custom tags to set in the instances in the ASG"
  type        = map(string)
  default     = {}
}

# Input variable use to verify whether auto-scaling should be enable

variable "enable_autoscaling" {
  description = "If set to true enable auto-scaling"
  type        = bool
}

variable "ami" {
  description = "The AMI to run in the cluster"
  type        = string
  default     = "ami-0b6c6ebed2801a5cb"
}

variable "server_text" {
  description = "The text the web server should return"
  type        = string
  default     = "Hello world, checking for zero downtime deployment."
}
