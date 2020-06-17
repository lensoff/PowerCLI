$reboot = $true
$i = 1
$count = $hosts.Count
ForEach ( $esx in get-vmhost $hosts | sort ){
	
	Write-Host $i "of" $count -ForegroundColor "Green"
	Write-Host "Host name is" $esx.Name -ForegroundColor "Yellow"
	Write-Host " "
	
	#enter to Maintenance part
	
	$Maintenance = $false
	if ( $esx.ConnectionState -eq 'Connected') {
		Write-Host "Putting the host in Maintenance mode"
		$esx | Set-VMHost -State Maintenance -Evacuate -RunAsync | Out-Null
		$end = $false
		$n = 0
		Do {							
			$ServerState = (get-vmhost $esx).ConnectionState
			if( $ServerState -eq "Maintenance" ){			
				#Write-Host "The host is in Maintenance mode"
				$end = $true
			}
			$n++
			Start-Sleep 15
		} Until ($end -eq $true -or $n -ge 40)
		If ( $n -ge 40 ) {
			Write-Host "Putting the host in Maintenance mode started 10 min ago"
			Read-Host -Prompt "If you sure that the host is in Maintenance mode, Press Enter. Something definitely went wrong"
		}		
	} else {
		Write-Host "The host already was in Maintenance mode"
		$Maintenance = $true
	}
	
	Write-Host "Setup started"
	########
	# start of executable code
	########


	
	########
	# end of executable code
	########
	Write-Host "Setup is over"
	
	#reboot part
	if ( $reboot -eq $true ) {
		Write-Host "Reboot started (" (Get-Date).ToString('HH:mm:ss') ")"
		$esx | Restart-VMhost -RunAsync -Confirm:$false | Out-Null
		
		# Wait for Server to show as down
		Do {
			Start-Sleep 15
			$ServerState = (Get-VMHost $esx).ConnectionState
		}
		Until ($ServerState -eq "NotResponding")
		
		# Wait for Server to boot
		Do {
			Start-Sleep 15
			$ServerState = (Get-VMHost $esx).ConnectionState
		}
		While ($ServerState -ne "NotResponding")
		
		# Wait to server become online
		$end = $false
		$n = 0
		Do {		
			$ServerState = (get-vmhost $esx).ConnectionState
			
			if($ServerState -eq "Maintenance"){
				$end = $true
				Write-Host "Reboot is over (" (Get-Date).ToString('HH:mm:ss') ")"
			}
			$n++
			Start-Sleep 30
			
			If ( $n -ge 30 ) {
				Write-Host "Reboot started 15 min ago"
			}				
			
		}
		Until ($end -eq $true -or $n -ge 40)
		
		If ( $n -ge 40 ) {
			Write-Host "Reboot started 20 min ago"
			Read-Host -Prompt "If you sure that the host is online, Press Enter. Something definitely went wrong"
		}		
	}
	
	#exit from Maintenance part	
	if ( $Maintenance -eq $false) {
		Write-Host "Putting the host in Connected mode"
		$esx | Set-VMHost -State Connected -RunAsync | Out-Null
		$end = $false
		$n = 0
		Do {							
			$ServerState = (get-vmhost $esx).ConnectionState
			if( $ServerState -eq "Connected" ){			
				#Write-Host "The host is in Connected mode"
				$end = $true
			}
			$n++
			Start-Sleep 5
		} Until ($end -eq $true -or $n -ge 60)
		
		If ( $n -ge 60 ) {
			Write-Host "Putting the host in Connected mode started 5 min ago"
			Read-Host -Prompt "If you sure that the host is in Connected mode, Press Enter. Something definitely went wrong"
		}
	} else { Write-Host "No need in Maintenance. The host was in Maintenance mode before the reboot" }
	Write-Host " "
	$i++
}
