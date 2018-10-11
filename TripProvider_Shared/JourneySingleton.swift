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
	var endPoint:MKMapPoint? = nil
	var tripProvider = TripProvider()
	
	
	func retrieveDrivingJourney(completionHandler: @escaping (Error?) -> Void) {
		if (endPoint == nil) {
			endPoint = MKMapPoint(CLLocationCoordinate2D(latitude: 42.481285, longitude: -71.214729))
		}
		tripProvider.fetchTrip(start: startPoint!, stop: endPoint!, segmentTypes.driving, completionHandler: completionHandler)
	}
	

	func retrieveDrivingJourney(start:MKMapPoint, stop:MKMapPoint, completionHandler: @escaping (Error?) -> Void) {
		tripProvider.fetchTrip(start: start, stop: stop, segmentTypes.driving, completionHandler: completionHandler)
	}
	
	func retrieveWalkingJourney(start:MKMapPoint, stop:MKMapPoint, completionHandler: @escaping (Error?) -> Void) {
		tripProvider.fetchTrip(start: start, stop: stop, segmentTypes.walking, completionHandler: completionHandler)
	}

}
