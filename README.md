# Module for base VPC lab environment

<!-- BEGIN_TF_DOCS -->
## Resources

| Name | Type |
|------|------|
| [ibm_is_floating_ip.bastion](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.60.0-beta0/docs/resources/is_floating_ip) | resource |
| [ibm_is_instance.bastion](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.60.0-beta0/docs/resources/is_instance) | resource |
| [ibm_is_public_gateway.regional](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.60.0-beta0/docs/resources/is_public_gateway) | resource |
| [ibm_is_ssh_key.generated_key](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.60.0-beta0/docs/resources/is_ssh_key) | resource |
| [ibm_is_subnet.backend](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.60.0-beta0/docs/resources/is_subnet) | resource |
| [ibm_is_subnet.frontend](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.60.0-beta0/docs/resources/is_subnet) | resource |
| [ibm_is_vpc.vpc](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.60.0-beta0/docs/resources/is_vpc) | resource |
| [null_resource.create_private_key](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_string.prefix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [tls_private_key.ssh](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [ibm_is_image.base](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.60.0-beta0/docs/data-sources/is_image) | data source |
| [ibm_is_ssh_key.sshkey](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.60.0-beta0/docs/data-sources/is_ssh_key) | data source |
| [ibm_is_zones.regional](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.60.0-beta0/docs/data-sources/is_zones) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allow_ip_spoofing"></a> [allow\_ip\_spoofing](#input\_allow\_ip\_spoofing) | Allow IP Spoofing on the network interface. Default is true. | `bool` | `true` | no |
| <a name="input_classic_access"></a> [classic\_access](#input\_classic\_access) | Whether or not to enable classic access for the VPC. Default is false. | `bool` | `false` | no |
| <a name="input_default_address_prefix"></a> [default\_address\_prefix](#input\_default\_address\_prefix) | Indicates whether a default address prefix should be created automatically auto or manually manual for each zone in this VPC. Default value is auto | `string` | `"auto"` | no |
| <a name="input_enable_bastion"></a> [enable\_bastion](#input\_enable\_bastion) | Whether or not to enable a bastion host. Default is false. | `bool` | `false` | no |
| <a name="input_existing_resource_group"></a> [existing\_resource\_group](#input\_existing\_resource\_group) | Existing resource group to use for the VPC and related resources. If not set, a new resource group will be created. | `string` | n/a | yes |
| <a name="input_existing_ssh_key"></a> [existing\_ssh\_key](#input\_existing\_ssh\_key) | Existing SSH key to use for the VPC. If not set, a new SSH key will be created. | `string` | `""` | no |
| <a name="input_image_name"></a> [image\_name](#input\_image\_name) | The name of an existing OS image to use. You can list available images with the command 'ibmcloud is images'. | `string` | `"ibm-ubuntu-22-04-2-minimal-amd64-1"` | no |
| <a name="input_init_script"></a> [init\_script](#input\_init\_script) | Path to the init script to run on the bastion host. If not set, a simple script will be used to update the system and install the IBM Cloud CLI and tools. | `string` | `""` | no |
| <a name="input_instance_profile"></a> [instance\_profile](#input\_instance\_profile) | Compute instance profile to use for the instance. See https://cloud.ibm.com/docs/vpc?topic=vpc-profiles for more information. If you have the IBM Cloud CLI installed, you can run 'ibmcloud is instance-profiles' to list available profiles. | `string` | `"cx2-2x4"` | no |
| <a name="input_metadata_service"></a> [metadata\_service](#input\_metadata\_service) | n/a | <pre>object({<br>    enabled            = bool<br>    protocol           = string<br>    response_hop_limit = number<br>  })</pre> | <pre>{<br>  "enabled": true,<br>  "protocol": "https",<br>  "response_hop_limit": 3<br>}</pre> | no |
| <a name="input_number_of_addresses"></a> [number\_of\_addresses](#input\_number\_of\_addresses) | Number of IPs to assign for each subnet. | `number` | `64` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner tag to attach to all deployed resources. Will be added in the format `owner:<owner>`. | `string` | n/a | yes |
| <a name="input_project_prefix"></a> [project\_prefix](#input\_project\_prefix) | Prefix to use for resource names. If not set, a random string will be generated. | `string` | `""` | no |
| <a name="input_region"></a> [region](#input\_region) | The region where the VPC will be deployed. If not specified, the default is us-south. | `string` | `"us-south"` | no |
| <a name="input_frontend_rules"></a> [frontend\_rules](#input\_frontend\_rules) | A list of security group rules to be added to the Frontend security group | <pre>list(<br>    object({<br>      name      = string<br>      direction = string<br>      remote    = string<br>      tcp = optional(<br>        object({<br>          port_max = optional(number)<br>          port_min = optional(number)<br>        })<br>      )<br>      udp = optional(<br>        object({<br>          port_max = optional(number)<br>          port_min = optional(number)<br>        })<br>      )<br>      icmp = optional(<br>        object({<br>          type = optional(number)<br>          code = optional(number)<br>        })<br>      )<br>    })<br>  )</pre> | <pre>[<br>  {<br>    "direction": "inbound",<br>    "ip_version": "ipv4",<br>    "name": "inbound-http",<br>    "remote": "0.0.0.0/0",<br>    "tcp": {<br>      "port_max": 80,<br>      "port_min": 80<br>    }<br>  },<br>  {<br>    "direction": "inbound",<br>    "ip_version": "ipv4",<br>    "name": "inbound-https",<br>    "remote": "0.0.0.0/0",<br>    "tcp": {<br>      "port_max": 443,<br>      "port_min": 443<br>    }<br>  },<br>  {<br>    "direction": "inbound",<br>    "ip_version": "ipv4",<br>    "name": "inbound-ssh",<br>    "remote": "0.0.0.0/0",<br>    "tcp": {<br>      "port_max": 22,<br>      "port_min": 22<br>    }<br>  },<br>  {<br>    "direction": "inbound",<br>    "icmp": {<br>      "code": 0,<br>      "type": 8<br>    },<br>    "ip_version": "ipv4",<br>    "name": "inbound-icmp",<br>    "remote": "0.0.0.0/0"<br>  },<br>  {<br>    "direction": "outbound",<br>    "ip_version": "ipv4",<br>    "name": "http-outbound",<br>    "remote": "0.0.0.0/0",<br>    "tcp": {<br>      "port_max": 80,<br>      "port_min": 80<br>    }<br>  },<br>  {<br>    "direction": "outbound",<br>    "ip_version": "ipv4",<br>    "name": "https-outbound",<br>    "remote": "0.0.0.0/0",<br>    "tcp": {<br>      "port_max": 443,<br>      "port_min": 443<br>    }<br>  },<br>  {<br>    "direction": "outbound",<br>    "ip_version": "ipv4",<br>    "name": "iaas-services-outbound",<br>    "remote": "161.26.0.0/16"<br>  },<br>  {<br>    "direction": "outbound",<br>    "ip_version": "ipv4",<br>    "name": "cloud-services-outbound",<br>    "remote": "166.8.0.0/14"<br>  }<br>]</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_backend_subnet_id"></a> [backend\_subnet\_id](#output\_backend\_subnet\_id) | Backend subnet IDs. |
| <a name="output_bastion_instance_id"></a> [bastion\_instance\_id](#output\_bastion\_instance\_id) | The ID of the bastion instance (if created). |
| <a name="output_bastion_instance_ip"></a> [bastion\_instance\_ip](#output\_bastion\_instance\_ip) | The Public IP of the bastion instance (if created). |
| <a name="output_frontend_security_group_id"></a> [frontend\_security\_group\_id](#output\_frontend\_security\_group\_id) | Frontend Security group ID. |
| <a name="output_frontend_subnet_ids"></a> [frontend\_subnet\_ids](#output\_frontend\_subnet\_ids) | Frontend subnet IDs. |
| <a name="output_vpc_crn"></a> [vpc\_crn](#output\_vpc\_crn) | The VPCs CRN. |
| <a name="output_vpc_default_routing_table_id"></a> [vpc\_default\_routing\_table\_id](#output\_vpc\_default\_routing\_table\_id) | ID of the VPCs default routing table. |
| <a name="output_vpc_default_security_group_id"></a> [vpc\_default\_security\_group\_id](#output\_vpc\_default\_security\_group\_id) | ID of the VPCs default security group. |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The VPC ID. |
<!-- END_TF_DOCS -->