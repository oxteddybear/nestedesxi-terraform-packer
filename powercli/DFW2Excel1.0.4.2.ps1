<#
Copyright © 2017 VMware, Inc. All Rights Reserved. 
SPDX-License-Identifier: MIT
NSX Power Operations
Copyright 2017 VMware, Inc.  All rights reserved				
The MIT license (the ìLicenseî) set forth below applies to all parts of the NSX Power Operations project.  You may not use this file except in compliance with the License.†
MIT License
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), 
to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#>

# Author:   Tony Sangha
# Blog:    tonysangha.com
# Version:  1.0.3
# PowerCLI v6.0
# PowerNSX v3.0
# Purpose: Document NSX for vSphere Distributed Firewall

param (
    [switch]$EnableIpDetection,
    [switch]$GetSecTagMembers,
    [switch]$GetSecGrpMembers,
    [switch]$StartMinimised,
    [string]$DocumentPath
)
# Empty Hash-tables for use with Hyperlinks
$services_ht = @{}
$vmaddressing_ht = @{}
$ipsets_ht = @{}
$secgrp_ht = @{}


# keep all the servicegroups in servicegroups here

########################################################
# Cleanup Excel application object
# We Need to call this for EVERY VARIABLE that references
# an excel object.  __EVERY VARIABLE__
########################################################
function ReleaseObject {
    param (
        $Obj
    )

    Try {
        $intRel = 0
        Do { 
            $intRel = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($Obj)
        } While ($intRel -gt  0)
    }
    Catch {
        throw "Error releasing object: $_"
    }
    Finally {
        [System.GC]::Collect()
       
    }
}

########################################################
# Cleanup Excel application object
# We Need to call this for EVERY VARIABLE that references
# an excel object.  __EVERY VARIABLE__
########################################################
function ReleaseObject {
    param (
        $Obj
    )

    Try {
        $intRel = 0
        Do { 
            $intRel = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($Obj)
        } While ($intRel -gt  0)
    }
    Catch {
        throw "Error releasing object: $_"
    }
    Finally {
        [System.GC]::Collect()
       
    }
}

########################################################
#  Formatting/Functions Options for Excel Spreadsheet
########################################################

    $titleFontSize = 18
    $titleFontBold = $True
    $titleFontColorIndex = 2
    $titleFontName = "Calibri (Body)"
    $titleInteriorColor = 10

    $subTitleFontSize = 10.5
    $subTitleFontBold = $True
    $subTitleFontName = "Calibri (Body)"
    $subTitleInteriorColor = 43

    $valueFontName = "Calibri (Body)"
    $valueFontSize = 10.5
    $valueMissingColorIndex =
    $valueMissingText = "<BLANK>"
    $valueMissingHighlight = 6
    $valueNotApplicable = "<NOT APPLICABLE>"
    $valueNotDefined = "<NOT DEFINED>"

########################################################
#    Global Parameters
########################################################

$null = New-VIProperty -Name VMIPAddress -ObjectType VirtualMachine `
    -ValueFromExtensionProperty 'Summary.Guest.IPAddress' `
    -Force

########################################################
#    Define Excel Workbook and calls to different WS
########################################################
function startExcel(){

    $Excel = New-Object -Com Excel.Application
    if ( -not $StartMinimised ) { 
        $Excel.visible = $True
    }
    $Excel.DisplayAlerts = $false
    $wb = $Excel.Workbooks.Add()

    if ($args[0] -eq "y"){

        Write-Host "`nRetrieving IP Addresses for ALL Virtual Machines in vCenter environment." -foregroundcolor "magenta"
        Write-Host "*** This may take a while ***." -foregroundcolor "Yellow"
        $ws0 = $wb.WorkSheets.Add()
        $ws0.Name = "VM_Info"
        vm_ip_addresses_ws($ws0)
        $usedRange = $ws0.UsedRange
        $null = $usedRange.EntireColumn.Autofit()
        ReleaseObject -Obj $ws0
    }

    Write-Host "`nRetrieving Services configured in NSX-v." -foregroundcolor "magenta"
    $ws1 = $wb.WorkSheets.Add()
    $ws1.Name = "ALL Services"
    services_ws($ws1)
    $usedRange = $ws1.UsedRange
    $null = $usedRange.EntireColumn.Autofit()

    Write-Host "`nRetrieving Service Groups configured in NSX-v." -foregroundcolor "magenta"
    $ws2 = $wb.WorkSheets.Add()
    $ws2.Name = "ALL Service_Groups"
    service_groups_ws($ws2)
    $usedRange = $ws2.UsedRange
    $null = $usedRange.EntireColumn.Autofit()

    Write-Host "`nRetrieving MACSETS configured in NSX-v." -foregroundcolor "magenta"
    $ws3 = $wb.WorkSheets.Add()
    $ws3.Name = "MACSETS"
    macset_ws($ws3)
    $usedRange = $ws3.UsedRange
    $null = $usedRange.EntireColumn.Autofit()

    Write-Host "`nRetrieving IPSETS configured in NSX-v." -foregroundcolor "magenta"
    $ws4 = $wb.WorkSheets.Add()
    $ws4.Name = "IPSETS"
    ipset_ws($ws4)
    $usedRange = $ws4.UsedRange
    $null = $usedRange.EntireColumn.Autofit()

    Write-Host "`nRetrieving Security Groups configured in NSX-v." -foregroundcolor "magenta"
    $ws5 = $wb.WorkSheets.Add()
    $ws5.Name = "Security Group Configuration"
    sg_ws($ws5)
    $usedRange = $ws5.UsedRange
    $null = $usedRange.EntireColumn.Autofit()

    Write-Host "`nRetrieving Security Groups Effective Membership in NSX-v." -foregroundcolor "magenta"
    $ws_sg_vm_mem = $wb.WorkSheets.Add()
    $ws_sg_vm_mem.Name = "Security Group Effective Member"
    sg_resultant_membership($ws_sg_vm_mem)
    $usedRange = $ws_sg_vm_mem.UsedRange
    $null = $usedRange.EntireColumn.Autofit()    

    Write-Host "`nRetrieving Security Tags configured in NSX-v." -foregroundcolor "magenta"
    $ws6 = $wb.Worksheets.Add()
    $ws6.Name = "Security_Tags"
    sec_tags_ws($ws6)
    $usedRange = $ws6.UsedRange
    $null = $usedRange.EntireColumn.Autofit()

    Write-Host "`nRetrieving VMs in DFW Exclusion List" -foregroundcolor "magenta"
    $ws7 = $wb.Worksheets.Add()
    $ws7.Name = "DFW Exclusion list"
    ex_list_ws($ws7)
    $usedRange = $ws7.UsedRange
    $null = $usedRange.EntireColumn.Autofit()

    Write-Host "`nRetrieving DFW Redirect FW Rules" -foregroundcolor "magenta"
    $ws8 = $wb.Worksheets.Add()
    $ws8.Name = "Redirection Firewall Rules"
    dfw_ws -sheet $ws8 -fw_type 'redirect'
    $usedRange = $ws8.UsedRange
    $null = $usedRange.EntireColumn.Autofit()

    Write-Host "`nRetrieving DFW Layer 2 FW Rules" -foregroundcolor "magenta"
    $ws9 = $wb.Worksheets.Add()
    $ws9.Name = "Layer 2 Firewall Rules"
    dfw_ws -sheet $ws9 -fw_type 'layer2'
    $usedRange = $ws9.UsedRange
    $null = $usedRange.EntireColumn.Autofit()

    Write-Host "`nRetrieving DFW Layer 3 FW Rules" -foregroundcolor "magenta"
    $ws10 = $wb.Worksheets.Add()
    $ws10.Name = "Layer 3 Firewall Rules"
    dfw_ws -sheet $ws10 -fw_type 'layer3'
    $usedRange = $ws10.UsedRange
    $null = $usedRange.EntireColumn.Autofit()

    Write-Host "`nRetrieving Environment Summary" -foregroundcolor "magenta"
    $ws11 = $wb.Worksheets.Add()
    $ws11.Name = "Environment Summary"
    env_ws($ws11)
    $usedRange = $ws11.UsedRange
    $null = $usedRange.EntireColumn.Autofit()


    ##figure out which of the services were actually used in the rules
    $ws12 = $wb.Worksheets.Add()
    $ws12.Name = "Services usedby rules"
    Services_ws($ws12)
    $usedRange = $ws12.UsedRange
    $null = $usedRange.EntireColumn.Autofit()

    ##figure out which of the services groups were used in the rules
    $ws13 = $wb.WorkSheets.Add()
    $ws13.Name = "ServiceGroup usedby rules"
    service_groups_ws($ws13)
    $usedRange = $ws13.UsedRange
    $null = $usedRange.EntireColumn.Autofit()

    #list out the definations of the services defined in those service groups used in the rules
    $ws14 = $wb.WorkSheets.Add()
    $ws14.Name = "Services in Svcgrp usedbyrule"
    services_ws($ws14)
    $usedRange = $ws14.UsedRange
    $null = $usedRange.EntireColumn.Autofit()
#list the services members found from Service groups within service groups
    $ws15 = $wb.WorkSheets.Add()
    $ws15.Name = "SVCGrp usedin SvcGrp "
    service_groups_ws($ws15)
    $usedRange = $ws15.UsedRange
    $null = $usedRange.EntireColumn.Autofit()
#list security groups in nsxv
    Write-Host "`nRetrieving Security Groups configured in NSX-v." -foregroundcolor "magenta"
    $ws16 = $wb.WorkSheets.Add()
    $ws16.Name = "Security Group Configuration2"
    sg_ws($ws16)
    $usedRange = $ws16.UsedRange
    $null = $usedRange.EntireColumn.Autofit()
    # Must cleanup manually or excel process wont quit.
    ReleaseObject -Obj $ws1    
    ReleaseObject -Obj $ws2
    ReleaseObject -Obj $ws3    
    ReleaseObject -Obj $ws4    
    ReleaseObject -Obj $ws5    
    ReleaseObject -Obj $ws6    
    ReleaseObject -Obj $ws7
    ReleaseObject -Obj $ws8    
    ReleaseObject -Obj $ws9   
    ReleaseObject -Obj $ws10 
    ReleaseObject -Obj $ws11
    ReleaseObject -Obj $ws12 # "Services used in DFWrules"
    ReleaseObject -Obj $ws13 # "Servicegroups used in DFWrules"
    ReleaseObject -Obj $ws14 # "memberservices of svcgrp used in rules"
    ReleaseObject -Obj $ws15 # "memberservices of svcgrp in svcgrp used in rules"
    ReleaseObject -Obj $ws16 # "memberservices of svcgrp in svcgrp used in rules"


    ReleaseObject -Obj $ws_sg_vm_mem
    ReleaseObject -Obj $usedRange
    
    if ( $DocumentPath -and (test-path (split-path -parent $DocumentPath))) { 
        $wb.SaveAs($DocumentPath)
        $wb.close(0)
        $Excel.Quit()
        ReleaseObject -Obj $Excel
        ReleaseObject -Obj $wb
        
    }

}

########################################################
#    Firewall Worksheet for L2/L3 & Redirect Types
########################################################

