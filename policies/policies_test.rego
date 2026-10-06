package main

# ---------- Small fake plans used by the tests ----------
good_tags := {"owner": "team", "env": "dev", "project": "demo"}

sg_plan(cidr, from, to) := {"resource_changes": [{
	"address": "aws_security_group.test",
	"type": "aws_security_group",
	"change": {"actions": ["create"], "after": {
		"tags_all": good_tags,
		"ingress": [{"protocol": "tcp", "from_port": from, "to_port": to, "cidr_blocks": [cidr]}],
	}},
}]}

deploy_plan(image, non_root) := {"resource_changes": [{
	"address": "kubernetes_deployment_v1.test",
	"type": "kubernetes_deployment_v1",
	"change": {"actions": ["create"], "after": {"spec": [{"template": [{"spec": [{
		"security_context": [{"run_as_non_root": non_root}],
		"container": [{"name": "web", "image": image, "resources": [{"limits": {"cpu": "100m"}}]}],
	}]}]}]}},
}]}

# ---------- Tags ----------
test_missing_tag_is_denied if {
	plan := {"resource_changes": [{
		"address": "aws_vpc.test", "type": "aws_vpc",
		"change": {"actions": ["create"], "after": {"tags_all": {"env": "dev", "project": "demo"}}},
	}]}
	some msg in deny with input as plan
	contains(msg, "missing required tag 'owner'")
}

test_all_tags_present_is_allowed if {
	plan := {"resource_changes": [{
		"address": "aws_vpc.test", "type": "aws_vpc",
		"change": {"actions": ["create"], "after": {"tags_all": good_tags}},
	}]}
	count(deny) == 0 with input as plan
}

# ---------- Network ----------
test_ssh_open_to_world_is_denied if {
	some msg in deny with input as sg_plan("0.0.0.0/0", 22, 22)
	contains(msg, "SSH")
}

test_ssh_from_vpc_is_allowed if {
	count(deny) == 0 with input as sg_plan("10.0.0.0/16", 22, 22)
}

test_port_range_covering_22_is_denied if {
	some msg in deny with input as sg_plan("0.0.0.0/0", 0, 1024)
	contains(msg, "SSH")
}

test_https_open_to_world_is_allowed if {
	count(deny) == 0 with input as sg_plan("0.0.0.0/0", 443, 443)
}

# ---------- Kubernetes ----------
test_latest_image_is_denied if {
	some msg in deny with input as deploy_plan("nginx:latest", true)
	contains(msg, ":latest")
}

test_untagged_image_is_denied if {
	some msg in deny with input as deploy_plan("nginx", true)
	contains(msg, "without a version tag")
}

test_root_deployment_is_denied if {
	some msg in deny with input as deploy_plan("nginx:1.27", false)
	contains(msg, "run_as_non_root")
}

test_good_deployment_is_allowed if {
	count(deny) == 0 with input as deploy_plan("nginx:1.27", true)
}

# ---------- Lifecycle ----------
test_deleting_statefulset_is_denied if {
	plan := {"resource_changes": [{
		"address": "kubernetes_stateful_set_v1.db", "type": "kubernetes_stateful_set_v1",
		"change": {"actions": ["delete", "create"], "after": null},
	}]}
	some msg in deny with input as plan
	contains(msg, "DELETED")
}
