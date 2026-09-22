variable "ACCOUNT" {
  type = string  
  sensitive = true
  description = "The account number."
  default = "ACCOUNT"
}

variable "ADMIN_DB_PASSWORD" {
  type = string
  sensitive = true
  description = "The DB password for the admin account."
  default = "ADMIN_DB_PASSWORD"
}

variable "ADMIN_DB_USERNAME" {
  type = string
  sensitive = true
  description = "The DB username for the admin account."
  default = "ADMIN_DB_USERNAME"
}

variable "CERT_BODY" {
  type = string
  sensitive = true  
  description = "The certificate body."
  default = "CERT_BODY"
}

variable "CERT_CHAIN" {
  type = string
  sensitive = true  
  description = "The certificate chain."
  default = "CERT_CHAIN"
}

variable "CERT_PRIVATE_KEY" {
  type = string
  sensitive = true
  description = "The certificate private key."
  default = "CERT_PRIVATE_KEY"
}

variable "CLOUDWATCH_EMAIL" {
  type = string
  description = "The email used for cloudwatch endpoint (Infra)."
  default = "cloudwatch_email@domain.com"
}

variable "DAMS_EMAIL" {
  type = string
  description = "The email used for cloudwatch endpoint (DAMS)."
  default = "dams_email@domain.com"
}

variable "DB_ALLOCATED_STORAGE" {
  type = number
  description = "The allocated storage for the database in GB."
  default = 20
}

variable "DB_BACKUP_WINDOW" {
  type = string
  description = "The backup window for the database. (UTC)"
  default = "07:00-08:00"
}

variable "DB_ENGINE_VERSION" {
  type = string
  description = "The database engine version for the application."
  default = "8.4"
}

variable "DB_INSTANCE_CLASS" {
  type = string
  description = "The database intance class for the application."
  default = "db.t3.medium"
}

variable "DB_INSTANCE_CLASS_MEMORY" {
  type = string
  description = "The database intance class available memory in GB."
  default = "4"
}

variable "DB_MAINTENANCE_WINDOW" {
  type = string
  description = "The maintenance window for the database. (UTC)"
  default = "sat:05:00-sat:06:00"
}

variable "ECR_IMAGE" {
  type = string
  description = "The image name used for task definition."
  default = "ECR_IMAGE"
}

variable "ENV" {
  type = string
  description = "The environment in which to deploy the solution."
  default = "dev"
}

variable "EXTERNAL_ID" {
  type = string  
  sensitive = true
  description = "External ID of the automation account role."
  default = "EXTERNAL_ID"
}

variable "FORCE_REFRESH" {
  type = string
  description = "If set to true, this will start the application with an empty database."
  default = "FALSE"
}

variable "FRESH_INSTALL" {
  type = string
  description = "If set to TRUE, it will do a fresh install of the filesystem."
  default = "FALSE"
}

variable "MFT_CLUSTER" {
  type = string
  description = "If set to true, this will start the application in cluster mode."
  default = "TRUE"
}

variable "ROLE_ARN" {
  type = string  
  sensitive = true
  description = "ARN of the role used by terraform."
  default = "ARN"
}

variable "TASK_DEFINITION_CPU" {
  type = number
  description = "The task definition CPU."
  default = 1024
}

variable "TASK_DEFINITION_MEMORY" {
  type = number
  description = "The task definition memory."
  default = 3072
}