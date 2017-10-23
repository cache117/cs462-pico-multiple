ruleset manage_fleet {
	meta {
		name "CS 462 Fleet Manager"
		description <<
Ruleset for CS 462 Lab 7 - Reactive Programming: Multiple Picos"
>>
		logging on
    		shares __testing, vehicles, vehicles_trips, show_children
		use module io.picolabs.pico alias wrangler
  	}
  	global {
 		__testing = { 
			"queries": [ 
				{ 
					"name": "__testing" 
				},
				{
					"name": "vehicles"
				} 
			],
                  	"events": [
				{
					"domain": "car",
					"type": "new_vehicle",
					"attrs": [
						"vehicle_id"
					]
				},
				{
					"domain": "car",
					"type": "unneeded_vehicle",
					"attrs": [
						"vehicle_id"
					]
				}
	 		] 
		}

		nameFromId = function(vehicle_id) {
			"Vehicle " + vehicle_id + " Pico"
		}
		
		vehicles = function() {
		
		}

		vehicles_trips = function() {

		}

		show_children = function() {
			wrangler:children()
		}
  	}
	
	rule create_vehicle {
		select when car new_vehicle
		pre {
			vehicle_id = event:attr("vehicle_id")
			exists = ent:vehicles >< vehicle_id
		}

		if not exists then
			noop()

		fired {
			raise pico event "new_child_request"
				attributes {
					"dname": nameFromId(vehicle_id),
					"color": "#FF69B4",
					"vehicle": vehicle
				}
		}	
	}

	rule vehicle_already_exists {
		select when car new_vehicle
                pre {
                        vehicle_id = event:attr("vehicle_id")
                        exists = ent:cars >< car_id
                }

                if exists then
			send_directive("vehicle_ready", {
				"vehicle_id": vehicle_id
			})

		
	}

	rule pico_child_initialized {
		select when pico child_initialized
		pre {
			the_vehicle = event:attr("new_child")
			vehicle_id = event:attr("rs_attrs") {"vehicle_id"}
		}
		if vehicle_id.klog("found vehicle_id") then
			event:send (
				{ 
					"eci": the_vehicle.eci,
					"eid": "install-ruleset",
					"domain": "pico",
					"type": "new_ruleset",
					"attrs": {
						"base": meta:rulesetURI,
						"url": "https://raw.githubusercontent.com/cache117/cs462-pico-multiple/master/track_trips.krl",
						"vehicle_id": vehicle_id
					}
				}
			)
		fired {
			ent:vehicles := ent:vehicles.defaultsTo({});
			ent:vehicles{[vehicle_id]} := the_vehicle
		}
	}

	rule delete_vehicle {
		select when car unneeded_vehicle
		pre {
			vehicle_id = event:attr("vehicle_id")
			exists = ent:vehicles >< vehicle_id
		}
		if exists then
			noop()
		fired {
			ent:vehicles.delete([vehicle_id])
		}
	}


	rule collection_empty {
		select when collection empty
		always {
			ent:vehicles := {}
		}
	}	
}

