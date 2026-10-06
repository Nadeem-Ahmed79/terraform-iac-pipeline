package main

# Policy 2: SSH (port 22) must never be open to the whole internet
deny contains msg if {
	some rc in changes
	rc.type == "aws_security_group"
	some rule in rc.change.after.ingress
	rule.from_port <= 22
	rule.to_port >= 22
	"0.0.0.0/0" in rule.cidr_blocks
	msg := sprintf("NETWORK: %s opens SSH (22) to 0.0.0.0/0", [rc.address])
}

# Policy 3: "all traffic" rules open to the internet are never allowed
deny contains msg if {
	some rc in changes
	rc.type == "aws_security_group"
	some rule in rc.change.after.ingress
	rule.protocol == "-1"
	"0.0.0.0/0" in rule.cidr_blocks
	msg := sprintf("NETWORK: %s allows ALL traffic from 0.0.0.0/0", [rc.address])
}