function dfw_ws(){

    param (
        [Parameter (Mandatory=$true)]
            [Object]$sheet,
        [Parameter (Mandatory=$true)]
            [string]$fw_type
    )

    $sheet.Cells.Item(1,1) = "Firewall Configuration"
    $sheet.Cells.Item(1,1).Font.Size = $titleFontSize
    $sheet.Cells.Item(1,1).Font.Bold = $titleFontBold
    $sheet.Cells.Item(1,1).Font.ColorIndex = $titleFontColorIndex
    $sheet.Cells.Item(1,1).Font.Name = $titleFontName
    $sheet.Cells.Item(1,1).Interior.ColorIndex = $titleInteriorColor
    $range1 = $sheet.Range("a1", "s1")
    $range1.merge() | Out-Null

    fw_rules -sheet $sheet -fw_type $fw_type
}

function fw_rules(){

    param (
        [Parameter (Mandatory=$true)]
            [Object]$sheet,
        [Parameter (Mandatory=$true)]
            [string]$fw_type
    )

    if ( $fw_type -eq 'redirect' ) {
        $sheet.Cells.Item(2,1) = "Redirection Rules"
        $fw_sections = Get-NSXFirewallSection -sectionType 'layer3redirectsections'
    }
    elseif ( $fw_type -eq 'layer2' ) {
        $sheet.Cells.Item(2,1) = "Layer 2 FW Rules"
        $fw_sections = Get-NSXFirewallSection -sectionType 'layer2sections'
    }
    else {
        $sheet.Cells.Item(2,1) = "Layer 3 FW Rules"
        $fw_sections = Get-NSXFirewallSection -sectionType 'layer3sections'
    }

    $sheet.Cells.Item(2,1).Font.Bold = $titleFontBold
    $sheet.Cells.Item(2,1).Font.ColorIndex = $titleFontColorIndex
    $sheet.Cells.Item(2,1).Font.Name = $titleFontName
    $sheet.Cells.Item(2,1).Interior.ColorIndex = $titleInteriorColor
    $range1 = $sheet.Range("a2", "s2")

    
    $sheet.Cells.Item(3,1) = "S/N"
    $sheet.Cells.Item(3,2) = "Rule Name (Description)"
    $sheet.Cells.Item(3,3) = "Source Type"
    $sheet.Cells.Item(3,4) = "Source"
    $sheet.Cells.Item(3,5) = "Destination Type"
    $sheet.Cells.Item(3,6) = "Destination"
    $sheet.Cells.Item(3,7) = "Service type"
    $sheet.Cells.Item(3,8) = "Service"
    $sheet.Cells.Item(3,9) = "Action"

    $sheet.Cells.Item(3,10) = "Log"
    $sheet.Cells.Item(3,11) = "Category"
    $sheet.Cells.Item(3,12) = "Section"
    $sheet.Cells.Item(3,13) = "Apply-To"
    $sheet.Cells.Item(3,14) = "Status"
    $sheet.Cells.Item(3,15) = "SectionID"
    $sheet.Cells.Item(3,16) = "RuleID"
    $sheet.Cells.Item(3,17) = "Source Negated"
    $sheet.Cells.Item(3,18) = "Destination Negated"
    #$sheet.Cells.Item(3,19) = 
    #$sheet.Cells.Item(3,20) = 
    #$sheet.Cells.Item(3,21) = 
    #$sheet.Cells.Item(3,22) = 
    #$sheet.Cells.Item(3,23) =
    

    $range2 = $sheet.Range("a3", "s3")
    $range2.Font.Bold = $subTitleFontBold
    $range2.Interior.ColorIndex = $subTitleInteriorColor
    $range2.Font.Name = $subTitleFontName

    # Moved further up the function to if block
    # $fw_sections = Get-NSXFirewallSection

    $row = 4
    
    foreach($section in $fw_sections){
        $sheet.Cells.Item($row,12) = $section.name
        $sheet.Cells.Item($row,12).Font.Bold = $true
        $sheet.Cells.Item($row,15) = $section.id
        $sheet.Cells.Item($row,15).Font.Bold = $true

        # Only go through rules if a section actually contains rules
        if (Get-Member -InputObject $section -Name 'rule' -MemberType Properties)
        {
            foreach($rule in $section.rule){

                if($rule.disabled -eq "false"){
                    $sheet.Cells.Item($row,14) = "Enabled"
                } else {
                    $sheet.Cells.Item($row,14) = "Disabled"
                }
                if ($rule.name -eq "rule"){
                    $sheet.Cells.Item($row,2) = $valueNotDefined
                    } else {
                        $sheet.Cells.Item($row,2) = $rule.name
                        $sheet.Cells.Item($row,2).Font.Bold = $true
                    }
                $sheet.Cells.Item($row,16) = $rule.id
                $sheet.Cells.Item($row,16).Font.Bold = $true

                # Highlight Allow/Deny statements
                if($rule.action -eq "deny"){
                    $sheet.Cells.Item($row,9) = $rule.action
                    $sheet.Cells.Item($row,9).Font.ColorIndex = 3
                } elseif($rule.action -eq "allow"){
                    $sheet.Cells.Item($row,9) = $rule.action
                    $sheet.Cells.Item($row,9).Font.ColorIndex = 4
                } elseif($rule.action -eq "redirect"){
                    $sheet.Cells.Item($row,9) = $rule.action
                    $sheet.Cells.Item($row,9).Font.ColorIndex = 5
                }

      #         $sheet.Cells.Item($row,16) = $rule.direction
      #         $sheet.Cells.Item($row,17) = $rule.packetType
                $sheet.Cells.Item($row,10) = $rule.logged

                ###### Sources Section ######
                $srcRow = $row
                
                # If Source does not exist, it must be set to ANY
                if (!$rule.sources){
                    $sheet.Cells.Item($srcRow,4) = "ANY"
                    $sheet.Cells.Item($srcRow,4).Font.ColorIndex = 45
                } else {
                    #If Negated field exists, document
                    if ($rule.sources.excluded -eq "True" ){
                        $sheet.Cells.Item($srcRow,17) = "True"
                        $sheet.Cells.Item($row,17).Font.ColorIndex = 3
                    }
$_srcothers = ""
$_srcipv4 = ""
$_srcipv6 = ""
$_srcipset = ""
$_srcsg = ""
$_srcvm = ""

                    foreach($source in $rule.sources.source){
                        
                        

                        if($source.type -eq "Ipv4Address"){
                            $_srcipv4 = $_srcipv4 + $source.value + ","
                           #Write-Host "source.value = " $source.value
                           #Write-Host "_scr.value = " $source.name
                        } 
                        elseif($source.type -eq "Ipv6Address") {
                            $_srcipv6 = $_srcipv6 + $source.value + ","
                        } 
                        elseif ($source.type -eq "IPSet") {
                            $_srcipset = $_srcipset + $source.name + ","
                        }
                        elseif ($source.type -eq "SecurityGroup") {
                            $_srcsg = $_srcsg + $source.name + ","
                        }
                        elseif ($source.type -eq "VirtualMachine") {
                            $_srcvm = $_srcvm + $source.name + ","
                        }
                        else {
                            $_srcothers = $_srcothers + $source.name + ","
                            #write-host "othersname="$source.name
                            #write-host "othersvalue="$source.value

                        }

                    
                    }
                    if ($_srcipv4  -ne "") {
                    $sheet.Cells.Item($srcRow,3) = "IPV4"
                    $sheet.Cells.Item($srcRow,4) = $_srcipv4.Substring(0,$_srcipv4.Length-1)
                    $srcRow++
                    }
                     
                    if ($_srcipv6  -ne "") {
                    $sheet.Cells.Item($srcRow,3) = "IPV6"
                    $sheet.Cells.Item($srcRow,4) = $_srcipv6.Substring(0,$_srcipv6.Length-1)
                    $srcRow++
                    
                    }
                    if ($_srcipset  -ne "") {

                    $sheet.Cells.Item($srcRow,3) = "IPSET"
                    $sheet.Cells.Item($srcRow,4) = $_srcipset.Substring(0,$_srcipset.Length-1)                    
                    $srcRow++                    
                    }
                    if ($_srcsg  -ne "") {

                    $sheet.Cells.Item($srcRow,3) = "SG"
                    $sheet.Cells.Item($srcRow,4) = $_srcsg.Substring(0,$_srcsg.Length-1)
                    $srcRow++                    
                    }
                    if ($_srcvm  -ne "") {
                    $sheet.Cells.Item($srcRow,3) = "VM"
                    $sheet.Cells.Item($srcRow,4) = $_srcvm.Substring(0,$_srcvm.Length-1)
                    $srcRow++
                    }
                    if ($_srcothers  -ne "") {
                    $sheet.Cells.Item($srcRow,3) = "others"
                    $sheet.Cells.Item($srcRow,4) = $_srcothers.Substring(0,$_srcothers.Length-1)
                    $srcRow++
                    }


$_srcothers = ""
$_srcipv4 = ""
$_srcipv6 = ""
$_srcipset = ""
$_srcsg = ""
$_srcvm = ""
                }

                ###### Destination Section ######
                $dstRow = $row

                # If Destination does not exist, it must be set to ANY
                if (!$rule.destinations){
                    $sheet.Cells.Item($dstRow,6) = "ANY"
                    $sheet.Cells.Item($dstRow,6).Font.ColorIndex = 45
                } else {

                    #If Negated field exists, document
                    if ($rule.destinations.excluded -eq "True" ){
                        $sheet.Cells.Item($srcRow,18) = "TRUE"
                        $sheet.Cells.Item($row,18).Font.ColorIndex = 3
                    }

$_dstothers = ""
$_dstipv4 = ""
$_dstipv6 = ""
$_dstipset = ""
$_dstsg = ""
$_dstvm = ""


                    foreach($destination in $rule.destinations.destination){
                       # $sheet.Cells.Item($dstRow,11) = $destination.type
                        if($destination.type -eq "Ipv4Address"){
                               $_dstipv4 = $_dstipv4 + $destination.value + ","
                            } 
                        elseif($destination.type -eq "Ipv6Address") {
                                $_dstipv6 = $_dstipv6 + $destination.value + ","
                            } 
                        elseif ($destination.type -eq "IPSet") {
                                $_dstipset = $_dstipset + $destination.name + ","
                        }
                        elseif ($destination.type -eq "VirtualMachine") {
                                $_dstvm = $_dstvm + $destination.name + ","
                        }
                        elseif ($destination.type -eq "SecurityGroup") {
                                $_dstsg = $_dstsg + $destination.name + ","
                        }                     
                        else {
                                $_dstothers = $_dstothers + $destination.name + ","
                        
                            }
                        #$dstRow++
                    }
                    if ($_dstipv4  -ne "") {
                    $sheet.Cells.Item($dstRow,5) = "IPV4"
                    $sheet.Cells.Item($dstRow,6) = $_dstipv4.Substring(0,$_dstipv4.Length-1)
                    $dstRow++
                    }
                     
                    if ($_dstipv6  -ne "") {
                    $sheet.Cells.Item($dstRow,5) = "IPV6"
                    $sheet.Cells.Item($dstRow,6) = $_dstipv6.Substring(0,$_dstipv6.Length-1)
                    $dstRow++
                    
                    }
                    if ($_dstipset  -ne "") {

                    $sheet.Cells.Item($dstRow,5) = "IPSET"
                    $sheet.Cells.Item($dstRow,6) = $_dstipset.Substring(0,$_dstipset.Length-1)
                    $dstRow++                    
                    }
                    if ($_dstsg  -ne "") {

                    $sheet.Cells.Item($dstRow,5) = "SG"
                    $sheet.Cells.Item($dstRow,6) = $_dstsg.Substring(0,$_dstsg.Length-1)
                    $dstRow++                    
                    }
                    if ($_dstvm  -ne "") {
                    $sheet.Cells.Item($dstRow,5) = "VM"
                    $sheet.Cells.Item($dstRow,6) = $_dstvm.Substring(0,$_dstvm.Length-1)
                    $dstRow++
                    }
                    if ($_dstothers  -ne "") {
                    $sheet.Cells.Item($dstRow,5) = "others"
                    $sheet.Cells.Item($dstRow,6) = $_dstothers.Substring(0,$_dstothers.Length-1)
                    #write-host "_dstothers="$_dstothers
                    $dstRow++
                    }
                   # if ($_dstothers  -eq "") {
                   # write-host "_dstothers=zero="$_dstothers }


$_dstothers = ""
$_dstipv4 = ""
$_dstipv6 = ""
$_dstipset = ""
$_dstsg = ""
$_dstvm = ""
                }

                ###### Services Section ######
                $svcRow = $row




                # If Service does not exist, it must be set to ANY
                if(!$rule.services){
                    $sheet.Cells.Item($svcRow,8) = "ANY"
                    $sheet.Cells.Item($svcRow,8).Font.ColorIndex = 45
                } else {


$_svcraw = ""
$_svcname = ""
$_svcgrp = ""

                    foreach($service in $rule.services.service){
                        if($service.protocolName) #if there's raw protocol definations then do this block
                        {
                            if ($service.protocolName -eq "ICMP"){ #icmp has to be treated differently as it has no concept of ports
                                Write-Host "ICMP_sub="$service.subProtocolName
                                $_svcraw = $_svcraw + $service.protocolName + "(subprot="+$service.subProtocolName +"),"
                            }
                            else {
                                
                                $_svcraw = $_svcraw + $service.protocolName + "( srcport="+$service.sourcePort +" destport="+$service.destinationPort + " )" + ","
                                #Write-Host "$_svcraw=" + $_svcraw
                                 }
                        }
                        else {
                            if ($service.type -eq "ApplicationGroup") {
                                $_svcgrp = $_svcgrp + $service.name + ","
                            } else {
                                $_svcname = $_svcname + $service.name +","   
                            }

                             
                             #Write-Host "$_svcname="$_svcname
                        }
                        
                    }
                    
                    if ($_svcraw  -ne "") {
                    
                     $sheet.Cells.Item($svcRow,7) = "RulecontainsRawDefinations"
                     $sheet.Cells.Item($svcRow,8) = $_svcraw.Substring(0,$_svcraw.Length-1)
                     $svcRow++
                    }

                    if ($_svcname  -ne "") {
                    
                     $sheet.Cells.Item($svcRow,7) = "Services"
                    #  $sheet.Cells.Item($svcRow,7) = "services/servicegroup"
                     $sheet.Cells.Item($svcRow,8) = $_svcname.Substring(0,$_svcname.Length-1)
                     $svcRow++
                    }
            

                    if ($_svcgrp  -ne "") {
                    
                        $sheet.Cells.Item($svcRow,7) = "Servicegroup"
                        $sheet.Cells.Item($svcRow,8) = $_svcgrp.Substring(0,$_svcgrp.Length-1)
                        $svcRow++
                       }                    
   
$_svcraw=""
$_svcname=""
$_svcgrp = ""
                }

                ###### AppliedTo ######
                $appRow = $row

                foreach($appliedTo in $rule.appliedToList.appliedTo){
                    $sheet.Cells.Item($appRow,13) = $appliedTo.name
                    $appRow++
                }
                $row = ($srcRow,$dstRow,$svcRow,$appRow | Measure-Object -Maximum).Maximum
            }
        }
        $row++
        $sheet.Cells.Item($row,1).Interior.ColorIndex = $titleInteriorColor
        $range1 = $sheet.Range("a"+$row, "s"+$row)
        $range1.merge() | Out-Null
        $row++

    }
}

