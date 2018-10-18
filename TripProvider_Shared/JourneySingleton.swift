//
//  JourneySingleton.swift
//  TripProvider
//
//  Created by Michael Bonnette on 10/3/18.
//  Copyright © 2018 Apple, Inc. All rights reserved.
//

import Foundation
import MapKit


class JourneySingleton {
	static let sharedInstance: JourneySingleton = {
		let instance = JourneySingleton()

		// setup code

		
		
		return instance
	}()


	//MARK:______________________________
	//MARK: CLASS routines
	

	
	
	//MARK:______________________________
	//MARK: OBJECT routines
	
	var startPoint:MKMapPoint? = nil
	var stopPoint:MKMapPoint? = nil
	var tripProvider = TripProvider()
	
	
	func retrieveDrivingJourney(completionHandler: @escaping (Error?) -> Void) {
		if (stopPoint == nil) {
			stopPoint = MKMapPoint(CLLocationCoordinate2D(latitude: 42.481285, longitude: -71.214729))	// Harvard
		}
		tripProvider.fetchTrip(start: startPoint!, stop: stopPoint!, segmentTypes.driving, completionHandler: completionHandler)
	}
	
	func retrieveDrivingJourney(start:MKMapPoint? = nil, stop:MKMapPoint? = nil, completionHandler: @escaping (Error?) -> Void) {
		startPoint = start ?? startPoint
		stopPoint = stop ?? stopPoint
		tripProvider.fetchTrip(start: startPoint!, stop: stopPoint!, segmentTypes.driving, completionHandler: completionHandler)
	}
	
	func retrieveWalkingJourney(start:MKMapPoint? = nil, stop:MKMapPoint? = nil, completionHandler: @escaping (Error?) -> Void) {
		startPoint = start ?? startPoint
		stopPoint = stop ?? stopPoint
		tripProvider.fetchTrip(start: startPoint!, stop: stopPoint!, segmentTypes.walking, completionHandler: completionHandler)
	}

	func getTrip(byType type:segmentTypes) -> Trip? {
		let matchingTrips = Trip.findTrips(from: (startPoint?.coordinate)!, to: (stopPoint?.coordinate)!)
		return matchingTrips?.filter{ $0.tripType == type.rawValue }.first ?? nil
	}
}
