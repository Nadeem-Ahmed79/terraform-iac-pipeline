package main

# Every resource that will exist after apply (create, update or no-op)
changes contains rc if {
	some rc in input.resource_changes
	rc.change.after != null
}
