$src = 'C:\Temp\robocopy\src'
$dst =  'C:\Temp\robocopy\dst'
$file = ''
$opt = '/v /njh'

robocopy $src $dst $file $opt.Split(' ')

$LASTEXITCODE