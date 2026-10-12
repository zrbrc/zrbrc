[String]::IsNullOrEmpty() - test if string is null or empty

[String]::IsNullOrWhiteSpace() - test if string is null or whitespace

[IO.Path]::Combine()- joining paths (faster that Join-Path)

[IO.Directory]::Exists() - because Test-Path fails on UNC paths sometimes

[DateTime]::Now - faster than Get-Date

[Uri]::IsWellFormedUriString() - validate format of Uri strings

[Web.Security.Membership]::GeneratePassword() - quick way to generate passwords