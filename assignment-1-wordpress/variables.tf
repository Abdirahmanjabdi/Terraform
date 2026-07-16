variable "aws_region" {
   description = "The AWS region to deploy resources in"
   type        = string
   default     = "eu-north-1"
 }

 variable "instance_type" {
    description = "The type of instance to use"
    type        = string
    default     = "t3.micro" # falls under current version free tier
 }