terraform {
  required_providers {
    nsxt = {
      source = "vmware/nsxt"
    }
  }
}

provider "nsxt" {
  host                  = "192.168.254.61"
  username              = "admin"
  password              = "VMware1!VMware1!"
  allow_unverified_ssl  = true
  max_retries           = 10
  retry_min_delay       = 500
  retry_max_delay       = 5000
  retry_on_status_codes = [429]
}

data "nsxt_policy_tier0_gateway" "t0-red" {
  display_name = "gw1"
}

data "nsxt_policy_edge_cluster" "ec" {
  display_name = "ec"
}

data "nsxt_policy_edge_node" "node1" {
  edge_cluster_path = data.nsxt_policy_edge_cluster.ec.path
  member_index      = 0
}
resource "nsxt_policy_vlan_segment" "seg-uplink36" {
  display_name = "seg-uplink36"
  vlan_ids     = [12]
}

resource "nsxt_policy_tier0_gateway_interface" "red_vrf_uplink1" {
  display_name   = "seg-uplink36"
  type           = "EXTERNAL"
  edge_node_path = data.nsxt_policy_edge_node.edge_node_1.path
  gateway_path   = nsxt_policy_tier0_gateway.red_vrf.path
  segment_path   = nsxt_policy_vlan_segment.vrf_trunk_1.path
  access_vlan_id = 112
  subnets        = ["192.168.112.254/24"]
  mtu            = 1500

  depends_on = [nsxt_policy_tier0_gateway_interface.parent_uplink1]
}