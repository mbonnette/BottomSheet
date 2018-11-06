//
//  Location+.swift
//
//
//  Created by Michael Bonnette on 9/23/18.
//

import Foundation
import CoreData
import MapKit


public enum locationTypes: Int32 {
	case temporary = 0
	case userSearched = 1
	case userPinned = 2
}


extension Location  {

	//MARK: - Equatable
//	public static func ==(lhs: Location, rhs: Location) -> Bool {
//		return lhs.address == rhs.address
//	}
//
	
	//MARK: - CLASS routines
	
	static func newLocation(inContext context:NSManagedObjectContext) -> Location {
		let location = NSEntityDescription.insertNewObject(forEntityName: "Location", into:context) as! Location
		location.locationType = locationTypes.temporary.rawValue
		return location
	}
	

	static func newLocation(named name:String?, withAddress address:String?, inContext context:NSManagedObjectContext) -> Location {
		let location = Location.newLocation(inContext:context)
		location.name = name
		location.address = address
		return location
	}
	

	static var defaultSortDescriptors: [NSSortDescriptor] {
		return ([NSSortDescriptor(key: "time", ascending: false)])
	}
	
	
	static var sortedFetchRequest: NSFetchRequest<Location> {
		let request: NSFetchRequest<Location> = Location.fetchRequest()
		request.sortDescriptors = Location.defaultSortDescriptors
		return request
	}
	
	
	static var allLocations: [Location] {
		var locations:[Location] = []
		do {
			locations = try PersistentContainerSingleton.shared.persistentContainer.viewContext.fetch(Location.sortedFetchRequest)
		}
		catch {
			print("!!!!!!!!!!!!!!No locations received and a throw was hit: \(error)")
		}
		return locations
	}
	static func allLocations(onContext:NSManagedObjectContext) -> [Location] {
		var locations:[Location] = []
		do {
			locations = try onContext.fetch(Location.sortedFetchRequest)
		}
		catch {
			print("!!!!!!!!!!!!!!No locations received and a throw was hit: \(error)")
		}
		return locations
	}
	
	static func findLocations(withRequest request:NSFetchRequest<Location>, inContext context:NSManagedObjectContext? = nil) -> [Location]? {
		var locations:[Location]? = nil
		let locContext = context ?? PersistentContainerSingleton.shared.persistentContainer.viewContext
		do {
			locations = try locContext.fetch(request)
		}
		catch {
			print("!!!!!!!!!!!!!!No location received and throw hit .. errno = : \(error)")
		}
		return locations
	}

	
	static func findLocation(withRequest request:NSFetchRequest<Location>, inContext context:NSManagedObjectContext? = nil) -> Location? {
		let locations:[Location]? = findLocations(withRequest: request, inContext:context)
		if (locations!.count >= 1) {
			return locations![0]
		}
		else {
			return nil
		}
	}

	static func findLocation(named name:String?, inContext context:NSManagedObjectContext? = nil) -> Location? {
		guard (name != nil) else { return nil }

		let request = Location.sortedFetchRequest
		request.predicate = NSPredicate(format: "name = %@", name!)
		return self.findLocation(withRequest:request, inContext:context)
	}

	static func findLocation(atAddress address:String?, inContext context:NSManagedObjectContext? = nil) -> Location? {
		guard (address != nil) else { return nil }

		let request = Location.sortedFetchRequest
		request.predicate = NSPredicate(format: "address = %@", address!)
		return self.findLocation(withRequest:request, inContext:context)
	}
	
	static func findLocation(at loc:CLLocationCoordinate2D, thatHasValidAddress:Bool = false, inContext context:NSManagedObjectContext? = nil) -> Location? {
		let request = sortedFetchRequest
		if (thatHasValidAddress) {
			request.predicate = NSPredicate(format: "abs(loc.latitude)-%f < 0.01 AND abs(loc.longitude)-%f < 0.01 AND address != nil ",abs(loc.latitude), abs(loc.longitude))
		}
		else {
			request.predicate = NSPredicate(format: "abs(loc.latitude)-%f < 0.01 AND abs(loc.longitude)-%f < 0.01 ",abs(loc.latitude), abs(loc.longitude))
		}
		return self.findLocation(withRequest:request, inContext:context)
	}
	
