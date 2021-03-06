## Copyright (c) 2022, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_core_virtual_network" "OCI_ES_VCN" {
  cidr_block     = var.VCN-CIDR
  compartment_id = var.compartment_ocid
  display_name   = "OCI_ES_VCN"
  dns_label      = "OCIESVCN"
  defined_tags = {"${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}

resource "oci_core_internet_gateway" "OCI_ES_IGW" {
  compartment_id = var.compartment_ocid
  display_name   = "OCI_ES_IGW"
  vcn_id         = oci_core_virtual_network.OCI_ES_VCN.id
  defined_tags = {"${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}

resource "oci_core_nat_gateway" "OCI_ES_NATGW" {
  compartment_id = var.compartment_ocid
  display_name   = "OCI_ES_NATGW"
  vcn_id         = oci_core_virtual_network.OCI_ES_VCN.id
  defined_tags = {"${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}

resource "oci_core_route_table" "OCI_PUB_RTB" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.OCI_ES_VCN.id
  display_name   = "OCI_PUB_RTB"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.OCI_ES_IGW.id
  }
  defined_tags = {"${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}

resource "oci_core_route_table" "OCI_NAT_RTB" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.OCI_ES_VCN.id
  display_name   = "OCI_NAT_RTB"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.OCI_ES_NATGW.id
  }
  defined_tags = {"${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}

resource "oci_core_security_list" "LBSecList" {
  compartment_id = var.compartment_ocid
  display_name   = "LBSecList"
  vcn_id         = oci_core_virtual_network.OCI_ES_VCN.id

  egress_security_rules {
    protocol    = "6"
    destination = "0.0.0.0/0"
  }

  ingress_security_rules {
    tcp_options {
      max = var.ESDataPort
      min = var.ESDataPort
    }

    protocol = "6"
    source   = "0.0.0.0/0"
  }
  ingress_security_rules {
    tcp_options {
      max = var.KibanaPort
      min = var.KibanaPort
    }

    protocol = "6"
    source   = "0.0.0.0/0"
  }
  defined_tags = {"${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}

resource "oci_core_security_list" "PrivSecList" {
  compartment_id = var.compartment_ocid
  display_name   = "PrivSecList"
  vcn_id         = oci_core_virtual_network.OCI_ES_VCN.id

  egress_security_rules {
    protocol    = "6"
    destination = "0.0.0.0/0"
  }

  ingress_security_rules {
    tcp_options {
      max = var.ESDataPort
      min = var.ESDataPort
    }

    protocol = "6"
    source   = var.VCN-CIDR
  }
  ingress_security_rules {
    tcp_options {
      max = var.ESDataPort2
      min = var.ESDataPort2
    }

    protocol = "6"
    source   = var.VCN-CIDR
  }
  ingress_security_rules {
    tcp_options {
      max = var.KibanaPort
      min = var.KibanaPort
    }

    protocol = "6"
    source   = var.VCN-CIDR
  }
  ingress_security_rules {
    tcp_options {
      max = 22
      min = 22
    }

    protocol = "6"
    source   = var.VCN-CIDR
  }
  defined_tags = {"${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}

resource "oci_core_security_list" "BastionSecList" {
  compartment_id = var.compartment_ocid
  display_name   = "BastionSecList"
  vcn_id         = oci_core_virtual_network.OCI_ES_VCN.id

  egress_security_rules {
    protocol    = "6"
    destination = "0.0.0.0/0"
  }

  ingress_security_rules {
    tcp_options {
      max = 22
      min = 22
    }

    protocol = "6"
    source   = "0.0.0.0/0"
  }
  ingress_security_rules {
    protocol = "all"
    source   = var.VCN-CIDR
  }
  defined_tags = {"${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}

resource "oci_core_subnet" "LBSubnetAD1" {
  availability_domain = data.oci_identity_availability_domains.ADs.availability_domains[0]["name"]
  cidr_block          = var.LBSubnetAD1CIDR
  display_name        = "LBSubnetAD1"
  compartment_id      = var.compartment_ocid
  vcn_id              = oci_core_virtual_network.OCI_ES_VCN.id
  route_table_id      = oci_core_route_table.OCI_PUB_RTB.id
  security_list_ids   = [oci_core_security_list.LBSecList.id]
  dhcp_options_id     = oci_core_virtual_network.OCI_ES_VCN.default_dhcp_options_id
  dns_label           = "lbad1"
  defined_tags        = {"${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}

resource "oci_core_subnet" "LBSubnetAD2" {
  availability_domain = data.oci_identity_availability_domains.ADs.availability_domains[1]["name"]
  cidr_block          = var.LBSubnetAD2CIDR
  display_name        = "LBSubnetAD2"
  compartment_id      = var.compartment_ocid
  vcn_id              = oci_core_virtual_network.OCI_ES_VCN.id
  route_table_id      = oci_core_route_table.OCI_PUB_RTB.id
  security_list_ids   = [oci_core_security_list.LBSecList.id]
  dhcp_options_id     = oci_core_virtual_network.OCI_ES_VCN.default_dhcp_options_id
  dns_label           = "lbad2"
  defined_tags        = {"${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}

resource "oci_core_subnet" "PrivSubnetAD1" {
  availability_domain = data.oci_identity_availability_domains.ADs.availability_domains[0]["name"]
  cidr_block          = var.PrivSubnetAD1CIDR
  display_name        = "PrivateSubnetAD1"
  compartment_id      = var.compartment_ocid
  vcn_id              = oci_core_virtual_network.OCI_ES_VCN.id
  route_table_id      = oci_core_route_table.OCI_NAT_RTB.id
  security_list_ids   = [oci_core_security_list.PrivSecList.id]
  dhcp_options_id     = oci_core_virtual_network.OCI_ES_VCN.default_dhcp_options_id
  defined_tags        = {"${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }

  #prohibit_public_ip_on_vnic  = "true"
  dns_label = "privad1"
}

resource "oci_core_subnet" "PrivSubnetAD2" {
  availability_domain = data.oci_identity_availability_domains.ADs.availability_domains[1]["name"]
  cidr_block          = var.PrivSubnetAD2CIDR
  display_name        = "PrivateSubnetAD2"
  compartment_id      = var.compartment_ocid
  vcn_id              = oci_core_virtual_network.OCI_ES_VCN.id
  route_table_id      = oci_core_route_table.OCI_NAT_RTB.id
  security_list_ids   = [oci_core_security_list.PrivSecList.id]
  dhcp_options_id     = oci_core_virtual_network.OCI_ES_VCN.default_dhcp_options_id
  defined_tags        = {"${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }

  #prohibit_public_ip_on_vnic  = "true"
  dns_label = "privad2"
}

resource "oci_core_subnet" "PrivSubnetAD3" {
  availability_domain = data.oci_identity_availability_domains.ADs.availability_domains[2]["name"]
  cidr_block          = var.PrivSubnetAD3CIDR
  display_name        = "PrivateSubnetAD3"
  compartment_id      = var.compartment_ocid
  vcn_id              = oci_core_virtual_network.OCI_ES_VCN.id
  route_table_id      = oci_core_route_table.OCI_NAT_RTB.id
  security_list_ids   = [oci_core_security_list.PrivSecList.id]
  dhcp_options_id     = oci_core_virtual_network.OCI_ES_VCN.default_dhcp_options_id
  defined_tags        = {"${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }

  #prohibit_public_ip_on_vnic  = "true"
  dns_label = "privad3"
}

resource "oci_core_subnet" "BastionSubnetAD1" {
  availability_domain = data.oci_identity_availability_domains.ADs.availability_domains[0]["name"]
  cidr_block          = var.BastSubnetAD1CIDR
  display_name        = "BastionSubnetAD1"
  compartment_id      = var.compartment_ocid
  vcn_id              = oci_core_virtual_network.OCI_ES_VCN.id
  route_table_id      = oci_core_route_table.OCI_PUB_RTB.id
  security_list_ids   = [oci_core_security_list.BastionSecList.id]
  dhcp_options_id     = oci_core_virtual_network.OCI_ES_VCN.default_dhcp_options_id
  defined_tags        = {"${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
  dns_label           = "bastsub"
}

