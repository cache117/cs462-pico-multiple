ruleset app_section_collection {
	meta {
		name "CS 462 Section Collection"
		description <<
Ruleset for CS 462 Lab 7 - Reactive Programming: Multiple Picos"
>>
		author "Cache Staheli"
		logging on
		shares __testing, showChildren
		use module io.picolabs.pico alias wrangler
	}
	global {
		nameFromID = function(section_id) {
			"Section " + section_id + " Pico"
		}
		__testing = {
			"queries": [
				{
					"name": "showChildren"
				},
				{
					"name": "__testing"
				}
			],
			"events" : [
				{
					"domain": "section",
					"type": "needed",
					"attrs": [
						"section_id"
					]
				},
				{
					"domain": "collection",
					"type": "empty"
				}
			]
		}
		showChildren = function() {
			wrangler:children()
		}

		sections = function() {
			ent:sections
		}
	}
	rule section_needed {
  		select when section needed
  		pre {
    			section_id = event:attr("section_id")
    			exists = ent:sections >< section_id
  		}
  		if not exists then
			noop()
  		fired {
			raise pico event "new_child_request"
      				attributes {	"dname": nameFromID(section_id),
						"color": "#FF69B4",
						"section": section_id
				 }
  		}
	}

	rule section_already_exists {
		select when section needed
		pre {
			section_id = event:attr("section_id")
			exists = ent:sections >< section_id
		}
		if exists then
			send_directive("section_ready", {"section_id":section_id})
	}	
		
	rule pico_child_initialized {
		select when pico child_initialized
		pre {
			the_section = event:attr("new_child")
			section_id = event:attr("rs_attrs") {"section"}
		}
		if section_id.klog("found section_id") then
			event:send (
				{ 
					"eci": the_section.eci,
					"eid": "install-ruleset",
					"domain": "pico",
					"type": "new_ruleset",
					"attrs": {
						"base": meta:rulesetURI,
						"url": "app_section.krl",
						"section_id": section_id
					}
				}
			)
		fired {
			ent:sections := ent:sections.defaultsTo({});
			ent:sections{[section_id]} := the_section
		}
	}

	rule collection_empty {
		select when collection empty
		always {
			ent:sections := {}
		}
	}
}
