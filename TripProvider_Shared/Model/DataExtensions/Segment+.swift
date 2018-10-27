//
//  Segment+.swift
//
//
//  Created by Michael Bonnette on 9/23/18.
//

import Foundation
import CoreData
import MapKit

//MARK:______________________________
//MARK: CLASS routines


extension Segment  {

	//MARK:______________________________
	//MARK: CLASS routines
	
	static func newSegment(inContext context:NSManagedObjectContext) -> Segment {

		let segment = NSEntityDescription.insertNewObject(forEntityName: "Segment", into:context) as! Segment

		segment.segmentType = TransportTypes.driving.rawValue
		return segment
	}
	
	public override func awakeFromFetch() {
		super.awakeFromFetch()
	}

	static func transportTypeEnum(_ transportTypeStr:String) -> Int32 {
		switch transportTypeStr {
		case "DRIVE","drive","Drive","driving":
			return TransportTypes.driving.rawValue
		case "WALK","walk","Walk","walking":
			return TransportTypes.walking.rawValue
		case "TRANSIT","transit","Transit":
			return TransportTypes.walking.rawValue
		default:
			return TransportTypes.driving.rawValue
		}
	}
	
	static func transportTypeString(_ transportType:TransportTypes) -> String {
		switch transportType {
		case .driving:
			return "driving"
		case .walking:
			return "walking"
		case .transit:
			return "transit"
		default:
			return "driving"
		}
	}
	
	
	
	//MARK:______________________________
	//MARK: OBJECT routines
	

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
			self.startLocation = Location.newLocation(inContext:context)
			try self.startLocation?.update(with:fromDictionary, inContext:context)
			self.stopLocation = Location.newLocation(inContext:context)
			try self.stopLocation?.update(with:toDictionary, inContext:context)

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
	
	func segmentTypeEnum(_ segmentTypeStr:String) -> Int32 {
		switch segmentTypeStr {
		case "DRIVE","drive","Drive":
			return TransportTypes.driving.rawValue
		case "WALK","walk","Walk":
			return TransportTypes.walking.rawValue
		default:
			return TransportTypes.driving.rawValue
		}
	}
	
	func segmentTypeString(_ segmentType:TransportTypes) -> String {
		switch segmentType {
		case .driving:
			return "driving"
		case .walking:
			return "walking"
		default:
			return "driving"
		}
	}
	

}
