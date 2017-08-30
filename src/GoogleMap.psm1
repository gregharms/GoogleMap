param (
    [bool]$DebugModule = $false
)

# Inspired by https://becomelotr.wordpress.com/2017/02/13/expensive-dot-sourcing/
foreach ($file in Get-ChildItem $PSScriptRoot\functions\*.ps1) {
    if ($DebugModule) {
        . $file.FullName
    } else {
        $ExecutionContext.InvokeCommand.InvokeScript(
            $false, 
            (
                [scriptblock]::Create(
                    [io.file]::ReadAllText(
                        $file.FullName,
                        [Text.Encoding]::UTF8
                    )
                )
            ), 
            $null, 
            $null
        )
    }
}