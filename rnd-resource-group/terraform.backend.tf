terraform {
  backend "azurerm" {
    container_name       = "cloudrnd"
    key                  = "terraform.tfstate"
    storage_account_name = "cloudrndstates"
    resource_group_name  = "tfstate"
  }
}
