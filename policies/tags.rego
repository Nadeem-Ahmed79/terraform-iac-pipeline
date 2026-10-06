package main

# Policy 1: every taggable AWS resource must carry these tags
required_tags := {"owner", "env", "project"}

deny contains msg if {
	some rc in changes
	tags := object.get(rc.change.after, "tags_all", null)
	is_object(tags)
	some tag in required_tags
	not tags[tag]
	msg := sprintf("TAGS: %s is missing required tag '%s'", [rc.address, tag])
}
