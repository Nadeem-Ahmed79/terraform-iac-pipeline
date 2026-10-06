package main

workload_types := {"kubernetes_deployment_v1", "kubernetes_stateful_set_v1"}

pod_spec(rc) := rc.change.after.spec[0].template[0].spec[0]

containers contains [rc.address, c] if {
	some rc in changes
	rc.type in workload_types
	some c in pod_spec(rc).container
}

runs_as_non_root(rc) if {
	some sc in pod_spec(rc).security_context
	sc.run_as_non_root == true
}

has_limits(c) if {
	some r in c.resources
	count(r.limits) > 0
}

# Policy 4: images must be pinned (no :latest, no missing tag)
deny contains msg if {
	some [addr, c] in containers
	endswith(c.image, ":latest")
	msg := sprintf("K8S: %s uses image '%s' (:latest is not allowed)", [addr, c.image])
}

deny contains msg if {
	some [addr, c] in containers
	not contains(c.image, ":")
	not contains(c.image, "@")
	msg := sprintf("K8S: %s uses image '%s' without a version tag", [addr, c.image])
}

# Policy 5: every container needs resource limits
deny contains msg if {
	some [addr, c] in containers
	not has_limits(c)
	msg := sprintf("K8S: container '%s' in %s has no resource limits", [c.name, addr])
}

# Policy 6: Deployments must run as non-root
deny contains msg if {
	some rc in changes
	rc.type == "kubernetes_deployment_v1"
	not runs_as_non_root(rc)
	msg := sprintf("K8S: %s must set run_as_non_root = true", [rc.address])
}

# StatefulSets get a warning only (official database images start as root, then drop privileges)
warn contains msg if {
	some rc in changes
	rc.type == "kubernetes_stateful_set_v1"
	not runs_as_non_root(rc)
	msg := sprintf("K8S: %s does not set run_as_non_root (review before prod)", [rc.address])
}
