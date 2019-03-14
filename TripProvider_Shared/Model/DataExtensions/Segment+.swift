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
		return segment
	}
	
	public override func awakeFromFetch() {
		super.awakeFromFetch()
	}

	static func transportTypeEnum(_ transportTypeStr:String) -> Int32 {
		switch transportTypeStr {
		case "DRIVE","drive","Drive","driving","DUMMY":			// saw dummy as drive buffer with no path data?
			return TransportTypes.driving.rawValue
		case "WALK","walk","Walk","walking":
			return TransportTypes.walking.rawValue
		case "BIKING","bicycling","Bicycling":
			return TransportTypes.bicycling.rawValue
		case "TRANSIT","transit","Transit":
			return TransportTypes.transit.rawValue
		case "PARKANDWALK","parkandwalk","Parkandwalk":
			return TransportTypes.parkandwalk.rawValue
		default:
			print("---- INSIDE transportTypeEnum No value for ---",transportTypeStr)
			return TransportTypes.driving.rawValue
		}
	}
	
	static func transportTypeString(_ transportType:TransportTypes) -> String {
		switch transportType {
		case .driving:
			return "driving"
		case .bicycling:
			return "bicycling"
		case .walking:
			return "walking"
		case .transit:
			return "transit"
		case .carshare:
			return "carshare"
		case .bikeshare:
			return "bikeshare"
		case .rideshare:
			return "rideshare"
		case .parkandwalk:
			return "parkandwalk"
		case .parkandride:
			return "parkandride"
		case .parkandbikeshare:
			return "parkandbikeshare"
		case .parkandrideshare:
			return "parkandrideshare"
		case .transitandbikeshare:
			return "transitandbikeshare"
		case .transitandrideshare:
			return "transitandrideshare"
		case .transitandcarshare:
			return "transitandcarshare"
		case .bikeshareandcarshare:
			return "bikeshareandcarshare"
		case .park:
			return "park"
		case .unknown:
			return "unknown"
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

		// Identifier is string based by sometimes comes in as number inside json parsing...probably better way of doing check
		//	so it doesn't get this far
		var localIdentifier:String = ""
		let numberBased = segmentDictionary["id"] as? NSNumber
		if (numberBased != nil) {
			localIdentifier = (numberBased?.stringValue)!
		}
		else {
			localIdentifier 	= segmentDictionary["id"] as! String
		}

		guard let fromDictionary = segmentDictionary["from_location"] as? [String: AnyObject],

			let toDictionary 		= segmentDictionary["to_location"] as? [String: AnyObject],
			let localDescription 	= segmentDictionary["description"] as? String,
			let localType 			= segmentDictionary["type"] as? String,
			let localCost 			= segmentDictionary["cost"] as? NSNumber,
			let localDistance 		= segmentDictionary["distance"] as? NSNumber,
			let localCalories 		= segmentDictionary["calories"] as? NSNumber,
			let localCo2 			= segmentDictionary["co2"] as? NSNumber,
			let localWeight 		= segmentDictionary["lb"] as? NSNumber,
			let localStartTime 		= segmentDictionary["start_time"] as? NSNumber,
			let localEndTime 		= segmentDictionary["end_time"] as? NSNumber

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
		self.identifier		= localIdentifier
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

			self.startLocation?.addToSegments(self)
			self.stopLocation?.addToSegments(self)
			
			let pathDictionary 	= segmentDictionary["path"] as? [String: AnyObject]
			if (pathDictionary != nil) {
				let segmentPath = Path.newPath(inContext:context)
				try segmentPath.update(with:pathDictionary!, inContext:context)
				self.path = segmentPath
			}
			
		} catch {
			let nserror = error as NSError
			fatalError("NO Polyline found \(nserror), \(nserror.userInfo)")
		}
	}

	//MARK:______________________________
	//MARK: PRIVATE routines
	
	private func segmentTypeEnum(_ segmentTypeStr:String) -> Int32 {
		switch segmentTypeStr {
		case "DRIVE","drive","Drive":
			return TransportTypes.driving.rawValue
		case "BIKE","bike","Bicycling","Biking","biking":
			return TransportTypes.bicycling.rawValue
		case "WALK","walk","Walk":
			return TransportTypes.walking.rawValue
		case "PARK":
			return TransportTypes.park.rawValue
		default:
			return TransportTypes.driving.rawValue
		}
	}
	
	private func segmentTypeString(_ segmentType:TransportTypes) -> String {
		switch segmentType {
		case .driving:
			return "driving"
		case .bicycling:
			return "bicycling"
		case .walking:
			return "walking"
		default:
			return "driving"
		}
	}
	

}
