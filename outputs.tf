output "vpc_id" {
    description = "The VPC ID."
  value = ibm_is_vpc.vpc.id
}

output "vpc_crn" {
    description = "The VPCs CRN."
  value = ibm_is_vpc.vpc.crn
}

output "vpc_default_security_group_id" {
description = "ID of the VPCs default security group."
  value = ibm_is_vpc.vpc.default_security_group
}

output "vpc_default_routing_table_id" {
    description = "ID of the VPCs default routing table."
  value = ibm_is_vpc.vpc.default_routing_table
}

output "frontend_subnet_ids" {
    description = "Frontend subnet IDs."
  value = ibm_is_subnet.frontend.*.id
}

output "backend_subnet_id" {
    description = "Backend subnet IDs."
  value = ibm_is_subnet.backend.*.id
}

output "frontend_security_group_id" {
  description = "Frontend Security group ID."
  value = module.frontend_security_group.security_group_id
}

output "bastion_instance_id" {
    description = "The ID of the bastion instance (if created)."
  depends_on = [ibm_is_instance.bastion]
  value      = var.enable_bastion ? ibm_is_instance.bastion[0].id : null
}

output "bastion_instance_ip" {
    description = "The Public IP of the bastion instance (if created)."
  depends_on = [ibm_is_floating_ip.bastion]
  value      = var.enable_bastion ? ibm_is_floating_ip.bastion[0].address : null
}