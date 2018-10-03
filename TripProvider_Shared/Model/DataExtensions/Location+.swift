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

//MARK:______________________________
//MARK: CLASS routines


extension Location  {

	//MARK:______________________________
	//MARK: CLASS routines
	
	static func newLocation(inContext context:NSManagedObjectContext) -> Location {

		let location = NSEntityDescription.insertNewObject(forEntityName: "Location", into:context) as! Location

		location.locationType = locationTypes.temporary.rawValue
		return location
	}
	
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
			let localLongtitude = locationDictionary["lng"] as? NSNumber,
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
		self.longtitude	= Double( truncating: localLongtitude )
		self.altitude	= Int32( truncating: localAltitude )
	}
}
