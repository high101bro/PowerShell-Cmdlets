param(
    [string]$Path = ".\",
    [switch]$Recurse,
    [switch]$UrlHttpHttps,
    [switch]$Url,
    [switch]$IP,
    [switch]$PhoneAlphaNumeric,
    [switch]$PhoneNumber,
    [switch]$Social,
    [switch]$SocialStrict,
    [switch]$Credit,
    [switch]$Email,
    [switch]$EmailStrict,
    [Switch]$All,
    [Switch]$AllNotStrict,
    [Switch]$AllStrict
)
$files = Get-ChildItem -Path $Path | Where-Object { -Not $_.PsIsContainer}
foreach($file in $files){
    $FileContent = Get-Content -Path $file.fullname

    if($UrlHttpHttps -or $All -or $AllStrict) {
        $Search = $FileContent | Select-String -Pattern "https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)" -AllMatches
	    if ($Search){
            Write-Host "URL [Strict] found in the following file:" -f Cyan
	        Write-Host "`t$($file.fullname)" -f yellow
            Foreach ($Match in $Search.Matches) {
		        Write-Host -ForegroundColor Green "`t$Match"
	        }
        }
    }
    if($Url -or $All -or $AllNotStrict) {
        $Search = $FileContent | Select-String -Pattern "[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)" -AllMatches
	    if ($Search){
            Write-Host "URL [Not Strict] found in the following file:" -f Cyan
	        Write-Host "`t$($file.fullname)" -f yellow
            Foreach ($Match in $Search.Matches) {
		        Write-Host -ForegroundColor Green "`t$Match"
	        }
        }
    }
    if($IP -or $All -or $AllStrict) {
        $Search = $FileContent | Select-String -Pattern "(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)" -AllMatches
	    if ($Search){
            Write-Host "IP Address [Strict] found in the following file:" -f Cyan
	        Write-Host "`t$($file.fullname)" -f yellow
            Foreach ($Match in $Search.Matches) {
		        Write-Host -ForegroundColor Green "`t$Match"
	        }
        }
    }
    if($PhoneAlphaNumeric -or $All -or $AllNotStrict) {
        $Search = $FileContent | Select-String -Pattern "([0-9]( |-)?)?(\(?[0-9]{3}\)?|[0-9]{3})( |-)?([0-9]{3}( |-)?[0-9]{4}|[a-zA-Z0-9]{7})"  -AllMatches
	    if ($Search){
            Write-Host "Phone Number [Not Strict] found in the following file:" -f Cyan
	        Write-Host "`t$($file.fullname)" -f yellow
            Foreach ($Match in $Search.Matches) {
		        Write-Host -ForegroundColor Green "`t$Match"
	        }
        }
    }
    if($PhoneNumber -or $All -or $AllStrict) {
        $Search = $FileContent | Select-String -Pattern "((\(\d{3}\)?)|(\d{3}))([\s-./]?)(\d{3})([\s-./]?)(\d{4})" -AllMatches
	    if ($Search){
            Write-Host "Phone Number [Strict] found in the following file:" -f Cyan
	        Write-Host "`t$($file.fullname)" -f yellow
            Foreach ($Match in $Search.Matches) {
		        Write-Host -ForegroundColor Green "`t$Match"
	        }
        }
    }
    if($Social -or $All -or $AllNotStrict) {
        $Search = $FileContent | Select-String -Pattern "(?!000)(?!666)(?!9)\d{3}([- ]?)(?!00)\d{2}\1(?!0000)\d{4}" -AllMatches
	    if ($Search){
            Write-Host "SSN [Not Strict] found in the following file:" -f Cyan
	        Write-Host "`t$($file.fullname)" -f yellow
            Foreach ($Match in $Search.Matches) {
		        Write-Host -ForegroundColor Green "`t$Match"
	        }
        }
    }
    if($SocialStrict -or $All -or $AllStrict) {
        $Search = $FileContent | Select-String -Pattern "\d{3}-\d{2}-\d{4}" -AllMatches
	    if ($Search){
            Write-Host "SSN [Strict] found in the following file:" -f Cyan
	        Write-Host "`t$($file.fullname)" -f yellow
            Foreach ($Match in $Search.Matches) {
		        Write-Host -ForegroundColor Green "`t$Match"
	        }
        }
    }
    if($Credit -or $All -or $AllStrict) {
        $Search = $FileContent | Select-String -Pattern "\d{4}\s\d{4}\s\d{4}\s\d{4}" -AllMatches
	    if ($Search){
            Write-Host "Credit Card Number [Strict] found in the following file:" -f Cyan
	        Write-Host "`t$($file.fullname)" -f yellow
            Foreach ($Match in $Search.Matches) {
		        Write-Host -ForegroundColor Green "`t$Match"
	        }
        }
    }
        
    if($Email -or $All -or $AllNotStrict)  {
        $Search = $FileContent | Select-String -Pattern "[\w-]+@([\w-]+\.)+[\w-]+“ -AllMatches
        if ($Search) {
            Write-Host "Email [Not Strict] found in the following file:" -f Cyan
	        Write-Host "`t$($file.fullname)" -f yellow
            Foreach ($Match in $Search.Matches) {
		        Write-Host -ForegroundColor Green "`t$Match"
	        }
        }
    }  
    if($EmailStrict -or $All -or $AllStrict)  {
        $Search = $FileContent | Select-String -Pattern "([a-zA-Z0-9_\-\.]+)@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.)|(([a-zA-Z0-9\-]+\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})(\]?)“ -AllMatches
        if ($Search) {
            Write-Host "Email [Strict] found in the following file:" -f Cyan
	        Write-Host "`t$($file.fullname)" -f yellow
            Foreach ($Match in $Search.Matches) {
		        Write-Host -ForegroundColor Green "`t$Match"
	        }
        }
    }  
}
 

