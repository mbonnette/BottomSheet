//
//  Segment+.swift
//
//
//  Created by Michael Bonnette on 9/23/18.
//

import Foundation
import CoreData


public enum segmentTypes: Int32 {
	case driving = 0
	case walking = 1
	case something = 2
}

//MARK:______________________________
//MARK: CLASS routines


extension Segment  {

	//MARK:______________________________
	//MARK: CLASS routines
	
	static func newSegment(inContext context:NSManagedObjectContext) -> Segment {

		let segment = NSEntityDescription.insertNewObject(forEntityName: "Segment", into:context) as! Segment

		segment.segmentType = segmentTypes.driving.rawValue
		return segment
	}
	
	public override func awakeFromFetch() {
		super.awakeFromFetch()
	}

	
	/**
	A convenience method to update a segment object with a dictionary.
	*/
	func update(with segmentDictionary: [AnyHashable: Any], inContext context:NSManagedObjectContext) throws {
		
		/**
		Only update if all the relevant properties can be accessed.
		Use NSNumber for numeric values, then convert the result to the right type.
		
		Do both the from/to locations
		*/

		guard let fromDictionary = segmentDictionary["from_location"] as? [String: AnyObject],

			let toDictionary 		= segmentDictionary["to_location"] as? [String: AnyObject],
			let localDescription 	= segmentDictionary["description"] as? String,
			let localType 			= segmentDictionary["type"] as? String,
			let localCost 			= segmentDictionary["cost"] as? NSNumber,
			let localDistance 		= segmentDictionary["distance"] as? NSNumber,
			let localCalories 		= segmentDictionary["calories"] as? NSNumber,
			let localCo2 			= segmentDictionary["co2"] as? NSNumber,
			let localWeight 		= segmentDictionary["lb"] as? NSNumber,
			let localIdentifier 	= segmentDictionary["id"] as? NSNumber,
			let localStartTime 		= segmentDictionary["start_time"] as? NSNumber,
			let localEndTime 		= segmentDictionary["end_time"] as? NSNumber,
			let pathDictionary 		= segmentDictionary["path"] as? [String: AnyObject]

		else {
			let description = NSLocalizedString("Could not interpret data from the direction server.", comment: "")
			throw NSError(domain: locationsErrorDomain, code: TripProviderErrorCode.wrongDataFormat.rawValue,
						  userInfo: [NSLocalizedDescriptionKey: description])
		}
		self.desc			= localDescription
		self.segmentType	= segmentTypeEnum(localType)
		self.cost			= Float(truncating: localCost)
		self.distance		= Int64(truncating: localDistance)
		self.calories		= Int64(truncating: localCalories)
		self.co2			= Int64(truncating: localCo2)
		self.weight			= Int64(truncating: localWeight)
		self.identifier		= Int64(truncating: localIdentifier)
		self.startTime		= Int64(truncating: localStartTime)
		self.endTime		= Int64(truncating: localEndTime)
		// not saved
		//	"parking": null,
		//	"transit": null,
		//	"carshare": null,
		//	"bikeshare": null,
		//	"rideshare": null,
		//	"controllable": true,

		do {
			let fromLocation = Location.newLocation(inContext:context)
			try fromLocation.update(with:fromDictionary, inContext:context)
			self.startLocation = fromLocation

			let toLocation = Location.newLocation(inContext:context)
			try toLocation.update(with:toDictionary, inContext:context)
			self.endLocation = toLocation
			
			let segmentPath = Path.newPath(inContext:context)
			try segmentPath.update(with:pathDictionary, inContext:context)
			self.path = segmentPath
			
		} catch {
			let nserror = error as NSError
			fatalError("NO Polyline found \(nserror), \(nserror.userInfo)")
		}
	}

	//MARK:______________________________
	//MARK: PRIVATE routines
	
	private func segmentTypeEnum(_ segmentTypeStr:String) -> Int32 {

		switch segmentTypeStr {
				case "Driving":
					return segmentTypes.driving.rawValue
				case "Walking":
					return segmentTypes.walking.rawValue
				default:
					return 	segmentTypes.driving.rawValue
			}
	}
}