########################################################
#    Security Groups - Configuration
########################################################

function sg_ws($sheet){

    $sheet.Cells.Item(1,1) = "Security Group Configuration2"
    $sheet.Cells.Item(1,1).Font.Size = $titleFontSize
    $sheet.Cells.Item(1,1).Font.Bold = $titleFontBold
    $sheet.Cells.Item(1,1).Font.ColorIndex = $titleFontColorIndex
    $sheet.Cells.Item(1,1).Font.Name = $titleFontName
    $sheet.Cells.Item(1,1).Interior.ColorIndex = $titleInteriorColor
    $range1 = $sheet.Range("a1", "j1")
    $range1.merge() | Out-Null

    $sheet.Cells.Item(2,1) = "Name"
    $sheet.Cells.Item(2,2) = "Scope"
    $sheet.Cells.Item(2,3) = "Universal"
    $sheet.Cells.Item(2,4) = "Inheritance Allowed"
    $sheet.Cells.Item(2,5) = "Group Type (Dynamic/Static)"
    $sheet.Cells.Item(2,6) = "Dynamic Query Key Value"
    $sheet.Cells.Item(2,7) = "Dynamic Query Operator"
    $sheet.Cells.Item(2,8) = "Dynamic Query Criteria"
    $sheet.Cells.Item(2,9) = "Dynamic Query Value"
    $sheet.Cells.Item(2,10) = "Object-ID"
    $range2 = $sheet.Range("a2", "j2")
    $range2.Font.Bold = $subTitleFontBold
    $range2.Interior.ColorIndex = $subTitleInteriorColor
    $range2.Font.Name = $subTitleFontName
    if($sheet -eq $ws16){
        pop_sg_ws2($sheet)
    }
    if($sheet -eq $ws5){
        pop_sg_ws($sheet)
    }
    # pop_sg_ws($sheet)
}

function pop_sg_ws($sheet){

    $row = 3
    $sg = Get-NSXSecurityGroup -scopeID 'globalroot-0'
    foreach ($member in $sg){
        try 
        {
            $link_ref = "Security_Groups!" + ($sheet.Cells.Item($row,1)).address($false,$false)
            if($secgrp_ht.ContainsKey($member.objectID) -eq $false)
            {
                $secgrp_ht.Add($member.objectID, $link_ref)
            }
        }
        catch [Exception]{
            Write-Warning $member.objectID + "already exists, manually create hyperlink reference"
        }

        if($member.dynamicMemberDefinition){

            $sheet.Cells.Item($row,1) = $member.name
            $sheet.Cells.Item($row,2) = $member.scope.name
            $sheet.Cells.Item($row,3) = $member.isUniversal
            $sheet.Cells.Item($row,4) = $member.inhertianceAllowed
            $sheet.Cells.Item($row,10) = $member.objectId
            $sheet.Cells.Item($row,5) = "Dynamic"

            foreach ($entity in $member.dynamicMemberDefinition.dynamicSet.dynamicCriteria){
                $sheet.Cells.Item($row,6) = $entity.key
                $sheet.Cells.Item($row,7) = $entity.operator
                $sheet.Cells.Item($row,8) = $entity.criteria
                $sheet.Cells.Item($row,9) = $entity.value
                $row++
            }
        }
        else{
            $sheet.Cells.Item($row,1) = $member.name
            $sheet.Cells.Item($row,2) = $member.scope.name
            $sheet.Cells.Item($row,3) = $member.isUniversal
            $sheet.Cells.Item($row,4) = $member.inhertianceAllowed
            $sheet.Cells.Item($row,10) = $member.objectId
            $sheet.Cells.Item($row,5) = "Static"
            $row++
        }
    }
    $sgu = Get-NSXSecurityGroup -scopeID 'universalroot-0'
    foreach ($member in $sgu){
        try 
        {
            $link_ref = "Security_Groups!" + ($sheet.Cells.Item($row,1)).address($false,$false)
            if($secgrp_ht.ContainsKey($member.objectID) -eq $false)
            {
                $secgrp_ht.Add($member.objectID, $link_ref)
            }
        }
        catch [Exception]{
            Write-Warning $member.objectID + "already exists, manually create hyperlink reference"
        }
        if($member.dynamicMemberDefinition){

            $sheet.Cells.Item($row,1) = $member.name
            $sheet.Cells.Item($row,2) = $member.scope.name
            $sheet.Cells.Item($row,3) = $member.isUniversal
            $sheet.Cells.Item($row,4) = $member.inhertianceAllowed
            $sheet.Cells.Item($row,10) = $member.objectId
            $sheet.Cells.Item($row,5) = "Dynamic"

            foreach ($entity in $member.dynamicMemberDefinition.dynamicSet.dynamicCriteria){
                $sheet.Cells.Item($row,6) = $entity.key
                $sheet.Cells.Item($row,7) = $entity.operator
                $sheet.Cells.Item($row,8) = $entity.criteria
                $sheet.Cells.Item($row,9) = $entity.value
                $row++
            }
        }
        else{
            $sheet.Cells.Item($row,1) = $member.name
            $sheet.Cells.Item($row,2) = $member.scope.name
            $sheet.Cells.Item($row,3) = $member.isUniversal
            $sheet.Cells.Item($row,4) = $member.inhertianceAllowed
            $sheet.Cells.Item($row,10) = $member.objectId
            $sheet.Cells.Item($row,5) = "Static"
            $row++
        }
    }

    $sheet.Cells.Item($row,1) = "Security Group Exclude & Include Membership"
    $sheet.Cells.Item($row,1).Font.Size = $titleFontSize
    $sheet.Cells.Item($row,1).Font.Bold = $titleFontBold
    $sheet.Cells.Item($row,1).Font.ColorIndex = $titleFontColorIndex
    $sheet.Cells.Item($row,1).Font.Name = $titleFontName
    $sheet.Cells.Item($row,1).Interior.ColorIndex = $titleInteriorColor
    $range2 = $sheet.Range("a"+$row, "H"+$row)
    $range2.merge() | Out-Null

    $row++

    $sheet.Cells.Item($row,1) = "SG Name"
    $sheet.Cells.Item($row,2) = "SG Object ID"   
    $sheet.Cells.Item($row,3) = "Is Universal"
    $sheet.Cells.Item($row,4) = "Inclusion or Exclusion"
    $sheet.Cells.Item($row,5) = "Member Type"
    $sheet.Cells.Item($row,6) = "Member Name"
    $sheet.Cells.Item($row,7) = "Member Object-ID"
    $sheet.Cells.Item($row,8) = "Universal"    
    $range3 = $sheet.Range("a"+$row, "h"+$row)
    $range3.Font.Bold = $subTitleFontBold
    $range3.Interior.ColorIndex = $subTitleInteriorColor
    $range3.Font.Name = $subTitleFontName

    $row++

    foreach ( $member in $sg ){

        $sheet.Cells.Item($row,1) = $member.name
        $sheet.Cells.Item($row,2) = $member.objectId
        $sheet.Cells.Item($row,3) = $member.isUniversal
        $range_row = $row
        # $row++

        if ( $member.member ) {
            
            foreach ($item in $member.member ) {
                
                $sheet.Cells.Item($row,4) = "Include"
                $sheet.Cells.Item($row,5) = $item.objectTypeName
                $sheet.Cells.Item($row,6) = $item.name
                $sheet.Cells.Item($row,7) = $item.objectId
                $sheet.Cells.Item($row,8) = $item.isUniversal
                $row++
            }
        }
        
        if ( $member.excludeMember ) {
            
            foreach ($item in $member.excludeMember ) {
                
                $sheet.Cells.Item($row,4) = "Exclude"
                $sheet.Cells.Item($row,5) = $item.objectTypeName
                $sheet.Cells.Item($row,6) = $item.name
                $sheet.Cells.Item($row,7) = $item.objectId
                $sheet.Cells.Item($row,8) = $item.isUniversal
                $row++
            }
        }        
    }

    foreach ( $member in $sgu ){

        $sheet.Cells.Item($row,1) = $member.name
        $sheet.Cells.Item($row,2) = $member.objectId
        $sheet.Cells.Item($row,3) = $member.isUniversal

        # $row++

        if ( $member.member ) {
            
            foreach ($item in $member.member ) {
                
                $sheet.Cells.Item($row,4) = "Include"
                $sheet.Cells.Item($row,5) = $item.objectTypeName
                $sheet.Cells.Item($row,6) = $item.name
                $sheet.Cells.Item($row,7) = $item.objectId
                $sheet.Cells.Item($row,8) = $item.isUniversal
                $row++
            }
        }
        
        if ( $member.excludeMember ) {
            
            foreach ($item in $member.excludeMember ) {
                
                $sheet.Cells.Item($row,4) = "Exclude"
                $sheet.Cells.Item($row,5) = $item.objectTypeName
                $sheet.Cells.Item($row,6) = $item.name
                $sheet.Cells.Item($row,7) = $item.objectId
                $sheet.Cells.Item($row,8) = $item.isUniversal
                $row++
            }
        }        
    }
} 


