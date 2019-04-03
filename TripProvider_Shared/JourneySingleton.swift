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
	//MARK: Variables
	
	var tripProvider = TripProvider()
	var curSelectedTransportType:TransportTypes = TransportTypes.driving


	//--- endPoints and listeners
	private var curEndPointListeners:[(()->())?] = []
	var startPoint:MKMapPoint? = nil {
		didSet {
			//current location is constantly changing right now so don't do source
//			for listener in curEndPointListeners {
//				listener?()
//			}
		}
	}
	var stopPoint:MKMapPoint? = MKMapPoint(CLLocationCoordinate2D(latitude: 42.481285, longitude: -71.214729)) {
		didSet {
			for listener in curEndPointListeners {
				listener?()
			}
		}
	}
	func notifyOnEndPointChanges(with closure: (()->())? ) {
		curEndPointListeners.append(closure)
	}

	
	//---- curTrip and listeners
	private var curTripListeners:[(()->())?] = []
	var curTripDisplayed:Trip? {
		didSet {
			for listener in curTripListeners {
				listener?()
			}
			Location.removeDuplicateLocations()
		}
	}
	func notifyOnTripChange(with closure: (()->())? ) {
		curTripListeners.append(closure)
	}

	
	// MARK:- Object Routines
	
	func retrieve(journeyType:TransportTypes, completionHandler: @escaping (Error?) -> Void) {
		if (stopPoint == nil) {
			stopPoint = MKMapPoint(CLLocationCoordinate2D(latitude: 42.481285, longitude: -71.214729))
		}
		tripProvider.fetchTrip(start: startPoint!, stop: stopPoint!, journeyType, completionHandler: completionHandler)
	}

	func retrieveDrivingJourney(completionHandler: @escaping (Error?) -> Void) {
		retrieve(journeyType: TransportTypes.driving, completionHandler: completionHandler)
	}
	
	func retrieveWalkingJourney(completionHandler: @escaping (Error?) -> Void) {
		retrieve(journeyType: TransportTypes.walking, completionHandler: completionHandler)
	}
	
	func retrieveBikingJourney(completionHandler: @escaping (Error?) -> Void) {
		retrieve(journeyType: TransportTypes.bicycling, completionHandler: completionHandler)
	}

	func getTrip(byType type:TransportTypes) -> Trip? {
		let matchingTrips = Trip.findTrips(from: (startPoint?.coordinate)!, to: (stopPoint?.coordinate)!)
		return matchingTrips?.filter{ $0.tripType == type.rawValue }.first ?? nil
	}
}
