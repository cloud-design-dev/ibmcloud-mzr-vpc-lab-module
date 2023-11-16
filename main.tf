module "resource_group" {
  source                       = "git::https://github.com/terraform-ibm-modules/terraform-ibm-resource-group.git?ref=v1.1.1"
  resource_group_name          = var.existing_resource_group == null ? "${local.prefix}-resource-group" : null
  existing_resource_group_name = var.existing_resource_group
}

resource "random_string" "prefix" {
  count   = var.project_prefix != "" ? 0 : 1
  length  = 4
  special = false
  upper   = false
}

resource "tls_private_key" "ssh" {
  count     = var.existing_ssh_key != "" ? 0 : 1
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "ibm_is_ssh_key" "generated_key" {
  count          = var.existing_ssh_key != "" ? 0 : 1
  name           = "${local.prefix}-${var.region}-key"
  public_key     = tls_private_key.ssh[0].public_key_openssh
  resource_group = module.resource_group.resource_group_id
  tags           = local.tags
}

resource "null_resource" "create_private_key" {
  count = var.existing_ssh_key != "" ? 0 : 1
  provisioner "local-exec" {
    command = <<-EOT
      echo '${tls_private_key.ssh[0].private_key_pem}' > ./'${local.prefix}'.pem
      chmod 400 ./'${local.prefix}'.pem
    EOT
  }
}

resource "ibm_is_vpc" "vpc" {
  name                        = "${local.prefix}-vpc"
  resource_group              = module.resource_group.resource_group_id
  classic_access              = var.classic_access
  address_prefix_management   = var.default_address_prefix
  default_network_acl_name    = "${local.prefix}-default-network-acl"
  default_security_group_name = "${local.prefix}-default-security-group"
  default_routing_table_name  = "${local.prefix}-default-routing-table"
  tags                        = local.tags
}

resource "ibm_is_public_gateway" "regional" {
  count          = length(data.ibm_is_zones.regional.zones)
  name           = "${local.prefix}-pubgw-zone-${count.index + 1}"
  resource_group = module.resource_group.resource_group_id
  vpc            = ibm_is_vpc.vpc.id
  zone           = local.vpc_zones[count.index].zone
  tags           = concat(local.tags, ["zone:${local.vpc_zones[count.index].zone}"])
}

resource "ibm_is_subnet" "frontend" {
  count                    = length(data.ibm_is_zones.regional.zones)
  name                     = "${local.prefix}-frontend-subnet-zone-${count.index + 1}"
  resource_group           = module.resource_group.resource_group_id
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = local.vpc_zones[count.index].zone
  total_ipv4_address_count = var.number_of_addresses
  public_gateway           = ibm_is_public_gateway.regional[count.index].id
  tags                     = concat(local.tags, ["zone:${local.vpc_zones[count.index].zone}", "gateway_attached:true"])
}

resource "ibm_is_subnet" "backend" {
  count                    = length(data.ibm_is_zones.regional.zones)
  name                     = "${local.prefix}-backend-subnet-zone-${count.index + 1}"
  resource_group           = module.resource_group.resource_group_id
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = local.vpc_zones[count.index].zone
  total_ipv4_address_count = var.number_of_addresses
  tags                     = concat(local.tags, ["zone:${local.vpc_zones[count.index].zone}", "gateway_attached:false"])
}

module "frontend_security_group" {
  source                = "terraform-ibm-modules/vpc/ibm//modules/security-group"
  version               = "1.1.1"
  create_security_group = true
  name                  = "${local.prefix}-frontend-sg"
  vpc_id                = ibm_is_vpc.vpc.id
  resource_group_id     = module.resource_group.resource_group_id
  security_group_rules  = local.frontend_rules
}

resource "ibm_is_instance" "bastion" {
  count          = var.enable_bastion ? 1 : 0
  name           = "${local.prefix}-bastion"
  vpc            = ibm_is_vpc.vpc.id
  image          = data.ibm_is_image.base.id
  profile        = var.instance_profile
  resource_group = module.resource_group.resource_group_id

  # metadata_service {
  #   enabled            = true
  #   protocol           = "https"
  #   response_hop_limit = 5
  # }

  dynamic "metadata_service" {
    for_each = var.metadata_service.enabled ? [1] : []

    content {
      enabled            = var.metadata_service.enabled
      protocol           = var.metadata_service.protocol
      response_hop_limit = var.metadata_service.response_hop_limit
    }
  }

  boot_volume {
    auto_delete_volume = false
    size               = 250
    name               = "${local.prefix}-bastion-boot"
    tags               = concat(local.tags, ["zone:${local.vpc_zones[0].zone}"])
  }

  primary_network_interface {
    subnet            = ibm_is_subnet.frontend.0.id
    allow_ip_spoofing = var.allow_ip_spoofing
    security_groups   = [module.frontend_security_group.security_group_id[0]]
  }

  user_data = var.init_script != "" ? var.init_script : file("${path.module}/init-script.sh")

  zone = local.vpc_zones[0].zone
  keys = local.ssh_key_id
  tags = concat(local.tags, ["zone:${local.vpc_zones[0].zone}"])
}

resource "ibm_is_floating_ip" "bastion" {
  count          = var.enable_bastion ? 1 : 0
  name           = "${local.prefix}-bastion-ip"
  resource_group = module.resource_group.resource_group_id
  target         = ibm_is_instance.bastion.0.primary_network_interface[0].id
  tags           = concat(local.tags, ["zone:${local.vpc_zones[0].zone}"])
}