##meeeeeeeeeeeee######################################
function pop_sg_ws2($sheet){

    $row = 3
    $sg = Get-NSXSecurityGroup -scopeID 'globalroot-0'
    foreach ($member in $sg){
        try 
        {
            $link_ref = "Security_Groups!" + ($sheet.Cells.Item($row,1)).address($false,$false)
            if($secgrp_ht.ContainsKey($member.objectID) -eq $false)
            {
                $secgrp_ht.Add($member.objectID, $link_ref)
            }
        }
        catch [Exception]{
            Write-Warning $member.objectID + "already exists, manually create hyperlink reference"
        }

        if($member.dynamicMemberDefinition){

            $sheet.Cells.Item($row,1) = $member.name
            $sheet.Cells.Item($row,2) = $member.scope.name
            $sheet.Cells.Item($row,3) = $member.isUniversal
            $sheet.Cells.Item($row,4) = $member.inhertianceAllowed
            $sheet.Cells.Item($row,10) = $member.objectId
            $sheet.Cells.Item($row,5) = "Dynamic"

            foreach ($entity in $member.dynamicMemberDefinition.dynamicSet.dynamicCriteria){
                $sheet.Cells.Item($row,6) = $entity.key
                $sheet.Cells.Item($row,7) = $entity.operator
                $sheet.Cells.Item($row,8) = $entity.criteria
                $sheet.Cells.Item($row,9) = $entity.value
                $row++
            }
        }
        else{
            $sheet.Cells.Item($row,1) = $member.name
            $sheet.Cells.Item($row,2) = $member.scope.name
            $sheet.Cells.Item($row,3) = $member.isUniversal
            $sheet.Cells.Item($row,4) = $member.inhertianceAllowed
            $sheet.Cells.Item($row,10) = $member.objectId
            $sheet.Cells.Item($row,5) = "Static"
            $row++
        }
    }
    $sgu = Get-NSXSecurityGroup -scopeID 'universalroot-0'
    foreach ($member in $sgu){
        try 
        {
            $link_ref = "Security_Groups!" + ($sheet.Cells.Item($row,1)).address($false,$false)
            if($secgrp_ht.ContainsKey($member.objectID) -eq $false)
            {
                $secgrp_ht.Add($member.objectID, $link_ref)
            }
        }
        catch [Exception]{
            Write-Warning $member.objectID + "already exists, manually create hyperlink reference"
        }
        if($member.dynamicMemberDefinition){

            $sheet.Cells.Item($row,1) = $member.name
            $sheet.Cells.Item($row,2) = $member.scope.name
            $sheet.Cells.Item($row,3) = $member.isUniversal
            $sheet.Cells.Item($row,4) = $member.inhertianceAllowed
            $sheet.Cells.Item($row,10) = $member.objectId
            $sheet.Cells.Item($row,5) = "Dynamic"

            foreach ($entity in $member.dynamicMemberDefinition.dynamicSet.dynamicCriteria){
                $sheet.Cells.Item($row,6) = $entity.key
                $sheet.Cells.Item($row,7) = $entity.operator
                $sheet.Cells.Item($row,8) = $entity.criteria
                $sheet.Cells.Item($row,9) = $entity.value
                $row++
            }
        }
        else{
            $sheet.Cells.Item($row,1) = $member.name
            $sheet.Cells.Item($row,2) = $member.scope.name
            $sheet.Cells.Item($row,3) = $member.isUniversal
            $sheet.Cells.Item($row,4) = $member.inhertianceAllowed
            $sheet.Cells.Item($row,10) = $member.objectId
            $sheet.Cells.Item($row,5) = "Static"
            $row++
        }
    }

    $sheet.Cells.Item($row,1) = "Security Group Exclude & Include Membership"
    $sheet.Cells.Item($row,1).Font.Size = $titleFontSize
    $sheet.Cells.Item($row,1).Font.Bold = $titleFontBold
    $sheet.Cells.Item($row,1).Font.ColorIndex = $titleFontColorIndex
    $sheet.Cells.Item($row,1).Font.Name = $titleFontName
    $sheet.Cells.Item($row,1).Interior.ColorIndex = $titleInteriorColor
    $range2 = $sheet.Range("a"+$row, "H"+$row)
    $range2.merge() | Out-Null

    $row++

    $sheet.Cells.Item($row,1) = "SG Name"
    $sheet.Cells.Item($row,2) = "SG Object ID"   
    $sheet.Cells.Item($row,3) = "Is Universal"
    $sheet.Cells.Item($row,4) = "Inclusion or Exclusion"
    $sheet.Cells.Item($row,5) = "Member Type"
    $sheet.Cells.Item($row,6) = "Member Name"
    $sheet.Cells.Item($row,7) = "Member Object-ID"
    $sheet.Cells.Item($row,8) = "Universal"    
    $range3 = $sheet.Range("a"+$row, "h"+$row)
    $range3.Font.Bold = $subTitleFontBold
    $range3.Interior.ColorIndex = $subTitleInteriorColor
    $range3.Font.Name = $subTitleFontName

    $row++

    foreach ( $member in $sg ){

        $sheet.Cells.Item($row,1) = $member.name
        $sheet.Cells.Item($row,2) = $member.objectId
        $sheet.Cells.Item($row,3) = $member.isUniversal
        $range_row = $row
        # $row++

        if ( $member.member ) { #this means included
            $ipsetsgname=""
            $vmsgname=""
            $macset=""
            $sgsgname=""
            $othersgname=""

            foreach ($item in $member.member ) {
                if ($item.objectTypeName -eq "IPSet"){
                    $ipsetsgname= $ipsetsgname + $item.name + ","
                }elseif ($item.objectTypeName -eq "VirtualMachine") {
                    $vmsgname= $vmsgname + $item.name + ","
                }elseif ($item.objectTypeName -eq "MACSet") {
                    $macset= $macset + $item.name + ","
                }elseif ($item.objectTypeName -eq "SecurityGroup") {
                    $sgsgname= $sgsgname + $item.name + ","
                }else {
                    $othersgname= $othersgname + $item.name + ","
                }
                # $sheet.Cells.Item($dstRow,6) = $_dstipv4.Substring(0,$_dstipv4.Length-1)
            }
            if ($ipsetsgname -ne "" ){
                $sheet.Cells.Item($row,4) = "Include"
                $sheet.Cells.Item($row,5) = "IPSET"
                $sheet.Cells.Item($row,6) = $ipsetsgname.Substring(0,$ipsetsgname.Length-1)
                $sheet.Cells.Item($row,8) = "False"
                $row++
            }
            if ($vmsgname -ne "" ){
                $sheet.Cells.Item($row,4) = "Include"
                $sheet.Cells.Item($row,5) = "VirtualMachine"
                $sheet.Cells.Item($row,6) = $vmsgname.Substring(0,$vmsgname.Length-1)
                $sheet.Cells.Item($row,8) = "False"
                $row++
            }
            if ($macset -ne "" ){
                $sheet.Cells.Item($row,4) = "Include"
                $sheet.Cells.Item($row,5) = "MACSet"
                $sheet.Cells.Item($row,6) = $macset.Substring(0,$macset.Length-1)
                $sheet.Cells.Item($row,8) = "False"
                $row++
            }
            if ($sgsgname -ne "" ){
                $sheet.Cells.Item($row,4) = "Include"
                $sheet.Cells.Item($row,5) = "SecurityGroup"
                $sheet.Cells.Item($row,6) = $sgsgname.Substring(0,$sgsgname.Length-1)
                $sheet.Cells.Item($row,8) = "False"
                $row++
            }
            if ($othersgname -ne "" ){
                $sheet.Cells.Item($row,4) = "Include"
                $sheet.Cells.Item($row,5) = "others"
                $sheet.Cells.Item($row,6) = $othersgname.Substring(0,$othersgname.Length-1)
                $sheet.Cells.Item($row,8) = "False"
                $row++
            }
            $ipsetsgname=""
            $vmsgname=""
            $macset=""
            $sgsgname=""
            $othersgname=""
        }
        
        if ( $member.excludeMember ) {
            $x_ipsetsgname=""
            $x_vmsgname=""
            $x_macset=""
            $x_sgsgname=""
            $x_othersgname=""
            
            foreach ($item in $member.excludeMember ) {
                
                if ($item.objectTypeName -eq "IPSet"){
                    $x_ipsetsgname= $x_ipsetsgname + $item.name + ","
                }elseif ($item.objectTypeName -eq "VirtualMachine") {
                    $x_vmsgname= $x_vmsgname + $item.name + ","
                }elseif ($item.objectTypeName -eq "MACSet") {
                    $x_macset= $x_macset + $item.name + ","
                }elseif ($item.objectTypeName -eq "SecurityGroup") {
                    $x_sgsgname= $x_sgsgname + $item.name + ","
                }else {
                    $x_othersgname= $x_othersgname + $item.name + ","
                }
            }
            if ($x_ipsetsgname -ne "" ){
                $sheet.Cells.Item($row,4) = "Exclude"
                $sheet.Cells.Item($row,5) = "IPSET"
                $sheet.Cells.Item($row,6) = $x_ipsetsgname.Substring(0,$x_ipsetsgname.Length-1)
                $sheet.Cells.Item($row,8) = "False"
                $row++
            }
            if ($x_vmsgname -ne "" ){
                $sheet.Cells.Item($row,4) = "Exclude"
                $sheet.Cells.Item($row,5) = "VirtualMachine"
                $sheet.Cells.Item($row,6) = $x_vmsgname.Substring(0,$x_vmsgname.Length-1)
                $sheet.Cells.Item($row,8) = "False"
                $row++
            }
            if ($x_macset -ne "" ){
                $sheet.Cells.Item($row,4) = "Exclude"
                $sheet.Cells.Item($row,5) = "MACSet"
                $sheet.Cells.Item($row,6) = $x_macset.Substring(0,$x_macset.Length-1)
                $sheet.Cells.Item($row,8) = "False"
                $row++
            }
            if ($x_sgsgname -ne "" ){
                $sheet.Cells.Item($row,4) = "Exclude"
                $sheet.Cells.Item($row,5) = "SecurityGroup"
                $sheet.Cells.Item($row,6) = $x_sgsgname.Substring(0,$sgsgname.Length-1)
                $sheet.Cells.Item($row,8) = "False"
                $row++
            }            
            if ($x_othersgname -ne "" ){
                $sheet.Cells.Item($row,4) = "Exclude"
                $sheet.Cells.Item($row,5) = "other"
                $sheet.Cells.Item($row,6) = $x_othersgname.Substring(0,$x_othersgname.Length-1)
                $sheet.Cells.Item($row,8) = "False"
                $row++
            }            
            $x_ipsetsgname=""
            $x_vmsgname=""
            $x_macset=""
            $x_sgsgname=""
            $x_othersgname=""
        }        
    }
    foreach ( $member in $sgu ){

        $sheet.Cells.Item($row,1) = $member.name
        $sheet.Cells.Item($row,2) = $member.objectId
        $sheet.Cells.Item($row,3) = $member.isUniversal
        $range_row = $row
        # $row++

        if ( $member.member ) { #this means included
            $ipsetsgname=""
            $vmsgname=""
            $macset=""
            $sgsgname=""
            $othersgname=""

            foreach ($item in $member.member ) {
                if ($item.objectTypeName -eq "IPSet"){
                    $ipsetsgname= $ipsetsgname + $item.name + ","
                }elseif ($item.objectTypeName -eq "VirtualMachine") {
                    $vmsgname= $vmsgname + $item.name + ","
                }elseif ($item.objectTypeName -eq "MACSet") {
                    $macset= $macset + $item.name + ","
                }elseif ($item.objectTypeName -eq "SecurityGroup") {
                    $sgsgname= $sgsgname + $item.name + ","
                }else {
                    $othersgname = $othersgname + $item.name + ","
                }
                
            }
            if ($ipsetsgname -ne "" ){
                $sheet.Cells.Item($row,4) = "Include"
                $sheet.Cells.Item($row,5) = "IPSET"
                $sheet.Cells.Item($row,6) = $ipsetsgname.Substring(0,$ipsetsgname.Length-1)
                $sheet.Cells.Item($row,8) = "True"
                $row++
            }
            if ($vmsgname -ne "" ){
                $sheet.Cells.Item($row,4) = "Include"
                $sheet.Cells.Item($row,5) = "VirtualMachine"
                $sheet.Cells.Item($row,6) = $vmsgname.Substring(0,$vmsgname.Length-1)
                $sheet.Cells.Item($row,8) = "True"
                $row++
            }
            if ($macset -ne "" ){
                $sheet.Cells.Item($row,4) = "Include"
                $sheet.Cells.Item($row,5) = "MACSet"
                $sheet.Cells.Item($row,6) = $macset.Substring(0,$macset.Length-1)
                $sheet.Cells.Item($row,8) = "True"
                $row++
            }
            if ($sgsgname -ne "" ){
                $sheet.Cells.Item($row,4) = "Include"
                $sheet.Cells.Item($row,5) = "SecurityGroup"
                $sheet.Cells.Item($row,6) = $sgsgname.Substring(0,$sgsgname.Length-1)
                $sheet.Cells.Item($row,8) = "True"
                $row++
            }
            if ($othersgname -ne "" ){
                $sheet.Cells.Item($row,4) = "Include"
                $sheet.Cells.Item($row,5) = "others"
                $sheet.Cells.Item($row,6) = $othersgname.Substring(0,$othersgname.Length-1)
                $sheet.Cells.Item($row,8) = "True"
                $row++
            }
            $ipsetsgname=""
            $vmsgname=""
            $macset=""
            $sgsgname=""
            $othersgname=""
        }
        
        if ( $member.excludeMember ) {
            $x_ipsetsgname=""
            $x_vmsgname=""
            $x_macset=""
            $x_sgsgname=""
            $x_othersgname=""
            foreach ($item in $member.excludeMember ) {
                
                if ($item.objectTypeName -eq "IPSet"){
                    $x_ipsetsgname= $x_ipsetsgname + $item.name + ","
                }elseif ($item.objectTypeName -eq "VirtualMachine") {
                    $x_vmsgname= $x_vmsgname + $item.name + ","
                }elseif ($item.objectTypeName -eq "MACSet") {
                    $x_macset= $x_macset + $item.name + ","
                }elseif ($item.objectTypeName -eq "SecurityGroup") {
                    $x_sgsgname= $x_sgsgname + $item.name + ","
                }else {
                    $x_othersgname= $x_othersgname + $item.name + ","
                }
            }
            if ($x_ipsetsgname -ne "" ){
                $sheet.Cells.Item($row,4) = "Exclude"
                $sheet.Cells.Item($row,5) = "IPSET"
                $sheet.Cells.Item($row,6) = $x_ipsetsgname.Substring(0,$x_ipsetsgname.Length-1)
                $sheet.Cells.Item($row,8) = "False"
                $row++
            }
            if ($x_vmsgname -ne "" ){
                $sheet.Cells.Item($row,4) = "Exclude"
                $sheet.Cells.Item($row,5) = "VirtualMachine"
                $sheet.Cells.Item($row,6) = $x_vmsgname.Substring(0,$x_vmsgname.Length-1)
                $sheet.Cells.Item($row,8) = "False"
                $row++
            }
            if ($x_macset -ne "" ){
                $sheet.Cells.Item($row,4) = "Exclude"
                $sheet.Cells.Item($row,5) = "MACSet"
                $sheet.Cells.Item($row,6) = $x_macset.Substring(0,$x_macset.Length-1)
                $sheet.Cells.Item($row,8) = "False"
                $row++
            }
            if ($x_sgsgname -ne "" ){
                $sheet.Cells.Item($row,4) = "Exclude"
                $sheet.Cells.Item($row,5) = "SecurityGroup"
                $sheet.Cells.Item($row,6) = $x_sgsgname.Substring(0,$sgsgname.Length-1)
                $sheet.Cells.Item($row,8) = "False"
                $row++
            }            
            if ($x_othersgname -ne "" ){
                $sheet.Cells.Item($row,4) = "Exclude"
                $sheet.Cells.Item($row,5) = "others"
                $sheet.Cells.Item($row,6) = $x_othersgname.Substring(0,$x_othersgname.Length-1)
                $sheet.Cells.Item($row,8) = "False"
                $row++
            }            
            $x_ipsetsgname=""
            $x_vmsgname=""
            $x_macset=""
            $x_sgsgname=""
            $x_othersgname=""

        }        
    }

} 




