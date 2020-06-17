ForEach ($esxi in $hosts) {
	Write-Host "$esxi" -ForegroundColor "Yellow"
	Write-Host "Entering Maintenance"
	$esxi | Set-VMHost -State Maintenance -Evacuate -RunAsync | Out-Null

	Do {							
		$ServerState = (get-vmhost $esxi).ConnectionState
		if( $ServerState -eq "Maintenance" ){
			Write-Host "The host is in Maintenance mode"
		}
		Start-Sleep 30
	}
	While ($ServerState -ne "Maintenance")
	
	Write-Host "Starting reboot"
	$esxi | Restart-VMhost -RunAsync -Confirm:$false | Out-Null
	
	# Wait for Server to show as down
	Do {
		Start-Sleep 15
		$ServerState = (Get-VMHost $esxi).ConnectionState
	}
	While ($ServerState -ne "NotResponding")
	$time2 = (Get-Date).ToString('HH:mm:ss')
	Write-Host "$esxi is Down ($time2) `n"
	
	# Цикл проверки успешности перезагрузки хоста	
	Do {		
		$ServerState = (get-vmhost $esxi).ConnectionState
		$timeOnline = (Get-Date).ToString('HH:mm:ss')
		
		if($ServerState -eq "Maintenance"){
			Write-Host "Reboot of $esxi completed ($timeOnline)"
			Write-Host "Exiting Maintenance `n"
			$esxi | Set-VMHost -State Connected -RunAsync | Out-Null		
		}
		Start-Sleep 30
	}
	While ($ServerState -ne "Maintenance")
}

#####################
#	with workflow	#
#####################
$vPass = ""
Workflow Restart-WF {

	Param (
		[Parameter(Mandatory=$true, Position=0)]
		[string[]] $hosts,	
		[Parameter(Mandatory=$true, Position=1)]
		[string] $vCenter,
		[Parameter(Mandatory=$true, Position=2)]
		[string] $User,
		[Parameter(Mandatory=$true, Position=3)]
		[string] $Password
	)	
		
	# Цикл, который будет выполняться параллельно
	foreach -parallel ( $vmhost in $hosts ) {
		# Это скрипт, который видит только свои переменные и те, которые ему переданы через $Using
		InlineScript {
			$a = Connect-VIServer -Server $Using:vCenter -User $Using:User -Password $Using:Password


			$esxi = get-vmhost $Using:vmhost
			$esxi | Set-VMHost -State Maintenance -Evacuate -RunAsync | Out-Null

			Do {							
				$ServerState = (get-vmhost $esxi).ConnectionState
				if( $ServerState -eq "Maintenance" ){
					Write-Host "The host $esxi is in Maintenance mode"
				}
				Start-Sleep 30
			}
			While ($ServerState -ne "Maintenance")
			
			Write-Host "$esxi. Starting reboot"
			$esxi | Restart-VMhost -RunAsync -Confirm:$false | Out-Null
			
			# Wait for Server to show as down
			Do {
				Start-Sleep 15
				$ServerState = (Get-VMHost $esxi).ConnectionState
			}
			While ($ServerState -ne "NotResponding")
			$time2 = (Get-Date).ToString('HH:mm:ss')
			Write-Host "$esxi is Down ($time2) `n"
			
			# Цикл проверки успешности перезагрузки хоста	
			Do {		
				$ServerState = (get-vmhost $esxi).ConnectionState
				$timeOnline = (Get-Date).ToString('HH:mm:ss')
				
				if($ServerState -eq "Maintenance"){
					Write-Host "$esxi. Reboot completed ($timeOnline)"
					#Write-Host "$esxi. Exiting Maintenance `n"
					$esxi | Set-VMHost -State Connected -RunAsync | Out-Null		
				}
				Start-Sleep 30
			}
			While ($ServerState -ne "Maintenance")
			
			
			$a | Disconnect-VIServer -Confirm:$false
		}
	}
}
Restart-WF $hosts $global:DefaultVIServer.Name $global:DefaultVIServer.User $vPass