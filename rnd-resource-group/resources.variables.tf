variable "tags" {
  type = map(string)
  default = {
    Department  = "Cloud"
    Environment = "NonProd"
  }
}