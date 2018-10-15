//
//  Location+.swift
//
//
//  Created by Michael Bonnette on 9/23/18.
//

import Foundation
import CoreData


public enum locationTypes: Int32 {
	case temporary = 0
	case userSearched = 1
	case userPinned = 2
}


extension Location  {

	//MARK:______________________________
	//MARK: CLASS routines
	
	static func newLocation(inContext context:NSManagedObjectContext) -> Location {
		let location = NSEntityDescription.insertNewObject(forEntityName: "Location", into:context) as! Location
		location.locationType = locationTypes.temporary.rawValue
		return location
	}
	
	static func newLocation() -> Location {
		let location = NSEntityDescription.insertNewObject(forEntityName: "Location", into:PersistentContainerSingleton.shared.persistentContainer.viewContext) as! Location
		location.locationType = locationTypes.temporary.rawValue
		return location
	}
	
	static func newLocation(named name:String?, withAddress address:String?) -> Location {
		let location = Location.newLocation()
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
	
	
	static var allLocations: [Location]? {
		var locations:[Location]? = nil
		do {
			locations = try PersistentContainerSingleton.shared.persistentContainer.viewContext.fetch(Location.sortedFetchRequest)
		}
		catch {
			print("!!!!!!!!!!!!!!No locations received and a throw was hit: \(error)")
		}
		return locations
	}
	
	static func findLocation(named name:String?) -> Location? {
		guard (name == nil) else {
			var locations:[Location]? = nil
			let request = Location.sortedFetchRequest
			request.predicate = NSPredicate(format: "name = %@", name!)
			do {
				locations = try PersistentContainerSingleton.shared.persistentContainer.viewContext.fetch(request)
			}
			catch {
				print("!!!!!!!!!!!!!!No location received and a throw was hit: \(error)")
			}
			assert(locations!.count <= 1)
			if (locations!.count == 1) {
				return locations![0]
			}
			else {
				return nil
			}
		}
		return nil
	}
	static func findLocation(atAddress address:String?) -> Location? {
		guard (address == nil) else {
			var locations:[Location]? = nil
			let request = Location.sortedFetchRequest
			request.predicate = NSPredicate(format: "address = %@", address!)
			do {
				locations = try PersistentContainerSingleton.shared.persistentContainer.viewContext.fetch(request)
			}
			catch {
				print("!!!!!!!!!!!!!!No location received and a throw was hit: \(error)")
			}
			assert(locations!.count <= 1)
			if (locations!.count == 1) {
				return locations![0]
			}
			else {
				return nil
			}
		}
		return nil
	}
	
	
	static func getOrCreateLocation(named name:String? = nil, withAddress address:String?) -> Location {
		var location = Location.findLocation(named: name)
		if ( location == nil ) {
			location = Location.findLocation(atAddress: address)
			if (location == nil) {
				location = newLocation(named: name, withAddress:address)
			}
		}
		return location!
	}


	//MARK:______________________________
	//MARK: OBJECT routines
	public override func awakeFromFetch() {
		super.awakeFromFetch()
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
//		self.address	= localAddress
		self.latitude	= Double( truncating: localLatitude )
		self.longitude	= Double( truncating: localLongitude )
		self.altitude	= Int32( truncating: localAltitude )
	}
}
