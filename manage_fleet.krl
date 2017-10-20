ruleset manage_fleet {
	meta {
		name "CS 462 Fleet Manager"
		description <<
Ruleset for CS 462 Lab 7 - Reactive Programming: Multiple Picos"
>>
		logging on
    		shares __testing, vehicles
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
					"attrs:" [
						"car_id"
					]
				},
				{
					"domain": "car",
					"type": "unneeded_vehicle",
					"attrs": [
						"car_id"
					]
				}
	 		] 
		}
		
		vehicles = function() {
		
		}

		vehicles_trips = function() {

		}
  	}
	
	rule create_vehicle {
		select when car new_vehicle
		
	}

	rule delete_vehicle {
		select when car unneeded_vehicle
	}
}

