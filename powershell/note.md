# Powershell Note #

1. String 的 `Replace()` method 和 `-Replace` operator 的区别： `Replace()` method 不做正则匹配， `-replace` 做正则匹配。 [具体来说](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_operators?view=powershell-6)  ( `-match` , `-notmatch` , `-replace` ) 使用正则匹配； ( `-like` , `-notlike` ) 使用通配符 。
2. String 的 `Contains()` method 只做完整的字符串匹配，需要检测某段字符串是否包含于该字符串的时候用 `-match` 或 `-like` 。例如
	```powershell
	PS C:\Users\Administrator> $alf=@("This is a", "are you ok")
	
	PS C:\Users\Administrator> $alf
	This is a
	are you ok
	
	PS C:\Users\Administrator> $alf.Contains("are")
	False
	
	PS C:\Users\Administrator> $alf.Contains("are you ok")
	True
	
	PS C:\Users\Administrator> 
	```

3. `Start-Process` 的 `-ArgumentList` 参数如果包含文件路径，而且文件路径包含方括弧 `[]` 那么该参数必须被 `单引号` `'` 括起来。为了使用变量向其中传递路径使用如下方法 `'-arg1 {0} -arg2 "{1}"' -f arg1,arg2`
4. `Start-Process` 如果要返回可以操作的 Object 必须添加 `-PassThru`。例如
	```powershell
	$p = Start-Process ffmpeg -ArgumentList $arg -PassThru
	$p.PriorityClass = "BelowNormal";
	$p.WaiteForExit()
	$stdout = $p.StandardOutput.ReadToEnd()
	$stderr = $p.StandardError.ReadToEnd()
	$stdout|Out-File -FilePath $stdoutFileFullName -Append -Encoding utf8 -Force
	Write-Host "stdout: $stdout"
	Write-Host "stderr: $stderr"
	```
5. String 的 `TrimEnd()` `TrimStart()` 方法不支持正则或通配符匹配，只删除输入的可以正确匹配的字符串。
6. ForEach 的输入是不能被 `ForEach` 后面的块语句改变的，会报错
7. 获取对象的时候可以显示地让对象成为数组。例如 `$objs = @(Get-ChildItem -Recurse)` 这样获取其对象数量的时候不会报错 `$objs.Count` ，而且使用上很方便，ISE会给出提示。
8. Start-Process 当执行脚本所在文件夹包含 `[]` 时，会提示如下，解决这个问题，暂时只能把脚本文件移出该文件夹执行。
	>>Start-Process : 无法执行操作，因为通配符路径 F:\[Sakurato.sub][Re Creators][01-22END][GB][720P] 无法解析为文件。
	
	
