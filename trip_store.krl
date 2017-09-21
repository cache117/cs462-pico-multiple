ruleset trip_store {
	meta {
		name "CS 462 Trip Store Ruleset"
		description <<
Ruleset for CS 462 Lab 6 - Reactive Programming: Single Pico
>>
		author "Cache Staheli"
		logging on
		shares __testing, trips, long_trips, short_trips
		provides trips, long_trips, short_trips
	}
  
	global {
		
		//all_trips = {
		//	"sample": {
		//		"trip": { 
		//			"mileage": "120",
		//			"timestamp": "stamp"
		//		}
		//	}
		//}
		
		//long_trips = {
		//	"sample": {
		//		"trip": { 
		//			"mileage": "800",
		//			"timestamp": "stamp"
		//		}
		//	}
		//}
		
		trip_counter = "0"
		
		long_trip_counter = "0"
		
		__testing = {
			"queries": [
				{
					"name": "__testing"
				}
			],
			"events": [
				{
					"domain": "explicit",
					"type": "processed_trip",
					"attrs": ["mileage"]
				},	
				{
					"domain": "explicit",
					"type": "found_long_trip",
					"attrs": ["mileage"]
				},
				{
					"domain": "car",
					"type": "trip_reset"
				}			
			]
		}
		
		trips = function() {
			trips
		}
		
		long_trips = function() {
			long_trips
		}
		
		short_trips = function() {
			long_trips - trips
		}
	}
	
	rule collect_trips {
		select when explicit processed_trip
		pre {
			mileage = event:attr("mileage").klog("our passed in mileage ")
		}
		always {
		//	ent:trip_counter := ent:trip_counter + "1"
			ent:all_trips := ent:all_trips.put([ent:trip_counter, "trip", "mileage"], mileage)
			             	              .put([ent:trip_counter, "trip", "timestamp"], timestamp)
		}
	}
	
	rule collect_long_trips {
		select when explicit found_long_trip
		pre {
			mileage = event:attr("mileage").klog("our passed in mileage ")
		}
		always {
		//	ent:long_trip_counter := ent:trip_counter + "1"
			ent:long_trips := ent:long_trips.put([ent:long_trip_counter, "trip", "mileage"], mileage)
						        .put([ent:long_trip_counter, "trip", "timestamp"], timestamp)
		}
	}
	
	rule clear_trips {
		select when car trip_reset
		always {
			ent:trip_counter := "0"

			//ent:all_trips := {
			//	"sample": {
			//		"trip": { 
			//			"mileage": "120",
			//			"timestamp": "stamp"
			//		}
			//	}
			//}

			//ent:long_trips = {
			//	"sample": {
			//		"trip": { 
			//			"mileage": "800",
			//			"timestamp": "stamp"
			//		}
			//	}
			//}
		}
	}
}
