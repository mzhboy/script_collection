#!/usr/local/bin/pwsh

$RemoveItem = $true
function convert-mp4([string[]]$InputFileName,[int]$AVNumber){
    if($InputFileName.Count -eq 1){
        $inFile = $InputFileName[0]
        $outFile = [io.path]::ChangeExtension($InputFileName[0], "mp4")
        $ArgumentList = '-hide_banner -y -i "{0}" -c copy "{1}"' -f $inFile,$outFile
        Write-Host "------ ffmpeg" $ArgumentList
        $p = Start-Process ffmpeg -ArgumentList $ArgumentList -PassThru -Wait
        if (($p.ExitCode -eq 0) -and (Test-Path $outFile)){
            if($RemoveItem -eq $true){Remove-Item  $inFile -ErrorAction SilentlyContinue}
        }
    }elseif($InputFileName.Count -gt 1){
        #$outFile = [io.path]::ChangeExtension($InputFileName[0], "mp4")
        $outFile = Join-Path -Path $PWD.Path -ChildPath ($InputFileName[0] -replace "_part\d+\.flv$",".mp4")

        $ArrList = @()
        for ([int]$i = 0; $i -lt $InputFileName.count; $i++){
            $ArrList += ("file '" + (Join-Path -Path $PWD.Path -ChildPath $InputFileName[$i]) + "'")
        }
        $TMP=[system.io.path]::GetTempPath()
        $ListFile = Join-Path -Path $TMP -ChildPath ([string]$AVNumber + '.list')
        Out-File -LiteralPath $ListFile -InputObject $ArrList -Encoding utf8 -Force

        $ArgumentList = '-hide_banner -f concat -safe 0 -y -i "{0}" -c copy "{1}"' -f $ListFile,$outFile
        Write-Host "----ffmpeg" $ArgumentList
        $Process=Start-Process ffmpeg -ArgumentList $ArgumentList -PassThru -Wait

        if(($Process.ExitCode -eq 0) -and (Test-Path -LiteralPath $outFile)){
            Remove-Item -LiteralPath $ListFile -ErrorAction SilentlyContinue

            for ([int]$i = 0; $i -lt $InputFileName.count; $i++){
                if($RemoveItem -eq $true){Remove-Item -LiteralPath (Join-Path -Path $PWD.Path -ChildPath $InputFileName[$i]) -ErrorAction SilentlyContinue}
            }
        }
    }
}

function dl-filenames($url){
    $ArgumentList = '--cookies "{0}" --no-cache-dir --get-filename "{1}"' -f $CookiesFilePath,$url
# https://stackoverflow.com/questions/8761888/capturing-standard-out-and-error-with-start-process
    $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo 
    $ProcessInfo.FileName = "youtube-dl" 
    $ProcessInfo.RedirectStandardError = $true 
    $ProcessInfo.RedirectStandardOutput = $true 
    $ProcessInfo.UseShellExecute = $false 
    $ProcessInfo.Arguments = $ArgumentList 
    $ProcessInfo.CreateNoWindow = $true
    $Process = New-Object System.Diagnostics.Process 
    $Process.StartInfo = $ProcessInfo 
    $Process.Start() | Out-Null 
    $Process.WaitForExit() 
    $stdout = $Process.StandardOutput.ReadToEndAsync() 
    $stderr = $Process.StandardError.ReadToEndAsync() 
    $FileNames = ([string[]]$stdout.Result.split([Environment]::NewLine,[System.StringSplitOptions]::RemoveEmptyEntries))
    return [pscustomobject]@{
        FileNames = $FileNames
        ExitCode = $Process.ExitCode
    }
}

function dl-url($url){
<#
    $p = Start-Process youtube-dl -ArgumentList $arg -PassThru -WindowStyle Hidden
    #$p.StandardOutput.ReadToEndAsync()
    $stdout = $p.StandardOutput.ReadToEnd()
    $stderr = $p.StandardError.ReadToEnd()
#>
    $ret = dl-filenames $url
    if ($ret.FileNames.Count -eq 1){$TargetFile = [io.path]::ChangeExtension($ret.FileNames[0], "mp4")}
    elseif($ret.FileNames.Count -gt 1) {$TargetFile = ($ret.FileNames[0] -replace "_part\d+\.flv$",".mp4")}
    if (-not ([string]::IsNullOrEmpty($TargetFile))){
        Write-Host "TargetFile" + $TargetFile
        if(Test-Path $TargetFile){
            Write-Host "Target Exists:" $TargetFile
            return
        }
    }
    
    if (($ret.exitcode -eq 0)){
        $ArgumentList = '--cookies "{0}" --no-cache-dir "{1}"' -f $CookiesFilePath,$url
        $p = Start-Process youtube-dl -ArgumentList $ArgumentList -PassThru -Wait
        if ($p.ExitCode -eq 0 ){
            Write-Host '-------------------------------------------------------'
            Write-Host 'count' $ret.FileNames.count
            Write-Host 'Entry' $ret.FileNames
            convert-mp4 $ret.FileNames $url.Split('av')[-1]
        }
    }else{Write-Host "url error or network failed"}
}

########### main ##########
$CookiesFilePath = Join-Path -Path $PSScriptRoot -ChildPath cookies.txt
if ($args.Count -gt 0){
    For($i=0;$i -lt $args.Count; $i++){
        [array]$UrlList = @()
        if (Test-Path $args[$i]) {$UrlList += Get-Content $args[$i] -ReadCount 0}
        elseif([string]$args[$i].StartsWith('https://www.bilibili.com/video/av')) {$UrlList += $args[$i].Split('?')[0]}
    
        for($j = 0; $j -lt $UrlList.Count; $j++){
            Write-Host '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
            Write-Host $UrlList[$j]
            dl-url $UrlList[$j]
        }
    }
}