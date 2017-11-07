ruleset manage_fleet {
	meta {
		name "CS 462 Fleet Manager"
		description <<
Ruleset for CS 462 Lab 7 - Reactive Programming: Multiple Picos"
>>
		logging on
    		shares __testing, fleet, vehicles, vehicles_trips, show_children
		use module io.picolabs.pico alias wrangler
		use module io.picolabs.subscription alias Subscription
  	}
  	global {
 		__testing = { 
			"queries": [ 
				{ 
					"name": "__testing" 
				},
				{
					"name": "fleet"
				},
				{
					"name": "vehicles"
				},
				{
					"name": "vehicles_trips"
				},
				{
					"name": "show_children"
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
			"Vehicle - " + vehicle_id + " - Pico"
		}

		childFromId = function(vehicle_id) {
			ent:vehicles[vehicle_id]
		}

		fleet = function() {
			ent:vehicles
		}
		
		vehicles = function() {
			Subscription:getSubscriptions()
		}

		vehicles_trips = function() {
			"Not Implemented"
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
					"vehicle_id": vehicle_id
				}
		}	
	}

	rule vehicle_already_exists {
		select when car new_vehicle
                pre {
                        vehicle_id = event:attr("vehicle_id")
                        exists = ent:vehicles >< vehicle_id
                }

                if exists then
			send_directive("vehicle_ready", {
				"vehicle_id": vehicle_id
			})

		
	}

	rule pico_child_initialized {
		select when wrangler child_initialized
		pre {
			the_vehicle_eci = event:attr("eci");
			the_vehicle_id = event:attr("id");
			vehicle_id = event:attr("rs_attrs") {"vehicle_id"};
		}
		if vehicle_id.klog("found vehicle_id: ") then every {
			event:send({ 
				"eci": the_vehicle_eci,
				"eid": "install-ruleset",
				"domain": "pico",
				"type": "new_ruleset",
				"attrs": {
					"rids": "track_trips;io.picolabs.subscription",
					// Leaving the URL here because installing from URL is not working properly
					"url": "https://raw.githubusercontent.com/cache117/cs462-pico-multiple/master/track_trips.krl",
					"vehicle_id": vehicle_id
				}
			});
		}
		fired {
			ent:vehicles := ent:vehicles.defaultsTo({});
			ent:vehicles{[vehicle_id]} := {
				"eci":the_vehicle_eci, 
				"id": the_vehicle_id
			};
			raise wrangler event "subscription" 
				attributes {
                                        "name": "Vehicle - " + vehicle_id + " - Subscription",
                                        "name_space": "vehicle",
                                        "my_role": "controller",
                                        "subscriber_role": "vehicle",
                                        "channel_type": "subscription",
                                        "subscriber_eci": the_vehicle_eci
                                }; 
		}
	}

	rule delete_vehicle {
		select when car unneeded_vehicle
		pre {
			vehicle_id = event:attr("vehicle_id").klog("Vehicle Id: ")
			exists = ent:vehicles >< vehicle_id.klog("Exists: ")
			eci = meta:eci.klog("Eci: ")
			child_to_delete = childFromId(vehicle_id).klog("Vehicle to Delete: ")
		}
		if exists then
			send_directive("vehicle_deleted", {
				"vehicle_id": vehicle_id
			})
		fired {
			raise pico event "delete_child_request"
				attributes child_to_delete;
			ent:vehicles{[vehicle_id]} := null
		}
	}

	rule collection_empty {
		select when collection empty
		always {
			ent:vehicles := {}
		}
	}	
}

