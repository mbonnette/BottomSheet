//
//  Path+.swift
//
//
//  Created by Michael Bonnette on 9/23/18.
//

import Foundation
import CoreData


public enum pathTypes: Int32 {
	case driving = 0
	case walking = 1
	case something = 2
}

//MARK:______________________________
//MARK: CLASS routines


extension Path  {

	//MARK:______________________________
	//MARK: CLASS routines
	
	static func newPath(inContext context:NSManagedObjectContext) -> Path {

		let path = NSEntityDescription.insertNewObject(forEntityName: "Path", into:context) as! Path

		path.type = pathTypes.something.rawValue
		return path
	}
	
	public override func awakeFromFetch() {
		super.awakeFromFetch()
	}

	//	A convenience method to update a location object with a dictionary.
	func update(with pathDictionary: [AnyHashable: Any], inContext context:NSManagedObjectContext) throws {
		
		/**
		Only update if all the relevant properties can be accessed.
		Use NSNumber for numeric values, then convert the result to the right type.
		*/
		
		guard let localDistance = pathDictionary["distance"] as? NSNumber,
			
			// rest of location information
			let localMeanTime 			= pathDictionary["meanTime"] as? NSNumber,
			let localTime 				= pathDictionary["time"] as? NSNumber,
			let localUncongestedTime 	= pathDictionary["uncongestedTime"] as? NSNumber,
			let polylineArray	 		= pathDictionary["polyline"] as? [NSArray]

		else {
				let description = NSLocalizedString("Could not find appropriate Path information.", comment: "")
				throw NSError(domain: locationsErrorDomain, code: TripProviderErrorCode.wrongDataFormat.rawValue,
							  userInfo: [NSLocalizedDescriptionKey: description])
		}
		self.distance 			= Int64(truncating: localDistance)
		self.time 				= Int64(truncating: localTime)
		self.meanTime 			= Int64(truncating: localMeanTime)
		self.uncongestedTime 	= Int64(truncating: localUncongestedTime)

		//	SAVE POLYLINE
		for coordinateStructure in polylineArray {
			let coordinate = Coordinate.newCoordinate(inContext: context)
			coordinate.update(coordinateStructure[0] as! NSNumber, coordinateStructure[1] as! NSNumber)
			self.addToPolyline(coordinate)
		}
	}
}
