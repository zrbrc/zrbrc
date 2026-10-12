try {
    throw "error asdfasdf"
}
catch {
    $_.Exception.Message 
}