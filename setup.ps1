Start-Transcript -Path 'C:/terraform-log.txt' -append;
$VerbosePreference = 'Continue';
$InformationPreference = 'Continue';
Install-WindowsFeature -name Web-Server -IncludeManagementTools;
Stop-Transcript;