########################################################
#    Security Groups - Effective Membership
########################################################

function sg_resultant_membership($sheet){

    $sheet.Cells.Item(1,1) = "Security Group Effective VM Membership"
    $sheet.Cells.Item(1,1).Font.Size = $titleFontSize
    $sheet.Cells.Item(1,1).Font.Bold = $titleFontBold
    $sheet.Cells.Item(1,1).Font.ColorIndex = $titleFontColorIndex
    $sheet.Cells.Item(1,1).Font.Name = $titleFontName
    $sheet.Cells.Item(1,1).Interior.ColorIndex = $titleInteriorColor
    $range1 = $sheet.Range("a1", "j1")
    $range1.merge() | Out-Null

    $sheet.Cells.Item(2,1) = "SG Name"
    $sheet.Cells.Item(2,2) = "SG Object ID"
    $sheet.Cells.Item(2,3) = "VM Name"
    $sheet.Cells.Item(2,4) = "VM ID"
    $range2 = $sheet.Range("a2", "d2")
    $range2.Font.Bold = $subTitleFontBold
    $range2.Interior.ColorIndex = $subTitleInteriorColor
    $range2.Font.Name = $subTitleFontName
    pop_sg_resultant_membership($sheet)
}

function pop_sg_resultant_membership($sheet){

    $row = 3
    $sg = Get-NSXSecurityGroup -scopeID 'globalroot-0'

    if ($collect_vm_members -eq "y") {
        Write-Host "Collection of VM Sec Membership Enabled"
        
        foreach ($member in $sg){

            $members = $member | Get-NSXSecurityGroupEffectiveMember

            $sheet.Cells.Item($row,1) = $member.name
            $sheet.Cells.Item($row,2) = $member.objectid

            foreach ($vm in $members.virtualmachine.vmnode)
            {
                $sheet.Cells.Item($row,3) = $vm.vmName
                $sheet.Cells.Item($row,4) = $vm.vmID

                $result = $vmaddressing_ht[$vm.vmID]        
                if([string]::IsNullOrWhiteSpace($result))
                {
                     $sheet.Cells.Item($row,3) = $vm.vmName
                }
                else 
                {
                    $link = $sheet.Hyperlinks.Add(
                    $sheet.Cells.Item($row,3),
                    "",
                    $result,
                    "Virtual Machine Information",
                    $vm.vmName)          
                }
                $row++
            }
        }
    }
    else {
        Write-Host "Collection of VM Sec Membership Disabled"
        $sheet.Cells.Item($row,2) = "<Collection Disabled>"
        $sheet.Cells.Item($row,2).Font.ColorIndex = 3
        $sheet.Cells.Item($row,3) = "<Collection Disabled>"
        $sheet.Cells.Item($row,3).Font.ColorIndex = 3
    }
}


########################################################
#    Environment Summary
########################################################

