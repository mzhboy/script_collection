#!/usr/local/bin/pwsh
$TMP=[system.io.path]::GetTempPath()
$MediaDir=$PWD.Path
$HashTable=@{}
$Objs=Get-ChildItem -Filter *.flv

$Objs|ForEach-Object -Process{
    if($_.name -match "_part\d+\.flv$"){
# https://stackoverflow.com/questions/10184156/whats-the-difference-between-replace-and-replace-in-powershell
        $FileNameTrimmed=($_.Name -Replace "_part\d+\.flv$","")
        $AvNumber=$FileNameTrimmed.Split('-')[-1]
        if(!($HashTable.ContainsKey($AvNumber))) {$HashTable.Add($AvNumber,$FileNameTrimmed)}
    }
}

if($HashTable.Count -eq 0) {exit}

ForEach ($item in $HashTable.Keys){
    $ListFile=Join-Path -Path $TMP -ChildPath ($item + '.list')
    if(Test-Path -LiteralPath $ListFile){echo $OutFile;Remove-Item -LiteralPath $ListFile -Force}
#   contains concat demuxer listfile format
    $ArrList=@()
#   contains a group of flv segment file name,which will be delete after concatenation has been successfully executed
    $ArrFile=@()

#   $Objs.Name.Where({$PSItem.StartsWith($HashTable[$item])}) # untested
    $Objs|ForEach-Object -Process{
        if ($_.Name.StartsWith($HashTable[$item])){
# https://trac.ffmpeg.org/wiki/Concatenate
            $ArrList += ("file '" + $_.FullName + "'")
            $ArrFile += $_.FullName
        }
    }
    $ArrList|Out-File -LiteralPath $ListFile -Append -Encoding utf8 -Force

    $OutMediaFile=$HashTable[$item] + '.mp4'
    $OutMediaFile=Join-Path -Path $MediaDir -ChildPath $OutMediaFile

    $ArgumentList = '-hide_banner -f concat -safe 0 -y -i "{0}" -c copy "{1}"' -f $ListFile,$OutMediaFile
    $Process=Start-Process ffmpeg -ArgumentList $ArgumentList -PassThru;
    $Process.WaitForExit();

    if(($Process.ExitCode -eq 0) -and (Test-Path -LiteralPath $OutMediaFile)){
        Remove-Item -LiteralPath $ListFile
        $ArrFile|ForEach-Object -Process{
            Remove-Item -LiteralPath $_
        }
    }
}

