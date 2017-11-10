ruleset track_trips {
	meta {
		name "CS 462 Track Trips Ruleset"
		description <<
Ruleset for CS 462 Lab 6 - Reactive Programming: Single Pico
>>
		author "Cache Staheli"
		logging on
		shares __testing, trips, long_trips, short_trips
		provides trips, long_trips, short_trips 
	}
  
	global {
		
		long_trip = 500;
		
		__testing = {
			"queries": [
				{
					"name": "__testing"
				},
                                {
                                        "name": "trips"
                                },
                                {
                                        "name": "long_trips"
                                },
                                {
                                        "name": "short_trips"
                                }	
			],
			"events": [
				{
					"domain": "car",
					"type": "new_trip",
					"attrs": ["mileage"]
				},
				{
					"domain": "fleet",
					"type": "report_needed" 
				}
			]
		}

		trips = function() {
			ent:trips.defaultsTo({});
		}

		long_trips = function() {
			ent:long_trips.defaultsTo({});
		}

		short_trips = function() {
			trips() - long_trips();
		}
	}

	rule process_trip {
		select when car new_trip 
		pre {
			mileage = event:attr("mileage").klog("mileage for trip processing");
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
			mileage = event:attr("mileage").klog("mileage for finding long trips ");
		}
		always {
			ent:found := "true" if (mileage > long_trip);
			raise explicit event "found_long_trip" attributes {
				"mileage": mileage
			} if (mileage > long_trip);
		}
	}

	rule collect_trips {
		select when explicit trip_processed
		pre {
			mileage = event:attr("mileage").klog("our passed in mileage for colleting trips ");
			trip_id = random:uuid();
			timestamp = time:now();
		}
		send_directive("store_trips", {
			"trip_id": trip_id,
			"mileage": mileage,
			"timestamp": timestamp
		});
		always {
			ent:trips := ent:trips.defaultsTo({});
			ent:trips{[trip_id]} := {
                        	"mileage": mileage,
                        	"timestamp": timestamp
			}
		}
	}

	rule collect_long_trips {
		select when explicit found_long_trip
                pre {
                        mileage = event:attr("mileage").klog("our passed in mileage for collecting long trips ");
                        trip_id = random:uuid();
                        timestamp = time:now();
                }
                send_directive("store_trips", {
                        "trip_id": trip_id,
                        "mileage": mileage,
                        "timestamp": timestamp
                });
                always {
                        ent:long_trips := ent:long_trips.defaultsTo({});
                        ent:long_trips{[trip_id]} := {
                                "mileage": mileage,
                                "timestamp": timestamp
                        }
                }

	}

	rule fleet_report_needed {
		select when fleet report_needed
		always {
			raise fleet event "report_ready"
				attributes {
					"vehicle_id": ent:vehicle_id,
					"trips": trips()
				};
		}
	}

	rule pico_ruleset_added {
		select when wrangler ruleset_added where rid == meta:rid or 
			    pico ruleset_added where rid == meta:rid
		pre {
			vehicle_id = event:attr("vehicle_id").klog("Ruleset added: vehicle Id ")
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
