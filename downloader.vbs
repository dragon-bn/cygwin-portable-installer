url = Wscript.Arguments(0)
target = Wscript.Arguments(1)
WScript.Echo "Downloading '" & url & "' to '" & target & "'..."
Set req = CreateObject("WinHttp.WinHttpRequest.5.1")
req.Open "GET", url, False
req.Send
If req.Status <> 200 Then
   WScript.Echo "FAILED to download: HTTP Status " & req.Status
   WScript.Quit 1
End If
Set buff = CreateObject("ADODB.Stream")
buff.Open
buff.Type = 1
buff.Write req.ResponseBody
buff.Position = 0
buff.SaveToFile target
buff.Close