function env_ws($sheet){

    $sheet.Cells.Item(1,1) = "NSX Environment Summary"
    $sheet.Cells.Item(1,1).Font.Size = $titleFontSize
    $sheet.Cells.Item(1,1).Font.Bold = $titleFontBold
    $sheet.Cells.Item(1,1).Font.ColorIndex = $titleFontColorIndex
    $sheet.Cells.Item(1,1).Font.Name = $titleFontName
    $sheet.Cells.Item(1,1).Interior.ColorIndex = $titleInteriorColor
    $range1 = $sheet.Range("a1", "j1")
    $range1.merge() | Out-Null

    $sys_sum = Get-NsxManagerSystemSummary
    $ssoconfig = Get-NsxManagerSsoConfig
    $vcconfig = Get-NsxManagerVcenterConfig
    $ver = Get-PowerNSXVersion

    $sheet.Cells.Item(2,1) = "PowerNSX version"
    $sheet.Cells.Item(2,2) = $ver.version.toString()

    $sheet.Cells.Item(3,1) = "NSX Manager Name"
    $sheet.Cells.Item(3,2) = $sys_sum.hostName
    
    $sheet.Cells.Item(4,1) = "IPv4 Address"
    $sheet.Cells.Item(4,2) = $sys_sum.Ipv4Address

    $sheet.Cells.Item(5,1) = "SSO Lookup URL"
    $sheet.Cells.Item(5,2) = $ssoconfig.ssoLookupServiceUrl    

    $sheet.Cells.Item(6,1) = "SSO User Account"
    $sheet.Cells.Item(6,2) = $ssoconfig.ssoAdminUsername
    
    $sheet.Cells.Item(7,1) = "vCenter Mapping"
    $sheet.Cells.Item(7,2) = $vcconfig.ipAddress

    $sheet.Cells.Item(8,1) = "NSX Manager Version"
    $sheet.Cells.Item(8,2) = ($sys_sum.versionInfo.majorVersion + "." `
                             + $sys_sum.versionInfo.minorVersion + "." `
                             + $sys_sum.versionInfo.patchVersion + "." `
                             + $sys_sum.versionInfo.buildNumber)
    
    $sheet.Cells.Item(9,1) = "Security Group Membership Statistics"
    $sheet.Cells.Item(9,1).Font.Size = $titleFontSize
    $sheet.Cells.Item(9,1).Font.Bold = $titleFontBold
    $sheet.Cells.Item(9,1).Font.ColorIndex = $titleFontColorIndex
    $sheet.Cells.Item(9,1).Font.Name = $titleFontName
    $sheet.Cells.Item(9,1).Interior.ColorIndex = $titleInteriorColor
    $range1 = $sheet.Range("a9", "j9")
    $range1.merge() | Out-Null
    
    $sheet.Cells.Item(10,1) = "Security Group Name"
    $sheet.Cells.Item(10,2) = "Translated VMs"
    $sheet.Cells.Item(10,3) = "Translated IPs"
    $range2 = $sheet.Range("a10", "c10")
    $range2.Font.Bold = $subTitleFontBold
    $range2.Interior.ColorIndex = $subTitleInteriorColor
    $range2.Font.Name = $subTitleFontName
    pop_env_ws($sheet)
}

function pop_env_ws($sheet){

    $row = 11

    ### Security Group Membership statistics

    $sg = Get-NSXSecurityGroup

    foreach($item in $sg){

        $sheet.Cells.Item($row,1) = $item.name

        $url_vms = "/api/2.0/services/securitygroup/" + $item.objectid + `
                   "/translation/virtualmachines"
        $url_ips = "/api/2.0/services/securitygroup/" + $item.objectid + `
                   "/translation/ipaddresses"
        
        $sec_vm_stats = Invoke-NsxRestMethod -method get -uri $url_vms
        $sheet.Cells.Item($row,2) = $sec_vm_stats.vmnodes.vmnode.Length 

        $sec_ip_stats = Invoke-NsxRestMethod -method get -uri $url_ips
        $sheet.Cells.Item($row,3) = $sec_ip_stats.ipNodes.ipNode.ipAddresses.Length

        $row ++
    }
}

########################################################
#    IPSETS Worksheet
########################################################

function ipset_ws($sheet){

    $sheet.Cells.Item(1,1) = "IPSET Configuration"
    $sheet.Cells.Item(1,1).Font.Size = $titleFontSize
    $sheet.Cells.Item(1,1).Font.Bold = $titleFontBold
    $sheet.Cells.Item(1,1).Font.ColorIndex = $titleFontColorIndex
    $sheet.Cells.Item(1,1).Font.Name = $titleFontName
    $sheet.Cells.Item(1,1).Interior.ColorIndex = $titleInteriorColor
    $range1 = $sheet.Range("a1", "d1")
    $range1.merge() | Out-Null

    $sheet.Cells.Item(2,1) = "Name"
    $sheet.Cells.Item(2,2) = "Value"
    $sheet.Cells.Item(2,3) = "Universal"
    $sheet.Cells.Item(2,4) = "Object-ID"
    $sheet.Cells.Item(2,5) = "Description"
    $range2 = $sheet.Range("a2", "e2")
    $range2.Font.Bold = $subTitleFontBold
    $range2.Interior.ColorIndex = $subTitleInteriorColor
    $range2.Font.Name = $subTitleFontName
    pop_ipset_ws($sheet)
}

function pop_ipset_ws($sheet){

    $row=3
    $ipset = get-nsxipset -scopeID 'globalroot-0'

    foreach ($ip in $ipset) {

        $sheet.Cells.Item($row,1) = $ip.name
        $sheet.Cells.Item($row,2) = $ip.value
        $sheet.Cells.Item($row,3) = $ip.isUniversal
        $sheet.Cells.Item($row,4) = $ip.objectId
        try 
        {
            $link_ref = "IPSETS!" + ($sheet.Cells.Item($row,1)).address($false,$false)
            if($ipsets_ht.ContainsKey($ip.objectID) -eq $false)
            {
                $ipsets_ht.Add($ip.objectID, $link_ref)
            }
        }
        catch [Exception]{
            Write-Warning $ip.objectID + "already exists, manually create hyperlink reference"
        }
        if(!$ip.description){
            $sheet.Cells.Item($row,5) = $valueNotDefined
        }
        else {$sheet.Cells.Item($row,5) = $ip.description}

        $row++ # Increment Rows
    }

    $ipset_unv = get-nsxipset -scopeID 'universalroot-0'

    foreach ($ip in $ipset_unv) {

        $sheet.Cells.Item($row,1) = $ip.name
        $sheet.Cells.Item($row,2) = $ip.value
        $sheet.Cells.Item($row,3) = $ip.isUniversal
        $sheet.Cells.Item($row,4) = $ip.objectId
        try 
        {
            $link_ref = "IPSETS!" + ($sheet.Cells.Item($row,1)).address($false,$false)
            if($ipsets_ht.ContainsKey($ip.objectID) -eq $false)
            {
                $ipsets_ht.Add($ip.objectID, $link_ref)
            }
        }
        catch [Exception]{
            Write-Warning $ip.objectID + "already exists, manually create hyperlink reference"
        }

        if(!$ip.description){
            $sheet.Cells.Item($row,5) = $valueNotDefined
        }
        else {$sheet.Cells.Item($row,5) = $ip.description}
        $row++ # Increment Rows
    }
}

########################################################
#    MACSETS Worksheet
########################################################

function macset_ws($sheet){

    $sheet.Cells.Item(1,1) = "MACSET Configuration"
    $sheet.Cells.Item(1,1).Font.Size = $titleFontSize
    $sheet.Cells.Item(1,1).Font.Bold = $titleFontBold
    $sheet.Cells.Item(1,1).Font.ColorIndex = $titleFontColorIndex
    $sheet.Cells.Item(1,1).Font.Name = $titleFontName
    $sheet.Cells.Item(1,1).Interior.ColorIndex = $titleInteriorColor
    $range1 = $sheet.Range("a1", "e1")
    $range1.merge() | Out-Null

    $sheet.Cells.Item(2,1) = "Name"
    $sheet.Cells.Item(2,2) = "Value"
    $sheet.Cells.Item(2,3) = "Description"
    $range2 = $sheet.Range("a2", "c2")
    $range2.Font.Bold = $subTitleFontBold
    $range2.Interior.ColorIndex = $subTitleInteriorColor
    $range2.Font.Name = $subTitleFontName
    pop_macset_ws($sheet)
}

function pop_macset_ws($sheet){

    # Grab MACSets and populate
    $row=3
    $macset = get-nsxmacset
    foreach ($mac in $macset) {

        $sheet.Cells.Item($row,1) = $mac.name
        $sheet.Cells.Item($row,2) = $mac.value
        if(!$mac.description){
            $sheet.Cells.Item($row,3) = $valueNotDefined
        }
        else {$sheet.Cells.Item($row,3) = $mac.description}

        $row++ # Increment Rows
    }
}

########################################################
#    Services Worksheet
########################################################

function services_ws($sheet){

    $sheet.Cells.Item(1,1) = "DFW Services Configuration"
    $sheet.Cells.Item(1,1).Font.Size = $titleFontSize
    $sheet.Cells.Item(1,1).Font.Bold = $titleFontBold
    $sheet.Cells.Item(1,1).Font.ColorIndex = $titleFontColorIndex
    $sheet.Cells.Item(1,1).Font.Name = $titleFontName
    $sheet.Cells.Item(1,1).Interior.ColorIndex = $titleInteriorColor
    $range1 = $sheet.Range("a1", "h1")
    $range1.merge() | Out-Null

    $sheet.Cells.Item(2,1) = "S/N"
    $sheet.Cells.Item(2,2) = "Name"
    $sheet.Cells.Item(2,3) = "Protocol"
    $sheet.Cells.Item(2,4) = "Dstport"
    $sheet.Cells.Item(2,5) = "Srcport"
    $sheet.Cells.Item(2,6) = "Remarks"
    $sheet.Cells.Item(2,7) = "Universal"

    $range2 = $sheet.Range("a2", "h2")
    $range2.Font.Bold = $subTitleFontBold
    $range2.Interior.ColorIndex = $subTitleInteriorColor
    $range2.Font.Name = $subTitleFontName
    if ($sheet -eq $ws1) {
        pop_services_ws($sheet)
    } elseif ($sheet -eq $ws12) {
        pop_services_ws2($sheet)
    } elseif ($sheet -eq $ws14) {
        pop_services_ws3($sheet)
    }
}




function pop_services_ws($sheet){

    # Grab Services and populate
    $row=3
    $services = get-nsxservice -scopeID 'globalroot-0'
    foreach ($svc in $services) {

        $sheet.Cells.Item($row,2) = $svc.name
        #$sheet.Cells.Item($row,2) = $svc.type.typeName
        $sheet.Cells.Item($row,3) = $svc.element.applicationProtocol
        $sheet.Cells.Item($row,4).NumberFormat = "@"
        $sheet.Cells.Item($row,4) = $svc.element.value
        $sheet.Cells.Item($row,5) = $svc.element.sourceport
        $sheet.Cells.Item($row,7) = $svc.isUniversal
        try 
        {
            $link_ref = "Services!" + ($sheet.Cells.Item($row,1)).address($false,$false)
            if($services_ht.ContainsKey($svc.objectID) -eq $false)
            {
                $services_ht.Add($svc.objectID, $link_ref)
            }
        }
        catch [Exception]{
            Write-Warning $svc.objectID + "already exists, manually create hyperlink reference"
        }
      
        $row++ # Increment Rows
    }

    $services_unv = get-nsxservice -scopeID 'universalroot-0'
    foreach ($svc in $services_unv) {

        $sheet.Cells.Item($row,1) = $svc.name
        #$sheet.Cells.Item($row,2) = $svc.type.typeName
        $sheet.Cells.Item($row,3) = $svc.element.applicationProtocol
        $sheet.Cells.Item($row,4).NumberFormat = "@"
        $sheet.Cells.Item($row,4) = $svc.element.value
        #$sheet.Cells.Item($row,5) = $svc.isUniversal
        $sheet.Cells.Item($row,5) = $svc.element.sourceport
        $sheet.Cells.Item($row,7) = $svc.isUniversal
        try 
        {
            $link_ref = "Services!" + ($sheet.Cells.Item($row,1)).address($false,$false)
            if($services_ht.ContainsKey($svc.objectID) -eq $false)
            {
                $services_ht.Add($svc.objectID, $link_ref)
            }
        }
        catch [Exception]{
            Write-Warning $svc.objectID + "already exists, manually create hyperlink reference"
        }
      
        $row++ # Increment Rows
    }
}

function pop_services_ws2($sheet){

    # Grab Services and populate
    $sheet.Cells.Item(1,1) = "Services that are of type Services and used by rules"
    $row=3
    $usedservices = (Get-NsxFirewallSection -sectionType layer3sections -scopeID 'globalroot-0'`
    | Get-NsxFirewallRule).services.service | Where-Object type -eq Application
    $dedup_servicename = $usedservices.Name | Sort-Object -Unique
        
    
    # $services = get-nsxservice -scopeID 'globalroot-0'
    

    foreach ($item in $dedup_servicename) {
        $svc = Get-NsxService -Name $item -scopeID 'globalroot-0'
        $sheet.Cells.Item($row,2) = $svc.name
        $sheet.Cells.Item($row,8) = $svc.type.typeName
        $sheet.Cells.Item($row,3) = $svc.element.applicationProtocol
        $sheet.Cells.Item($row,4).NumberFormat = "@"
        $sheet.Cells.Item($row,4) = $svc.element.value
        $sheet.Cells.Item($row,5) = $svc.element.sourceport
        $sheet.Cells.Item($row,7) = $svc.isUniversal
     
        $row++ # Increment Rows
    }
#get the firewall section which are under universal and are services only
    $usedservices = (Get-NsxFirewallSection -sectionType layer3sections `
    | Where-Object {($_.managedBy -eq 'universalroot-0')} `
    | Get-NsxFirewallRule).services.service | Where-Object type -eq Application
# remove duplication    
    $dedup_servicename = $usedservices.Name | Sort-Object -Unique
        
        
        foreach ($item in $dedup_servicename) {
        #for the same service there are univeral and global ones identical names only get the universal ones
        # Get-NsxService -Name $item -scopeID 'universalroot-0'
        $svc = Get-NsxService -Name $item -scopeID 'universalroot-0'
        $sheet.Cells.Item($row,2) = $svc.name
        $sheet.Cells.Item($row,8) = $svc.type.typeName
        $sheet.Cells.Item($row,3) = $svc.element.applicationProtocol
        $sheet.Cells.Item($row,4).NumberFormat = "@"
        $sheet.Cells.Item($row,4) = $svc.element.value
        $sheet.Cells.Item($row,5) = $svc.element.sourceport
        $sheet.Cells.Item($row,7) = $svc.isUniversal
     
        $row++ # Increment Rows
    }

}

