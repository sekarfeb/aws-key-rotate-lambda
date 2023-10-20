variable "function_name" {
  description = "Lambda function name"
  type        = string
  default     = "iam-key-rotate-lambda-python"
}

variable "runtime" {
  description = "Python runtime version"
  type        = string
  default     = "python3.11"
}

variable "handler" {
  description = "Specify your Python handler function"
  type        = string
  default     = "lambda_function.handler"
}