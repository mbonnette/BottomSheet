//
//  Trip+.swift
//
//
//  Created by Michael Bonnette on 9/23/18.
//

import Foundation
import CoreData
import MapKit


//MARK:______________________________
//MARK: CLASS routines


public enum TransportTypes: Int32 {
	case driving = 0
	case walking = 1
	case transit = 2
	case driveWalk = 3
	case transitWalk = 4
	case driveTransitWalk = 5
	case unknown = 99
}


extension Trip  {

	//MARK:______________________________
	//MARK: CLASS routines
	
	static func newTrip(inContext context:NSManagedObjectContext) -> Trip {
		let trip = NSEntityDescription.insertNewObject(forEntityName: "Trip", into:context) as! Trip
		return trip
	}
	

	static var defaultSortDescriptors: [NSSortDescriptor] {
		return ([NSSortDescriptor(key: "arrivalTime", ascending: false)])
	}
	
	
	static var sortedFetchRequest: NSFetchRequest<Trip> {
		let request: NSFetchRequest<Trip> = Trip.fetchRequest()
		request.sortDescriptors = Trip.defaultSortDescriptors
		return request
	}
	
	
	static var allTrips: [Trip]? {
		var trips:[Trip]? = nil
		do {
			trips = try PersistentContainerSingleton.shared.persistentContainer.viewContext.fetch(Trip.sortedFetchRequest)
		}
		catch {
			print("!!!!!!!!!!!!!!No trips received and a throw was hit: \(error)")
		}
		return trips
	}
	
	
	static func findTrips(from begin:CLLocationCoordinate2D,to end:CLLocationCoordinate2D) -> [Trip]? {
		var trips:[Trip]? = nil
		let request = sortedFetchRequest
		request.predicate = NSPredicate(format: "abs(startLocation.latitude)-%f < 0.01 AND abs(startLocation.longitude)-%f < 0.01 AND abs(stopLocation.latitude)-%f < 0.01 AND abs(stopLocation.longitude)-%f < 0.01",abs(begin.latitude),abs(begin.longitude),abs(end.latitude),abs(end.longitude))
		print(request as Any)
		do {
			trips = try PersistentContainerSingleton.shared.persistentContainer.viewContext.fetch(request)
		}
		catch {
			print("!!!!!!!!!!!!!!No trips received and a throw was hit: \(error)")
		}
		return trips
	}
	
	static func findFastestTrip(from begin:CLLocationCoordinate2D,to end:CLLocationCoordinate2D) -> Trip? {
		var trips:[Trip]? = Trip.findTrips(from:begin, to:end)
		if (trips?.count ?? 0 >= 1) {
			return trips![0]
		}
		else {
			return nil
		}
	}
	
	static func getAllTripsResultsController() -> NSFetchedResultsController<Trip> {
		let controller = NSFetchedResultsController(fetchRequest: Trip.sortedFetchRequest,
													managedObjectContext: PersistentContainerSingleton.shared.persistentContainer.viewContext,
													sectionNameKeyPath: nil, cacheName: nil)
		do {
			try controller.performFetch()
			print("Existing number of trips",controller.fetchedObjects!.count as Any)
		} catch {
			let nserror = error as NSError
			fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
		}
		return controller
	}

	
	//MARK:______________________________
	//MARK: OBJECT routines
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
			let localResponseIdentifier	= tripDictionary["response_id"] as? String,
			let localTripType			= tripDictionary["mobi_identifier"] as? String

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
		self.tripType			= Segment.transportTypeEnum(localTripType)

		//??? Not stored
		//		"mobi_score": 0,
		//		"to_drop": false,
		//		"is_awesome": false,
	}

}