function pop_services_ws3($sheet){

    # Grab Services and populate
     $sheet.Cells.Item(1,1) = "Members of the Service groups that are of type SERVICE and are used in the rules"
    $row=3

   
    # $services = get-nsxservice -scopeID 'globalroot-0'
    $usedsvcgrp = (Get-NsxFirewallSection -sectionType layer3sections -scopeID 'globalroot-0'`
    | Get-NsxFirewallRule).services.service `
    |  Where-Object type -eq ApplicationGroup
    $dedup_svcgrpname = $usedsvcgrp.name | Sort-Object -Unique

    $_member=@()
    foreach ($item in $dedup_svcgrpname) { # we want the set of all services used in the service group
        $svcgrp = Get-NsxServiceGroup -name $item -scopeID 'globalroot-0'

        foreach ($item in $svcgrp.member) {
            $_member = $_member + $item.name 
        }
        
    }

    $dedup_servicename = $_member | Sort-Object -Unique
    
    # write-host "############################"
    foreach ($item in $dedup_servicename) {
        $svc = Get-NsxService -Name $item -scopeID 'globalroot-0'
        Write-Host $svc.name
        $sheet.Cells.Item($row,2) = $svc.name
        $sheet.Cells.Item($row,8) = $svc.type.typeName
        $sheet.Cells.Item($row,3) = $svc.element.applicationProtocol
        $sheet.Cells.Item($row,4).NumberFormat = "@"
        $sheet.Cells.Item($row,4) = $svc.element.value
        $sheet.Cells.Item($row,5) = $svc.element.sourceport
        $sheet.Cells.Item($row,7) = $svc.isUniversal
        
        $row++ # Increment Rows$$ 
        
    }


#########universal
#get only universal sections
    $usedsvcgrp = (Get-NsxFirewallSection -sectionType layer3sections `
    | Where-Object {($_.managedBy -eq 'universalroot-0')} `
    | Get-NsxFirewallRule).services.service `
    |  Where-Object type -eq ApplicationGroup

    $dedup_svcgrpname = $usedsvcgrp.name | Sort-Object -Unique

    $_member=@()
    foreach ($item in $dedup_svcgrpname) { # we want the set of all services used in the service group
        $svcgrp = Get-NsxServiceGroup -name $item -scopeID 'universalroot-0'

        foreach ($item in $svcgrp.member) {
            $_member = $_member + $item.name 
        }
        
    }

    $dedup_servicename = $_member | Sort-Object -Unique
    
    foreach ($item in $dedup_servicename) {
        $svc = Get-NsxService -Name $item -scopeID 'universalroot-0'
    
        $sheet.Cells.Item($row,2) = $svc.name
        $sheet.Cells.Item($row,8) = $svc.type.typeName
        $sheet.Cells.Item($row,3) = $svc.element.applicationProtocol
        $sheet.Cells.Item($row,4).NumberFormat = "@"
        $sheet.Cells.Item($row,4) = $svc.element.value
        $sheet.Cells.Item($row,5) = $svc.element.sourceport
        $sheet.Cells.Item($row,7) = $svc.isUniversal
        
        $row++ # Increment Rows$$ 
        
    }



}
########################################################
#    Service Groups Worksheet
########################################################

function service_groups_ws($sheet){

    $sheet.Cells.Item(1,1) = "Service Group Configuration"
    $sheet.Cells.Item(1,1).Font.Size = $titleFontSize
    $sheet.Cells.Item(1,1).Font.Bold = $titleFontBold
    $sheet.Cells.Item(1,1).Font.ColorIndex = $titleFontColorIndex
    $sheet.Cells.Item(1,1).Font.Name = $titleFontName
    $sheet.Cells.Item(1,1).Interior.ColorIndex = $titleInteriorColor
    $range1 = $sheet.Range("a1", "g1")
    $range1.merge() | Out-Null

    $sheet.Cells.Item(2,1) = "S/N"
    $sheet.Cells.Item(2,2) = "Service Group Name"
    $sheet.Cells.Item(2,3) = "Scope"
    $sheet.Cells.Item(2,4) = "Service Members"
    $sheet.Cells.Item(2,5) = "Object-ID"
    $sheet.Cells.Item(2,6) = "Type"
    
    $range2 = $sheet.Range("a2", "g2")
    $range2.Font.Bold = $subTitleFontBold
    $range2.Interior.ColorIndex = $subTitleInteriorColor
    $range2.Font.Name = $subTitleFontName
    if ($sheet -eq $ws2){
    pop_service_groups_ws($sheet)
    } 
    if ($sheet -eq $ws13){
        pop_service_groups_ws2($sheet)    
    }
    if ($sheet -eq $ws15){
    pop_service_groups_ws4($sheet)
    }
}

function pop_service_groups_ws($sheet){

    $row=3
    $SG = Get-NSXServiceGroup -scopeID 'globalroot-0'

    foreach ($svc_mem in $SG) 
    {
        $sheet.Cells.Item($row,2) = $svc_mem.name
        $sheet.Cells.Item($row,2).Font.Bold = $true
        # $sheet.Cells.Item($row,2) = $svc_mem.isUniversal
        $sheet.Cells.Item($row,3) = $svc_mem.scope.name
        $sheet.Cells.Item($row,5) = $svc_mem.objectId
       
        try 
        {
            $link_ref = "Service_Groups!" + ($sheet.Cells.Item($row,1)).address($false,$false)
            if($services_ht.ContainsKey($svc_mem.objectID) -eq $false)
            {
                $services_ht.Add($svc_mem.objectID, $link_ref)
            }
        }
        catch [Exception]{
            Write-Warning $svc_mem.objectID + "already exists, manually create hyperlink reference"
        }

        if (!$svc_mem.member)
        {
            $row++ # Increment Rows
        }
        else
        {
            foreach ($member in $svc_mem.member)
            {
                $result = $services_ht[$member.objectid]        
                if([string]::IsNullOrWhiteSpace($result))
                {
                     $sheet.Cells.Item($row,4) = $member.name
                     $row++ # Increment Rows
                }
                else 
                {
                    $link = $sheet.Hyperlinks.Add(
                    $sheet.Cells.Item($row,4),
                    "",
                    $result,
                    $member.objectid,
                    $member.name)  
                    $row++ # Increment Rows
                }
            }
        }
    }

    $SGU = Get-NSXServiceGroup -scopeID 'universalroot-0'

    foreach ($svc_mem in $SGU) 
    {
        $sheet.Cells.Item($row,2) = $svc_mem.name
        $sheet.Cells.Item($row,2).Font.Bold = $true
        # $sheet.Cells.Item($row,2) = $svc_mem.isUniversal
        $sheet.Cells.Item($row,3) = $svc_mem.scope.name
        $sheet.Cells.Item($row,5) = $svc_mem.objectId
        
        try 
        {
            $link_ref = "Service_Groups!" + ($sheet.Cells.Item($row,1)).address($false,$false)
            if($services_ht.ContainsKey($svc_mem.objectID) -eq $false)
            {
                $services_ht.Add($svc_mem.objectID, $link_ref)
            }
        }
        catch [Exception]{
            Write-Warning $svc_mem.objectID + "already exists, manually create hyperlink reference"
        }

        if (!$svc_mem.member) 
        {
                $row++ # Increment Rows
        }
        else 
        {
            foreach ($member in $svc_mem.member)
            {
                $result = $services_ht[$member.objectid]        
                if([string]::IsNullOrWhiteSpace($result))
                {
                     $sheet.Cells.Item($row,4) = $member.name
                     $row++ # Increment Rows
                }
                else 
                {
                    $link = $sheet.Hyperlinks.Add(
                    $sheet.Cells.Item($row,4),
                    "",
                    $result,
                    $member.objectid,
                    $member.name)  
                    $row++ # Increment Rows
                }
            }
        }
    }
}

function pop_service_groups_ws2($sheet){

    $row=3
    $sheet.Cells.Item(1,1) = "Service Groups used in the rules"
    $usedsvcgrp = (Get-NsxFirewallSection -sectionType layer3sections `
        | Get-NsxFirewallRule).services.service `
        |  Where-Object type -eq ApplicationGroup
    $dedup_svcgrpname = $usedsvcgrp.Name | Sort-Object -Unique
    
    foreach ($item in $dedup_svcgrpname) 
    {
        
        Get-NsxServiceGroup -name $item 
        $svc_mem = Get-NsxServiceGroup -name $item 

        $sheet.Cells.Item($row,2) = $svc_mem.name
        $sheet.Cells.Item($row,2).Font.Bold = $true
        $sheet.Cells.Item($row,3) = $svc_mem.scope.name
        $sheet.Cells.Item($row,5) = $svc_mem.objectId
        
    #     write-host $item
    #    write-host "################################"
    #     write-host $svc_mem.name
        $_member=""
        $_member_grpingrp=""
        foreach ($member in $svc_mem.member)
        {
        
            if ($member.objectTypeName -eq 'Application'){
                $_member = $_member + $member.name + ","
                # write-host "_member=" $_member
            }
            
            if ($member.objectTypeName -eq 'ApplicationGroup'){
                $_member_grpingrp = $_member_grpingrp + $member.name + ","
                # write-host "_member_grpingrp=" $_member_grpingrp
            }
        
        }
        if ($_member -ne "") {
            $sheet.Cells.Item($row,4) = $_member.Substring(0,$_member.Length-1) 
            $sheet.Cells.Item($row,6) = "Service"
            $row++
        }
        if ($_member_grpingrp -ne "") {
            $sheet.Cells.Item($row,4) = $_member_grpingrp.Substring(0,$_member_grpingrp.Length-1) 
            $sheet.Cells.Item($row,6) = "ServiceGroup"
            $row++

        }
            
        $_member=""
        $_member_grpingrp=""
        
    }

}

function pop_service_groups_ws4($sheet){

    $row=3
    $sheet.Cells.Item(1,1) = "Members of the Service groups that are of type SERVICE GROUP and are used in the rules"
    $sheet.Cells.Item(2,1) = "S/N"
    $sheet.Cells.Item(2,2) = "Parent"
    $sheet.Cells.Item(2,3) = "Child"
    $sheet.Cells.Item(2,4) = "Service Member"
    $sheet.Cells.Item(2,5) = "Service Member Type"
    $sheet.Cells.Item(2,6) = "Scope"
    $sheet.Cells.Item(2,7) = "Parent ObjectID"
   
    $usedsvcgrp = (Get-NsxFirewallSection -sectionType layer3sections `
        | Get-NsxFirewallRule).services.service `
        |  Where-Object type -eq ApplicationGroup
    $dedup_svcgrpname = $usedsvcgrp.Name | Sort-Object -Unique
    
    foreach ($item in $dedup_svcgrpname) {
        write-host "row="$row
        # Get-NsxServiceGroup -name $item 
        $svc_mem = Get-NsxServiceGroup -name $item 
        # write-host "############parent service group######"
        # write-host “parentservicegroup="$svc_mem.name

        if ($svc_mem.member.objectTypeName -eq 'ApplicationGroup'){ #only proceed if there are svcgrps in the svcgrps
            $sheet.Cells.Item($row,2) = $svc_mem.name #parent name
            $sheet.Cells.Item($row,2).Font.Bold = $true
            $sheet.Cells.Item($row,6) = $svc_mem.scope.name
            $sheet.Cells.Item($row,7) = $svc_mem.objectId
            
            $_grandchildsvc=""
            $_grandchildsvcgrp=""
            foreach ($member in $svc_mem.member){
                
                if ($member.objectTypeName -eq 'ApplicationGroup'){ #look for members that are service groups
                    write-host "childservicegroup="$member.name
                    $sheet.Cells.Item($row,3) = $member.name #child name
                    # child service group name
    
                    foreach ($child in $member.name){
                        $childmemsvc = Get-NsxServiceGroup -name $child 
                        $appmember = $childmemsvc.member | Where-Object objectTypeName -eq "Application"
                        
                        foreach ($grandchild in $appmember){
                            $_grandchildsvc = $_grandchildsvc + $grandchild.name + ","
                            write-host "grandchild="$grandchild.name
                        }

                        $appmember = $childmemsvc.member | Where-Object objectTypeName -eq "ApplicationGroup"
                        
                        foreach ($grandchild in $appmember){
                            $_grandchildsvcgrp = $_grandchildsvcgrp + $grandchild.name + ","
                            write-host "_grandchildsvcgrp="$grandchild.name
                        }

                    }

                    
                    if ($_grandchildsvc -ne "") {
                        $sheet.Cells.Item($row,4) = $_grandchildsvc.Substring(0,$_grandchildsvc.Length-1) 
                        $sheet.Cells.Item($row,5) = "Service"
                        $row++
                    }
                    if ($_grandchildsvcgrp -ne "") {
                        $sheet.Cells.Item($row,4) = $_grandchildsvcgrp.Substring(0,$_grandchildsvcgrp.Length-1) 
                        $sheet.Cells.Item($row,5) = "ServiceGroup"
                        $row++
                    }
                    $_grandchildsvc=""
                    $_grandchildsvcgrp=""
                
                }
            
            }
        
            write-host "_grandchildsvc="$_grandchildsvc
            write-host "_grandchildsvcgrp="$_grandchildsvcgrp

            $_grandchildsvc=""
            $_grandchildsvcgrp=""
            write-host "row="$row
        }
    }

}


####################################################

########################################################
#    Security Tag Worksheet
########################################################

function sec_tags_ws($sheet){

    $sheet.Cells.Item(1,1) = "Security Tag Configuration"
    $sheet.Cells.Item(1,1).Font.Size = $titleFontSize
    $sheet.Cells.Item(1,1).Font.Bold = $titleFontBold
    $sheet.Cells.Item(1,1).Font.ColorIndex = $titleFontColorIndex
    $sheet.Cells.Item(1,1).Font.Name = $titleFontName
    $sheet.Cells.Item(1,1).Interior.ColorIndex = $titleInteriorColor
    $range1 = $sheet.Range("a1", "f1")
    $range1.merge() | Out-Null

    $sheet.Cells.Item(2,1) = "Security Tag Name"
    $sheet.Cells.Item(2,2) = "Built-In"
    $sheet.Cells.Item(2,3) = "VM Members"
    $sheet.Cells.Item(2,4) = "Is Universal"
    $range2 = $sheet.Range("a2", "d2")
    $range2.Font.Bold = $subTitleFontBold
    $range2.Interior.ColorIndex = $subTitleInteriorColor
    $range2.Font.Name = $subTitleFontName
    pop_sec_tags_ws($sheet)
}

function pop_sec_tags_ws($sheet){
    
    $row=3
    $ST = get-nsxsecuritytag -includesystem

    foreach ($tag in $ST) {
        $sheet.Cells.Item($row,1) = $tag.name
        $sheet.Cells.Item($row,2) = $tag.systemResource
        $sheet.Cells.Item($row,3) = $tag.vmCount
        $sheet.Cells.Item($row,4) = $tag.isUniversal
        $row++ # Increment Rows
    }

    $sheet.Cells.Item($row,1) = "Security Tag Name"
    $sheet.Cells.Item($row,2) = "VM Name"
    $sheet.Cells.Item($row,3) = "VM ID"
    $range3 = $sheet.Range("a"+$row, "c"+$row)
    $range3.Font.Bold = $subTitleFontBold
    $range3.Interior.ColorIndex = $subTitleInteriorColor
    $range3.Font.Name = $subTitleFontName

    $row ++

    # Traverse VM membership and populate spreadsheet
    if ($collect_vm_stag_members -eq "y") {
        
        # Retrieve a list of all Tag Assignments
        $tag_assign = $ST | Get-NsxSecurityTagAssignment        
        
        foreach ($mem in $tag_assign){

            $sheet.Cells.Item($row,1) = $mem.SecurityTag.name
            $sheet.Cells.Item($row,2) = $mem.VirtualMachine.name
            $vm_id = $mem.VirtualMachine.ID.TrimStart("VirtualMachine-")
            $sheet.Cells.Item($row,3) = $vm_id
            $row++
        }
    }
    else {
        $sheet.Cells.Item($row,1) = "<Collection Disabled>"
        $sheet.Cells.Item($row,1).Font.ColorIndex = 3
        $sheet.Cells.Item($row,2) = "<Collection Disabled>"
        $sheet.Cells.Item($row,2).Font.ColorIndex = 3
    }
}

########################################################
#    Exclusion list Worksheet
########################################################

function ex_list_ws($sheet){

    $sheet.Cells.Item(1,1) = "Exclusion List"
    $sheet.Cells.Item(1,1).Font.Size = $titleFontSize
    $sheet.Cells.Item(1,1).Font.Bold = $titleFontBold
    $sheet.Cells.Item(1,1).Font.ColorIndex = $titleFontColorIndex
    $sheet.Cells.Item(1,1).Font.Name = $titleFontName
    $sheet.Cells.Item(1,1).Interior.ColorIndex = $titleInteriorColor
    $range1 = $sheet.Range("a1", "f1")
    $range1.merge() | Out-Null

    $sheet.Cells.Item(2,1) = "VM Name"
    $sheet.Cells.Item(2,2) = "VM ID"
    $range2 = $sheet.Range("a2", "b2")
    $range2.Font.Bold = $subTitleFontBold
    $range2.Interior.ColorIndex = $subTitleInteriorColor
    $range2.Font.Name = $subTitleFontName
    pop_ex_list_ws($sheet)
}

function pop_ex_list_ws($sheet){

    $row=3
    $guests = Get-NsxFirewallExclusionListMember

    foreach ($vm in $guests) {
        # $sheet.Cells.Item($row,1) = $vm.name
        $result = $vmaddressing_ht[$vm.id.TrimStart("VirtualMachine-")]        
        if([string]::IsNullOrWhiteSpace($result))
        {
             $sheet.Cells.Item($row,1) = $vm.name
             $sheet.Cells.Item($row,2) = $vm.id.TrimStart("VirtualMachine-")
        }
        else 
        {
            $link = $sheet.Hyperlinks.Add(
            $sheet.Cells.Item($row,1),
            "",
            $result,
            "Virtual Machine Information",
            $vm.name)
            $sheet.Cells.Item($row,2) = $vm.id.TrimStart("VirtualMachine-")
        }
        $row++ # Increment Rows
    }
}

########################################################
#    VM Addressing - First NIC IP Address
########################################################

function vm_ip_addresses_ws($sheet){

    $sheet.Cells.Item(1,1) = "Virtual Machine Addressing"
    $sheet.Cells.Item(1,1).Font.Size = $titleFontSize
    $sheet.Cells.Item(1,1).Font.Bold = $titleFontBold
    $sheet.Cells.Item(1,1).Font.ColorIndex = $titleFontColorIndex
    $sheet.Cells.Item(1,1).Font.Name = $titleFontName
    $sheet.Cells.Item(1,1).Interior.ColorIndex = $titleInteriorColor
    $range1 = $sheet.Range("a1", "f1")
    $range1.merge() | Out-Null

    $sheet.Cells.Item(2,1) = "VM Name"
    $sheet.Cells.Item(2,2) = "Guest IP Address"
    $sheet.Cells.Item(2,3) = "VM ID"
    $range2 = $sheet.Range("a2", "c2")
    $range2.Font.Bold = $subTitleFontBold
    $range2.Interior.ColorIndex = $subTitleInteriorColor
    $range2.Font.Name = $subTitleFontName
    pop_ip_address_ws($sheet)
}

function pop_ip_address_ws($sheet){

    $row=3
    $guests = Get-VM | Select Name, VMIPAddress, id

    foreach ($vm in $guests) {
        $sheet.Cells.Item($row,1) = $vm.name
        $sheet.Cells.Item($row,2) = $vm.VMIPAddress
        $vm_id = $vm.id.TrimStart("VirtualMachine-")
        $sheet.Cells.Item($row,3) = $vm_id
        try 
        {
            $link_ref = "VM_Info!" + ($sheet.Cells.Item($row,1)).address($false,$false)
            if($vmaddressing_ht.ContainsKey($vm_id) -eq $false)
            {
                $vmaddressing_ht.Add($vm_id, $link_ref)
            }
        }
        catch [Exception]{
            Write-Warning "already exists, manually create hyperlink reference"
        }

        $row++ # Increment Rows
    }
}

########################################################
#    Global Functions
########################################################

If (-not $DefaultNSXConnection) 
{
    
    Write-Warning "`nConnect to NSX Manager established"
    #$nsx_mgr = Read-Host "`nIP or FQDN of NSX Manager? "
    # Connect-NSXServer -NSXServer $nsx_mgr
    Connect-NSXServer -NSXServer 192.168.8.141 -Username admin -Password VMware1!VMware1!

}

