$content=get-content sha256
$file="sha256"
$content.replace('SHA2-256(windows-update.exe)= ','') | set-content $file

cp $file ../../sha256
