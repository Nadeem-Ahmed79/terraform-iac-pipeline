package main

# Policy 7: stateful resources must never be deleted (or replaced) by a plan
protected_types := {
	"kubernetes_stateful_set_v1",
	"kubernetes_persistent_volume_claim_v1",
	"aws_secretsmanager_secret",
	"aws_s3_bucket",
}

deny contains msg if {
	some rc in input.resource_changes
	rc.type in protected_types
	"delete" in rc.change.actions
	msg := sprintf("LIFECYCLE: %s would be DELETED %v. Protected resource: needs team approval.", [rc.address, rc.change.actions])
}