$version = Get-NsxManagerSystemSummary
$major_version = $version.versionInfo.majorVersion

# Only tested to run on NSX 6.2.x & 6.3.x installations

if($major_version -eq 6){

    if ( $EnableIpDetection ) {
        $collect_vm_ips = "y"
        Write-Host "Collection of IP Addresses Enabled"
    } 
    elseif (-not $PSBoundParameters.ContainsKey("EnableIpDetection")) { 
        $collect_vm_ips = "n"
        Write-Warning "Collection of IP Addresses Disabled"
    }

    if ( $GetSecTagMembers ) {
        $collect_vm_stag_members= "y"
        Write-Host "Collection of Security Tag VM Membership Enabled"
    } 
    elseif (-not $PSBoundParameters.ContainsKey("GetSecTagMembers")) { 
        $collect_vm_stag_members = "n"
        Write-Warning "Collection of Security Tag VM Membership Disabled"
    }

    if ( $GetSecGrpMembers ) {
        $collect_vm_members = "y"
        Write-Host "Collection of Security Group VM Membership Enabled"
    } 
    elseif (-not $PSBoundParameters.ContainsKey("GetSecGrpMembers")) { 
        $collect_vm_members = "n"
        Write-Warning "Collection of Security Group VM Membership Disabled"
    }

    if ($collect_vm_ips -eq "y") {
        # Write-Host "Collection of IP Addresses Enabled"
        startExcel("y")
    }
    else{
        # Write-Warning "Collection of IP Addresses Disabled"
        startExcel("n")
    }
}
else{
        Write-Warning "nNSX Manager version is not in the NSX 6.x release train"
}