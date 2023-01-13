<#
  .NOTES
  ===========================================================================
   Created on:   	27.06.2022
   Created by:   	Simon Skotheimsvik
   Filename:     	OfficeIcons-Remediation.ps1
   Instructions:    https://skotheimsvik.no
  ===========================================================================
  
  .DESCRIPTION
    This script will remediate the missing Office
    Based on ideas from the Microsoft EMS Community on Discord, Reddit and Rudy Ooms

#>


# Office Alternative1 - Repair
  # Start-Process "C:\Program Files\Microsoft Office 15\ClientX64\OfficeClickToRun.exe" -ArgumentList "scenario=Repair", "system=x64", "culture=en-us", "RepairType=QuickRepair", "DisplayLevel=False" -Wait 

# Office Alternative2 - Recreate icons the Rudy Ooms way

if(!(Test-Path -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Word.lnk")){  

  if(Test-Path -Path "C:\Program Files\Microsoft Office 15\ClientX64\OfficeClickToRun.exe"){
  
  #Restore Shortcuts to Public desktop
      $ComObj = New-Object -ComObject WScript.Shell
      $ShortCut = $ComObj.CreateShortcut("C:\Users\Public\desktop\Microsoft Excel.lnk")
      $ShortCut.TargetPath = "C:\Program Files\Microsoft Office\root\Office16\EXCEL.EXE"
      $ShortCut.Description = "Excel"
      $ShortCut.FullName 
      $ShortCut.WindowStyle = 1
#      $ShortCut.Save()
  
      $ComObj = New-Object -ComObject WScript.Shell
      $ShortCut = $ComObj.CreateShortcut("C:\Users\Public\desktop\Microsoft Outlook.lnk")
      $ShortCut.TargetPath = "C:\Program Files\Microsoft Office\root\Office16\Outlook.exe"
      $ShortCut.Description = "Outlook"
      $ShortCut.FullName 
      $ShortCut.WindowStyle = 1
#      $ShortCut.Save()
  
      $ComObj = New-Object -ComObject WScript.Shell
      $ShortCut = $ComObj.CreateShortcut("C:\Users\Public\desktop\Microsoft Word.lnk")
      $ShortCut.TargetPath = "C:\Program Files\Microsoft Office\root\Office16\Winword.EXE"
      $ShortCut.Description = "Word"
      $ShortCut.FullName 
      $ShortCut.WindowStyle = 1
#      $ShortCut.Save()
  
      $ComObj = New-Object -ComObject WScript.Shell
      $ShortCut = $ComObj.CreateShortcut("C:\Users\Public\desktop\Microsoft Powerpoint.lnk")
      $ShortCut.TargetPath = "C:\Program Files\Microsoft Office\root\Office16\PowerPNT.exe"
      $ShortCut.Description = "PowerPoint"
      $ShortCut.FullName 
      $ShortCut.WindowStyle = 1
#      $ShortCut.Save()
  
          if(!(Test-Path -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Powerpoint.lnk")){  
       $ComObj = New-Object -ComObject WScript.Shell
          $ShortCut = $ComObj.CreateShortcut("C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Powerpoint.lnk")
          $ShortCut.TargetPath = "C:\Program Files\Microsoft Office\root\Office16\PowerPNT.exe"
          $ShortCut.Description = "PowerPoint"
          $ShortCut.FullName 
          $ShortCut.WindowStyle = 1
          $ShortCut.Save()
      }
  
      if(!(Test-Path -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Word.lnk")){  
       $ComObj = New-Object -ComObject WScript.Shell
          $ShortCut = $ComObj.CreateShortcut("C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Word.lnk")
          $ShortCut.TargetPath = "C:\Program Files\Microsoft Office\root\Office16\Winword.EXE"
          $ShortCut.Description = "Word"
          $ShortCut.FullName 
          $ShortCut.WindowStyle = 1
          $ShortCut.Save()
      }
  
      if(!(Test-Path -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Outlook.lnk")){  
       $ComObj = New-Object -ComObject WScript.Shell
          $ShortCut = $ComObj.CreateShortcut("C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Outlook.lnk")
          $ShortCut.TargetPath = "C:\Program Files\Microsoft Office\root\Office16\Outlook.exe"
          $ShortCut.Description = "Outlook"
          $ShortCut.FullName 
          $ShortCut.WindowStyle = 1
          $ShortCut.Save()
      }
  
      if(!(Test-Path -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Excel.lnk")){  
       $ComObj = New-Object -ComObject WScript.Shell
          $ShortCut = $ComObj.CreateShortcut("C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Excel.lnk")
          $ShortCut.TargetPath = "C:\Program Files\Microsoft Office\root\Office16\EXCEL.EXE"
          $ShortCut.Description = "Excel"
          $ShortCut.FullName 
          $ShortCut.WindowStyle = 1
          $ShortCut.Save()
      }
  
  
  
  } elseif(Test-PAth -Path "C:\Program Files\Microsoft Office 15\ClientX32\OfficeClickToRun.exe"){
  
  #Restore Shortcuts to Public desktop
      $ComObj = New-Object -ComObject WScript.Shell
      $ShortCut = $ComObj.CreateShortcut("C:\Users\Public\desktop\Microsoft Excel.lnk")
      $ShortCut.TargetPath = "C:\Program Files (x86)\Microsoft Office\root\Office16\EXCEL.EXE"
      $ShortCut.Description = "Excel"
      $ShortCut.FullName 
      $ShortCut.WindowStyle = 1
 #     $ShortCut.Save()
 
      $ComObj = New-Object -ComObject WScript.Shell
      $ShortCut = $ComObj.CreateShortcut("C:\Users\Public\desktop\Microsoft Outlook.lnk")
      $ShortCut.TargetPath = "C:\Program Files (x86)\Microsoft Office\root\Office16\Outlook.exe"
      $ShortCut.Description = "Outlook"
      $ShortCut.FullName 
      $ShortCut.WindowStyle = 1
 #     $ShortCut.Save()
 
      $ComObj = New-Object -ComObject WScript.Shell
      $ShortCut = $ComObj.CreateShortcut("C:\Users\Public\desktop\Microsoft Word.lnk")
      $ShortCut.TargetPath = "C:\Program Files (x86)\Microsoft Office\root\Office16\Winword.EXE"
      $ShortCut.Description = "Word"
      $ShortCut.FullName 
      $ShortCut.WindowStyle = 1
      #$ShortCut.Save()
      
      $ComObj = New-Object -ComObject WScript.Shell
      $ShortCut = $ComObj.CreateShortcut("C:\Users\Public\desktop\Microsoft Powerpoint.lnk")
      $ShortCut.TargetPath = "C:\Program Files (x86)\Microsoft Office\root\Office16\PowerPNT.exe"
      $ShortCut.Description = "PowerPoint"
      $ShortCut.FullName 
      $ShortCut.WindowStyle = 1
      #$ShortCut.Save()
      
      if(!(Test-Path -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Powerpoint.lnk")){  
          $ComObj = New-Object -ComObject WScript.Shell
          $ShortCut = $ComObj.CreateShortcut("C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Powerpoint.lnk")
          $ShortCut.TargetPath = "C:\Program Files (x86)\Microsoft Office\root\Office16\PowerPNT.exe"
          $ShortCut.Description = "PowerPoint"
          $ShortCut.FullName 
          $ShortCut.WindowStyle = 1
          $ShortCut.Save()
      }
  
      if(!(Test-Path -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Word.lnk")){  
       $ComObj = New-Object -ComObject WScript.Shell
          $ShortCut = $ComObj.CreateShortcut("C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Word.lnk")
          $ShortCut.TargetPath = "C:\Program Files (x86)\Microsoft Office\root\Office16\Winword.EXE"
          $ShortCut.Description = "Word"
          $ShortCut.FullName 
          $ShortCut.WindowStyle = 1
          $ShortCut.Save()
      }
  
      if(!(Test-Path -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Outlook.lnk")){  
       $ComObj = New-Object -ComObject WScript.Shell
          $ShortCut = $ComObj.CreateShortcut("C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Outlook.lnk")
          $ShortCut.TargetPath = "C:\Program Files (x86)\Microsoft Office\root\Office16\Outlook.exe"
          $ShortCut.Description = "Outlook"
          $ShortCut.FullName 
          $ShortCut.WindowStyle = 1
          $ShortCut.Save()
      }
  
      if(!(Test-Path -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Excel.lnk")){  
       $ComObj = New-Object -ComObject WScript.Shell
          $ShortCut = $ComObj.CreateShortcut("C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Excel.lnk")
          $ShortCut.TargetPath = "C:\Program Files (x86)\Microsoft Office\root\Office16\EXCEL.EXE"
          $ShortCut.Description = "Excel"
          $ShortCut.FullName 
          $ShortCut.WindowStyle = 1
          $ShortCut.Save()
      }
  
    
  }
  }else{ 
  write-host "nothing to repair"}
  
  #Restore Other Shortcuts to Public desktop
  
  if(!(Test-Path -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk")){  
   $ComObj = New-Object -ComObject WScript.Shell
      $ShortCut = $ComObj.CreateShortcut("C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk")
      $ShortCut.TargetPath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
      $ShortCut.Description = "Edge"
      $ShortCut.FullName 
      $ShortCut.WindowStyle = 1
      $ShortCut.Save()
  
      $ComObj = New-Object -ComObject WScript.Shell
      $ShortCut = $ComObj.CreateShortcut("C:\Users\Public\desktop\Microsoft Edge.lnk")
      $ShortCut.TargetPath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
      $ShortCut.Description = "Edge"
      $ShortCut.FullName 
      $ShortCut.WindowStyle = 1
#      $ShortCut.Save()
  }
  

  $StartMenuFolder = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs"
  $Count = (Get-ChildItem $StartMenuFolder | ? Name -match "Word|Outlook|Powerpoint|Excel").count
  
  if ($count -ge 4) { 
    "Installed" 
    $exitCode = 0
  }
  
  else {
    $exitCode = -1
  }


exit $exitCode