	static func missingAddressPredicate() -> NSPredicate {
		return NSPredicate(format: "address == nil")
	}
	
	static func missingNamePredicate() -> NSPredicate {
		return NSPredicate(format: "name = nil OR name = 'origin' OR name = 'destination'")
	}

	/// **findMissingAddressLocations**
	/// 		Retrieve locations that have a missing address and a name that appears to be well defined
	/// - Oct 21, 2018 at 9:51:53 PM
	/// - returns: Array of locations that are either missing an address or have a realistic name... e.g. user named the location
	static func findMissingAddressLocations(inContext context:NSManagedObjectContext? = nil) -> [Location]?  {
		let request = sortedFetchRequest
		request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates:[missingAddressPredicate(),
																			   missingNamePredicate()])
		return self.findLocations(withRequest:request, inContext:context)
	}
	
	
	static func getAddress(fromPlacemark placemark:CLPlacemark) -> String {
		var addressString = ""
		if placemark.isoCountryCode == "TW" /*Address Format in Chinese*/ {
			if placemark.country != nil {
				addressString = placemark.country!
			}
			if placemark.subAdministrativeArea != nil {
				addressString = addressString + placemark.subAdministrativeArea! + "\n"
			}
			if placemark.postalCode != nil {
				addressString = addressString + placemark.postalCode! + " "
			}
			if placemark.locality != nil {
				addressString = addressString + placemark.locality!
			}
			if placemark.thoroughfare != nil {
				addressString = addressString + placemark.thoroughfare!
			}
			if placemark.subThoroughfare != nil {
				addressString = addressString + placemark.subThoroughfare!
			}
		}
		else {
			if placemark.subThoroughfare != nil {
				addressString = placemark.subThoroughfare! + " "
			}
			if placemark.thoroughfare != nil {
				addressString = addressString + placemark.thoroughfare! + ", "
			}
			if placemark.locality != nil {
				addressString = addressString + placemark.locality! + " "
			}
			if placemark.administrativeArea != nil {
				addressString = addressString + placemark.administrativeArea! + " "
			}
//			if placemark.postalCode != nil {
//				addressString = addressString + placemark.postalCode! + " "
//			}
//			if placemark.country != nil {
//				addressString = addressString + placemark.country!
//			}
		}
		print (addressString)
		return addressString
	}
	
	
	
	/// **updateMissingAddresses**
	/// 		Check the address of all the stored locations and find missing addresses and attempt to geolocate them.
	/// - parameter locDictionary: Array of strings coming from trip engine representing a location
	/// - parameter isStart: starting or ending location
	/// - Oct 18, 2018 at 4:33:54 PM
	
	static func updateMissingAddresses() {
		
		PersistentContainerSingleton.shared.persistentContainer.performBackgroundTask( {_ in
			let taskContext = PersistentContainerSingleton.shared.persistentContainer.newBackgroundContext()
			taskContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
			taskContext.undoManager = nil // We don't need undo so set it to nil.

			let potentialLocations = Location.findMissingAddressLocations(inContext: taskContext)
			for loc in potentialLocations! {
				let userCoordinates = CLLocation(latitude: loc.latitude, longitude: loc.longitude)
				CLGeocoder().reverseGeocodeLocation(userCoordinates, completionHandler: {(placemarks, error)->Void in
					var addressString = ""
					if error == nil && (placemarks?.count)! > 0 {
						let placemark = placemarks![0] as CLPlacemark
						addressString = Location.getAddress(fromPlacemark: placemark)
						loc.address = addressString
						do {
							if (taskContext.hasChanges) {
								try taskContext.save()
								Location.removeDuplicateLocations()
							}
						}
						catch {
							print("!!!!!!!!!!!!!!Error received saving context during updateMissingAddresses errno = : \(error)")
						}
					}
				})
			}
		})
	}

	
	/// **removeDuplicateLocations**
	/// 		Go through all locations and get rid of duplicates.  Not depending on core data to have a tight relationship as we want
	///			 the trips to go away but not get rid of all the locations
	/// - parameter n/a:
	/// - Nov 3, 2018 at 2:45:25 PM
	/// - returns: n/a
	static func removeDuplicateLocations () {
		
		PersistentContainerSingleton.shared.persistentContainer.performBackgroundTask( {_ in
			let taskContext = PersistentContainerSingleton.shared.persistentContainer.newBackgroundContext()
			taskContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
			taskContext.undoManager = nil // We don't need undo so set it to nil.
			
			var locsToDelete:[Location] = []
			let locations = Location.allLocations(onContext:taskContext) as [Location]
			var innerLocations = Location.allLocations(onContext:taskContext) as [Location]
			var compareLoc:Location? = nil
			
			for outerLoc in locations {
				compareLoc = outerLoc
				let index = innerLocations.index(where: { $0 == outerLoc } )
				if (index != nil) {
					innerLocations.remove(at: index!)
				}
				for innerLoc in innerLocations {
					if (compareLoc!.equalAddress(rhs:innerLoc) && !locsToDelete.contains(innerLoc)) {
						locsToDelete.append(innerLoc)
						for case let segment as Segment in innerLoc.segments! {
							if (segment.startLocation?.equalAddress(rhs:innerLoc) ?? false) {
								segment.startLocation = compareLoc
								compareLoc?.addToSegments(segment)
								innerLoc.removeFromSegments(segment)
							}
							if (segment.stopLocation?.equalAddress(rhs:innerLoc) ?? false) {
								segment.stopLocation = compareLoc
								compareLoc?.addToSegments(segment)
								innerLoc.removeFromSegments(segment)
							}
						}
						for case let trip as Trip in innerLoc.trips! {
							if (trip.startLocation?.equalAddress(rhs:innerLoc) ?? false) {
								trip.startLocation = compareLoc
								compareLoc?.addToTrips(trip)
								innerLoc.removeFromTrips(trip)
							}
							if (trip.stopLocation?.equalAddress(rhs:innerLoc) ?? false) {
								trip.stopLocation = compareLoc
								compareLoc?.addToTrips(trip)
								innerLoc.removeFromTrips(trip)
							}
						}
					}
				}
			}
			
			for locToDelete in locsToDelete {
				assert(locToDelete.trips?.count == 0, "Deleting a location that still refers to trips")
				assert(locToDelete.segments?.count == 0, "Deleting a location that still refers to segments")
				taskContext.delete(locToDelete)
			}
			do {
				if (taskContext.hasChanges) {
					try taskContext.save()
				}
			}
			catch {
				print("!!!!!!!!!!!!!!Error received deleting duplicate locations errno = : \(error)")
			}
		})
	}

	

	//MARK:______________________________
	//MARK: OBJECT routines
	public override func awakeFromFetch() {
		super.awakeFromFetch()
	}

	func equalAddress(rhs: Location?) -> Bool {
		guard (rhs != nil) && (rhs?.address != nil) else {return false}
		print (self.address as Any)
		print (rhs?.address as Any)
		if (self.address == rhs?.address) {
			return true
		}
		else {
			return false
		}
	}
	
	
	//	A convenience method to update a location object with a dictionary.
	func update(with locationDictionary: [AnyHashable: Any], inContext context:NSManagedObjectContext) throws {
		
		/**
		Only update if all the relevant properties can be accessed.
		Use NSNumber for numeric values, then convert the result to the right type.
		*/
		guard let localIdentifier = locationDictionary["id"] as? String,
			
			// rest of location information
			let localName 		= locationDictionary["name"] as? String,
//			let localAddress 	= locationDictionary["address"] as? String, ----- coming thru null and then odd number from json process
			let localLatitude 	= (locationDictionary["lat"] as? NSNumber),
			let localLongitude = locationDictionary["lng"] as? NSNumber,
			let localAltitude 	= locationDictionary["alt"] as? NSNumber
			
			else {
				
				let description = NSLocalizedString("Could not find appropriate location information.", comment: "")
				throw NSError(domain: locationsErrorDomain, code: TripProviderErrorCode.wrongDataFormat.rawValue,
							  userInfo: [NSLocalizedDescriptionKey: description])
		}
		self.identifier = localIdentifier
		self.name		= localName
		self.latitude	= Double( truncating: localLatitude )
		self.longitude	= Double( truncating: localLongitude )
		// self.address	= Using internal CLGeocoder().reverseGeocodeLocation when location saved
		self.altitude	= Int32( truncating: localAltitude )
	}
}
