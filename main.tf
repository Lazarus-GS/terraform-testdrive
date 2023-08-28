terraform {
  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"
      version = ">= 1.26.0"
    }
  }
}

#Create the test VPC
resource "huaweicloud_vpc" "Terraform-test-Geethaka" {
    name = "Terraform-test-Geethaka"
    cidr = "192.168.0.0/16"
}

resource "huaweicloud_vpc_subnet" "subnet_001" {
    name = "subnet_001"
    cidr = "192.168.0.0/24"
    gateway_ip = "192.168.0.1"
    vpc_id = huaweicloud_vpc.Terraform-test-Geethaka.id
}

#create ecs
data "huaweicloud_availability_zones" "myaz" {
    region = "ap-southeast-1"
}
data "huaweicloud_compute_flavors" "myflavor" {
    availability_zone = data.huaweicloud_availability_zones.myaz.names[0]
    performance_type = "normal"
    cpu_core_count = 2
    memory_size = 4
}
data "huaweicloud_images_image" "myimage" {
    name = "Ubuntu 18.04 server 64bit"
    most_recent = true
}

# data "huaweicloud_vpc_subnet" "Terraform-test-Geethaka" {
#     name = "subnet_001"
# }


resource "random_password" "password" {
    length = 16
    special = true
    override_special = "!@#$%&*"
}

resource "huaweicloud_compute_instance" "ecs" {
    provider = huaweicloud
    name = "ecs-terraform"
    admin_pass = random_password.password.result
    image_id = data.huaweicloud_images_image.myimage.id
    flavor_id = data.huaweicloud_compute_flavors.myflavor.ids[0]
    availability_zone = data.huaweicloud_availability_zones.myaz.names[0]
    security_group_ids = [huaweicloud_networking_secgroup.mysecgroup.id]
    system_disk_type = "SAS"
    system_disk_size = 40
    user_data = base64encode(file("user_data.sh"))
    charging_mode = "postPaid"
    enterprise_project_id = "8ccfc768-35f9-4830-a687-9a258216f376"

    network {
        uuid = huaweicloud_vpc_subnet.subnet_001.id
        fixed_ip_v4 = "192.168.0.100"
    }
    depends_on = [
        huaweicloud_vpc_subnet.subnet_001
    ]
}
#create security group
resource "huaweicloud_networking_secgroup" "mysecgroup" {
    provider = huaweicloud
    name = "sec"
}
resource "huaweicloud_networking_secgroup_rule" "http" {
    description = "Enable for accessing HTTP trafiic from outside"
    direction = "ingress"
    ethertype = "IPv4"
    protocol = "tcp"
    port_range_min = 80
    port_range_max = 80
    remote_ip_prefix = "0.0.0.0/0"
    security_group_id = huaweicloud_networking_secgroup.mysecgroup.id
}
resource "huaweicloud_networking_secgroup_rule" "https" {
    description = "Enable for accessing HTTPS traffic from outside"
    direction = "ingress"
    ethertype = "IPv4"
    protocol = "tcp"
    port_range_min = 443
    port_range_max = 443
    remote_ip_prefix = "0.0.0.0/0"
    security_group_id = huaweicloud_networking_secgroup.mysecgroup.id
}
resource "huaweicloud_networking_secgroup_rule" "sg_rule_common" {
    direction = "ingress"
    ethertype = "IPv4"
    protocol = "icmp"
    security_group_id = huaweicloud_networking_secgroup.mysecgroup.id
}

