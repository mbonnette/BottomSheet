//
//  Coordinate+.swift
//  Locations
//
//  Created by Michael Bonnette on 9/26/18.
//  Copyright © 2018 BlueMEDL, Inc. All rights reserved.
//

import Foundation
import CoreData

extension Coordinate  {
	
	//MARK:______________________________
	//MARK: CLASS routines
	
	static func newCoordinate(inContext context:NSManagedObjectContext) -> Coordinate {
		
		let coordinate = NSEntityDescription.insertNewObject(forEntityName: "Coordinate", into:context) as! Coordinate
		
		return coordinate
	}
	
	public override func awakeFromFetch() {
		super.awakeFromFetch()
	}
	
	//	A convenience method to update a location object with a lat/long.
	func update(_ lat:NSNumber, _ long:NSNumber)  {

		self.latitude = Double(truncating: lat)
		self.longitude = Double(truncating: long)
	}
}

