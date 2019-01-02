# Copyright (c) 2017 SAP SE or an SAP affiliate company. All rights reserved. This file is licensed under the Apache Software License, v. 2 except as noted otherwise in the LICENSE file
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

variable "entry_count" {
  default = 0
}
variable "name_count" {
  default = 1
}
variable "target" {
  type = "string"
  default = ""
}
variable "targets" {
  type = "list"
  default = []
}
variable "name" {
  type = "string"
  default = ""
}
variable "names" {
  type = "list"
  default = [ ]
}

variable "type" {
  type = "string"
}
variable "ttl" {
  default = 300
}

variable "config" {
  type = "map"
}
variable "active" {
  default = false
}

variable "azuredns_clientid" {
  default = ""
}
variable "azuredns_client_secret" {
  default = ""
}
variable "azuredns_tenantid" {
  default = ""
}
variable "azuredns_subscription_id" {
  default = ""
}
variable "azuredns_region" {
  default = ""
}

module "azuredns" {
  source = "../../access/azure"
  access_info = "${var.config}"

  client_id = "${var.azuredns_clientid}"
  client_secret = "${var.azuredns_client_secret}"
  tenant_id = "${var.azuredns_tenantid}"
  subscription_id = "${var.azuredns_subscription_id}"
  region = "${var.azuredns_region}"
}

module "dns" {
  source = "../../condmap"

  if = "${lookup(var.config,"dns_type","") == "azuredns"}"
  then = "${merge(var.config,module.azuredns.access_info)}"  
  else = "${var.config}"
}

provider "azurerm" {
  alias     = "azuredns"
  version = "0.1.5"
  tenant_id = "${module.azuredns.tenant_id}"
  subscription_id = "${module.azuredns.subscription_id}"
  client_id = "${module.azuredns.client_id}"
  client_secret = "${module.azuredns.client_secret}"  
}


module "azuredns_zone_name" {
  source = "../../configurable"
  value  = "${lookup(var.config,"zone_name")}"
}

module "azuredns_resource_group_name" {
  source = "../../configurable"
  value  = "${lookup(var.config,"resource_group_name")}"
}

locals {
  names = "${compact(concat(list(var.name),var.names))}"
}
module "active" {
  source = "../../flag"
  option = "${var.active}"
}

resource "azurerm_dns_a_record" "record" {
  provider = "azurerm.azuredns"
  count    = "${module.active.if_active * var.name_count * (1 - signum(var.entry_count))}"  
  zone_name           = "${module.azuredns_zone_name.value}"
  resource_group_name = "${module.azuredns_resource_group_name.value}"
  name     = "${element(local.names,count.index)}"
  ttl      = "${var.ttl}"
  records  = ["${var.target}"]
}
resource "azurerm_dns_a_record" "records" {
  provider = "azurerm.azuredns"
  count    = "${module.active.if_active * var.entry_count }"  
  zone_name           = "${module.azuredns_zone_name.value}"
  resource_group_name = "${module.azuredns_resource_group_name.value}"
  name     = "${var.names[count.index]}"
  ttl      = "${var.ttl}"
  records  = ["${element(var.targets,count.index)}"]
}
