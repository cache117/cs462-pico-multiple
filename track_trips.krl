ruleset track_trips {
	meta {
		name "CS 462 Track Trips Ruleset"
		description <<
Ruleset for CS 462 Lab 6 - Reactive Programming: Single Pico
>>
		author "Cache Staheli"
		logging on
		shares __testing
	}
  
	global {
		
		long_trip = "500"
		
		__testing = {
			"queries": [
				{
					"name": "__testing"
				}
			],
			"events": [
				{
					"domain": "car",
					"type": "new_trip",
					"attrs": ["mileage"]
				}
			]
		}
	}

	rule process_trip {
		select when car new_trip 
		pre {
			mileage = event:attr("mileage").klog("our passed in mileage ")
		}
		send_directive("trip", {"length": mileage})
		always {
			raise explicit event "trip_processed"
				attributes event:attrs()
		}
	}

	rule find_long_trips {
		select when explicit trip_processed
		pre {		
			mileage = event:attr("mileage").klog("our passed in mileage ")
		}
		always {
			ent:found := "true" if (mileage > long_trip);
			raise explicit event "found_long_trip" attributes {
				"mileage": mileage
			} if (mileage > long_trip);
		}
	}

	rule pico_ruleset_added {
		select when wrangler ruleset_added where rid == meta:rid
		pre {
			vehicle_id = event:attr("vehicle_id")
		}
		always {
			ent:vehicle_id := vehicle_id
		}
	}

	rule auto_accept {
		select when wrangler inbound_pending_subscription_added
		pre {
			attributes = event:attrs().klog("subscription:")
		}
		always {
			raise wrangler event "pending_subscription_approval"
			attributes attributes
		}
	}
}
