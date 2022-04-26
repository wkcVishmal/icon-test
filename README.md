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


## Task 3 - CI/CD Pipeline - azure-pipelines.yml

```
trigger:
  - main
  
pr: none
  
variables: 
  # Service connection as configured in project settings
  prodConnection: 'isabelProd'

  # App name
  prodApp: 'isabelProd'
  
stages:
  - stage: build
    displayName: 'Build'
    jobs:
    - job: build_test
      displayName: 'Build and test'
      pool:
        vmImage: 'Ubuntu-16.04'
      steps:
      - task: NodeTool@0
        inputs:
          versionSpec: '12.x'
        displayName: 'Install Node.js'
      - script: |
          npm install
        displayName: 'npm install'
      - task: ArchiveFiles@2
        inputs:
          rootFolderOrFile: '$(System.DefaultWorkingDirectory)'
          includeRootFolder: false
      - task: PublishPipelineArtifact@0
        inputs:
          targetPath: '$(System.ArtifactsDirectory)'
  
  
  - stage: prod
    displayName: 'Prod'
    dependsOn: build
    jobs:
    - deployment: deployProd
      displayName: 'Deploy prod'
      environment: isabelProdEnv
      strategy:
        runOnce:
          deploy:
            steps:
            - task: DownloadPipelineArtifact@1
              inputs:
                downloadPath: '$(System.DefaultWorkingDirectory)'
            - task: AzureWebApp@1
              inputs:
                azureSubscription: $(prodConnection)
                appType: 'webAppLinux'
                appName: $(prodApp)
                runtimeStack: 'NODE|12.1'
                startUpCommand: 'npm run start'
```