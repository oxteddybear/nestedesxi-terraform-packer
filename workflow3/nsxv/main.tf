provider "vsphere" {
  user           = var.vsphere_user
  password       = var.vsphere_password
  vsphere_server = var.vsphere_server

  allow_unverified_ssl = true
}

resource "vsphere_datacenter" "target_dc" {
  name = var.vsphere_datacenter
}

######update this fingerprint block for as many 
data "vsphere_host_thumbprint" "finger0" {
  address = var.all_hosts[0]
  insecure = true
}

data "vsphere_host_thumbprint" "finger1" {
  address = var.all_hosts[1]
  insecure = true
}

locals {
  fingerprint= [
    data.vsphere_host_thumbprint.finger0.id,
    data.vsphere_host_thumbprint.finger1.id
  ]

}

resource "vsphere_compute_cluster" "c1" {
  name            = var.compute_cluster
  datacenter_id   = vsphere_datacenter.target_dc.moid
  #depends_on = [vsphere_datacenter.target_dc,]

}

resource "vsphere_host" "hostmember" {
  count = length(var.addhost.name)
  hostname = var.addhost.name[count.index]
  username = var.esxi_user
  password = var.esxi_password
  thumbprint = local.fingerprint[count.index]
  cluster = vsphere_compute_cluster.c1.id
  #depends_on = [vsphere_compute_cluster.c1]
}


#############################1st vds
#create mgt vds
resource "vsphere_distributed_virtual_switch" "vds1" {
  name          = var.vds1_name
  datacenter_id = vsphere_datacenter.target_dc.moid
  max_mtu       = var.vds1_mtu
  #depends_on = [vsphere_host.hostmember] this is needed if nothing in this resource accesses the hostmember resource. https://www.terraform.io/docs/language/meta-arguments/depends_on.html
  uplinks        = ["uplink1", "uplink2"]
  
  dynamic "host" {
    for_each = vsphere_host.hostmember
    content {
      host_system_id = host.value.id #here host.value.id = <dynamic "host">."value" <==tis is a keyword to get the value id.<attribute> you can view the attribute in the state
      devices        = var.mgt_vmnic
    }
  }
 
}

#create data vds
resource "vsphere_distributed_virtual_switch" "vds2" {
  name          = var.vds2_name
  datacenter_id = vsphere_datacenter.target_dc.moid
  max_mtu       = var.vds2_mtu
  uplinks       = ["uplink1", "uplink2"]
  
  dynamic "host" {
    for_each = vsphere_host.hostmember
    content {
      host_system_id = host.value.id #here host.value.id = <dynamic "host">."value" <==tis is a keyword to get the value id.<attribute> you can view the attribute in the state
      devices        = var.data_vmnic
    }
  }
 
}

# Creating distributed port groups

resource "vsphere_distributed_port_group" "pg1" {
  for_each = var.pg1
  name = each.key
  distributed_virtual_switch_uuid = vsphere_distributed_virtual_switch.vds1.id
  vlan_id = each.value
}

#############################2nd vds
#create data vds

# #create pg on second vds - here i'm hardcoding since it makes no sense to create just 1 variable for this custom trunk
resource "vsphere_distributed_port_group" "pg2" {
  name     = dpg-vdsdata-edgeuplink1
  distributed_virtual_switch_uuid = vsphere_distributed_virtual_switch.vds2.id

    vlan_range { #got this of the state file
        max_vlan = 4094
        min_vlan = 0
    }
}
