# ICON Test

## Task 1 - Infrastructure upgrade - Architecture Diagram
![enter image description here](https://github.com/wkcVishmal/icon-test/blob/main/architecture.png)

## Task 2 - Terraform
### Setup guide
1. Login into the Azure CLI

https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/azure_cli#logging-into-the-azure-cli

2. Initialize terrafrom environment

    ```terraform init```

3. Create new terraform workspace

    ```terraform workspace new prod```

4. Create Azure infrastructure

    ```terraform apply```