$directories = Get-ChildItem -Directory

foreach($directory in $directories)
{
    if (($directory.Name.Length -gt 8) -and (Get-ChildItem -Directory -Name -Include $directory.Name.Substring(0,8)))
    {
        Move-Item -Path .\$directory\* -Destination (".\"+$directory.Name.Substring(0,8)) -Force
    }
    else
    {
        New-Item -Path ".\" -Name $directory.Name.Substring(0,8) -ItemType "Directory" -Force

        Move-Item -Path .\$directory\* -Destination (".\"+$directory.Name.Substring(0,8)) -Force
    }
}
