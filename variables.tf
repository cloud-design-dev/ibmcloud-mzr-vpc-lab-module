variable "region" {
  description = "The region where the VPC will be deployed. If not specified, the default is us-south."
  type        = string
  default     = "us-south"
}

variable "existing_resource_group" {
  description = "Existing resource group to use for the VPC and related resources. If not set, a new resource group will be created."
  type        = string
}

variable "existing_ssh_key" {
  description = "Existing SSH key to use for the VPC. If not set, a new SSH key will be created."
  type        = string
  default     = ""
}

variable "default_address_prefix" {
  description = "Indicates whether a default address prefix should be created automatically auto or manually manual for each zone in this VPC. Default value is auto"
  type        = string
  default     = "auto"
}

variable "classic_access" {
  description = "Whether or not to enable classic access for the VPC. Default is false."
  type        = bool
  default     = false
}

variable "enable_bastion" {
  description = "Whether or not to enable a bastion host. Default is false."
  type        = bool
  default     = false
}

variable "owner" {
  description = "Owner tag to attach to all deployed resources. Will be added in the format `owner:<owner>`."
  type        = string
}

variable "project_prefix" {
  description = "Prefix to use for resource names. If not set, a random string will be generated."
  type        = string
  default     = ""
}

variable "init_script" {
  description = "Path to the init script to run on the bastion host. If not set, a simple script will be used to update the system and install the IBM Cloud CLI and tools."
  type        = string
  default     = ""
}

variable "metadata_service" {
  type = object({
    enabled            = bool
    protocol           = string
    response_hop_limit = number
  })

  default = {
    enabled            = true
    protocol           = "https"
    response_hop_limit = 3
  }
}

variable "allow_ip_spoofing" {
  description = "Allow IP Spoofing on the network interface. Default is true."
  type        = bool
  default     = true
}

variable "instance_profile" {
  description = "Compute instance profile to use for the instance. See https://cloud.ibm.com/docs/vpc?topic=vpc-profiles for more information. If you have the IBM Cloud CLI installed, you can run 'ibmcloud is instance-profiles' to list available profiles."
  type        = string
  default     = "cx2-2x4"
}

variable "image_name" {
  description = "The name of an existing OS image to use. You can list available images with the command 'ibmcloud is images'."
  type        = string
  default     = "ibm-ubuntu-22-04-2-minimal-amd64-1"
}

variable "number_of_addresses" {
  description = "Number of IPs to assign for each subnet."
  type        = number
  default     = 64
  validation {
    condition     = contains([8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384], var.number_of_addresses)
    error_message = "Error: Incorrect value for number_of_addresses. Allowed values are 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384."
  }
}

variable "frontend_rules" {
  description = "A list of security group rules to be added to the Frontend security group"
  type = list(
    object({
      name      = string
      direction = string
      remote    = string
      tcp = optional(
        object({
          port_max = optional(number)
          port_min = optional(number)
        })
      )
      udp = optional(
        object({
          port_max = optional(number)
          port_min = optional(number)
        })
      )
      icmp = optional(
        object({
          type = optional(number)
          code = optional(number)
        })
      )
    })
  )

  validation {
    error_message = "Security group rules can only have one of `icmp`, `udp`, or `tcp`."
    condition = (var.frontend_rules == null || length(var.frontend_rules) == 0) ? true : length(distinct(
      # Get flat list of results
      flatten([
        # Check through rules
        for rule in var.frontend_rules :
        # Return true if there is more than one of `icmp`, `udp`, or `tcp`
        true if length(
          [
            for type in ["tcp", "udp", "icmp"] :
            true if rule[type] != null
          ]
        ) > 1
      ])
    )) == 0 # Checks for length. If all fields all correct, array will be empty
  }

  validation {
    error_message = "Security group rule direction can only be `inbound` or `outbound`."
    condition = (var.frontend_rules == null || length(var.frontend_rules) == 0) ? true : length(distinct(
      flatten([
        # Check through rules
        for rule in var.frontend_rules :
        # Return false if direction is not valid
        false if !contains(["inbound", "outbound"], rule.direction)
      ])
    )) == 0
  }

  validation {
    error_message = "Security group rule names must match the regex pattern ^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$."
    condition = (var.frontend_rules == null || length(var.frontend_rules) == 0) ? true : length(distinct(
      flatten([
        # Check through rules
        for rule in var.frontend_rules :
        # Return false if direction is not valid
        false if !can(regex("^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$", rule.name))
      ])
    )) == 0
  }

  default = [
    {
      name       = "inbound-http"
      direction  = "inbound"
      remote     = "0.0.0.0/0"
      ip_version = "ipv4"
      tcp = {
        port_min = 80
        port_max = 80
      }
    },
    {
      name       = "inbound-https"
      direction  = "inbound"
      remote     = "0.0.0.0/0"
      ip_version = "ipv4"
      tcp = {
        port_min = 443
        port_max = 443
      }
    },
    {
      name       = "inbound-ssh"
      direction  = "inbound"
      remote     = "0.0.0.0/0"
      ip_version = "ipv4"
      tcp = {
        port_min = 22
        port_max = 22
      }
    },
    {
      name       = "inbound-icmp"
      direction  = "inbound"
      remote     = "0.0.0.0/0"
      ip_version = "ipv4"
      icmp = {
        code = 0
        type = 8
      }
    },
    {
      name       = "http-outbound"
      direction  = "outbound"
      remote     = "0.0.0.0/0"
      ip_version = "ipv4"
      tcp = {
        port_min = 80
        port_max = 80
      }
    },
    {
      name       = "https-outbound"
      direction  = "outbound"
      remote     = "0.0.0.0/0"
      ip_version = "ipv4"
      tcp = {
        port_min = 443
        port_max = 443
      }
    },
    {
      name       = "iaas-services-outbound"
      direction  = "outbound"
      remote     = "161.26.0.0/16"
      ip_version = "ipv4"
    },
    {
      name       = "cloud-services-outbound"
      direction  = "outbound"
      remote     = "166.8.0.0/14"
      ip_version = "ipv4"
    }
  ]
}