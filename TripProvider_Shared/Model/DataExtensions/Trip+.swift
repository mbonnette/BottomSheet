//
//  Trip+.swift
//
//
//  Created by Michael Bonnette on 9/23/18.
//

import Foundation
import CoreData


//MARK:______________________________
//MARK: CLASS routines



extension Trip  {

	//MARK:______________________________
	//MARK: CLASS routines
	
	static func newTrip(inContext context:NSManagedObjectContext) -> Trip {

		let trip = NSEntityDescription.insertNewObject(forEntityName: "Trip", into:context) as! Trip

		return trip
	}
	
	public override func awakeFromFetch() {
		super.awakeFromFetch()
	}

	
	/**
	A convenience method to update a trip object with a dictionary.
	
	Note: Only updating the high level items for now... segments still handled by provider object
	*/
	func update(with tripDictionary: [AnyHashable: Any], inContext context:NSManagedObjectContext) throws {
		
		guard let localId = tripDictionary["id"] as? String,
			
			let localDescription		= tripDictionary["description"] as? String,
			let localDepartureTime		= tripDictionary["departure_time"] as? NSNumber,
			let localArrivalTime		= tripDictionary["arrival_time"] as? NSNumber,
			let localTotalTime			= tripDictionary["time"] as? NSNumber,
			let localTotalDistance		= tripDictionary["distance"] as? NSNumber,
			let localWalkingTime		= tripDictionary["walking_time"] as? NSNumber,
			let localWalkingDistance	= tripDictionary["walking_distance"] as? NSNumber,
			let localBikingTime			= tripDictionary["biking_time"] as? NSNumber,
			let localBikingDistance		= tripDictionary["biking_distance"] as? NSNumber,
			let localDrivingTime		= tripDictionary["driving_time"] as? NSNumber,
			let localDrivingDistance	= tripDictionary["driving_distance"] as? NSNumber,
			let localCost				= tripDictionary["cost"] as? NSNumber,
			let localCo2				= tripDictionary["co2"] as? NSNumber,
			let localCalories			= tripDictionary["calories"] as? NSNumber,
			let localResponseIdentifier	= tripDictionary["response_id"] as? String
		
		else {
			let description = NSLocalizedString("Missing basic trip information -- doesn't look like a mobi payload", comment: "")
			throw NSError(domain: locationsErrorDomain, code: TripProviderErrorCode.wrongDataFormat.rawValue, userInfo: [NSLocalizedDescriptionKey: description])
		}

		self.identifier 		= localId
		self.desc 				= localDescription
		self.departureTime		= Int64(truncating: localDepartureTime)
		self.arrivalTime		= Int64(truncating: localArrivalTime)
		self.totalTime			= Int64(truncating: localTotalTime)
		self.totalDistance		= Int32(truncating: localTotalDistance)
		self.walkingTime		= Int64(truncating: localWalkingTime)
		self.walkingDistance	= Int32(truncating: localWalkingDistance)
		self.bikingTime			= Int32(truncating: localBikingTime)
		self.bikingDistance		= Int32(truncating: localBikingDistance)
		self.drivingTime		= Int64(truncating: localDrivingTime)
		self.drivingDistance	= Int32(truncating: localDrivingDistance)
		self.cost				= Float(truncating: localCost)
		self.co2				= Int32(truncating: localCo2)
		self.calories			= Int32(truncating: localCalories)
		self.responseIdentifier	= localResponseIdentifier

		//??? Not stored
		//		"mobi_score": 0,
		//		"to_drop": false,
		//		"is_awesome": false,
		//		"mobi_identifier": "driving"
	}

}
