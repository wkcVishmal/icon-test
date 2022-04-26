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
- master
- staging

variables:
  azureSubscription: $(azureSubscription)
  vmImageName: 'ubuntu-latest'

stages:
- stage: Build
  displayName: Build stage
  jobs:
  - job: Build
    displayName: Build
    pool:
      vmImage: $(vmImageName)

    steps:
    - task: NodeTool@0
      inputs:
        versionSpec: '10.x'
      displayName: 'Install Node.js'

    - script: |
        npm install
        npm run build --if-present
        npm run test --if-present
      displayName: 'npm install, build and test'

    - task: ArchiveFiles@2
      displayName: 'Archive files'
      inputs:
        rootFolderOrFile: '$(System.DefaultWorkingDirectory)'
        includeRootFolder: false
        archiveType: zip
        archiveFile: $(Build.ArtifactStagingDirectory)/$(Build.BuildId).zip
        replaceExistingArchive: true

    - upload: $(Build.ArtifactStagingDirectory)/$(Build.BuildId).zip
      artifact: drop

- stage: DeployStaging
  displayName: DeployStaging
  dependsOn: Build
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/staging'))
  jobs:
  - deployment: DeployStaging
    displayName: DeployStaging
    environment: staging
    pool:
      vmImage: $(vmImageName)
    strategy:
      runOnce:
        deploy:
          steps:
          - task: AzureWebApp@1
            displayName: 'Azure Web App Deploy staging: '
            inputs:
              azureSubscription: $(azureSubscription)
              appType: webAppLinux
              appName: website-staging
              runtimeStack: 'NODE|12-lts'
              package: $(Pipeline.Workspace)/drop/$(Build.BuildId).zip
              startUpCommand: 'npm run start'

- stage: DeployProd
  displayName: DeployProd
  dependsOn: Build
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/master'))
  jobs:
  - deployment: DeployProd
    displayName: DeployProd
    environment: prod
    pool:
      vmImage: $(vmImageName)
    strategy:
      runOnce:
        deploy:
          steps:
          - task: AzureWebApp@1
            displayName: 'Azure Web App Deploy prod: '
            inputs:
              azureSubscription: $(azureSubscription)
              appType: webAppLinux
              appName: website-prod
              runtimeStack: 'NODE|12-lts'
              package: $(Pipeline.Workspace)/drop/$(Build.BuildId).zip
              startUpCommand: 'npm run start'
```