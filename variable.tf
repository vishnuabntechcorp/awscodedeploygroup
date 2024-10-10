variable "resource_name" {
  description = "Base name used for AWS resources like CodePipeline, EC2, and CodeDeploy"
  type        = string
  default     = "devops" //
}

variable "github_token" {
  description = "OAuth token for GitHub access"
  type        = string
  default     = ""   //enter the token 
}
