//
//  Copyright © 2018 Simon Kågedal Reimer. All rights reserved.
//

import MapKit
import UIKit
import CoreData

class MapViewController: UIViewController, NSFetchedResultsControllerDelegate, CLLocationManagerDelegate {

    private lazy var mapView = MKMapView(frame: view.bounds)
	private lazy var locationMgr = CLLocationManager()
	private lazy var geoCoder = CLGeocoder()
	private lazy var tripProvider: TripProvider = {
		let provider = TripProvider()
		provider.fetchedResultsControllerDelegate = self
		return provider
	}()
	let regionRadius: CLLocationDistance = 100000

	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.locationMgr.requestWhenInUseAuthorization()
		mapView.showsUserLocation = true

		view.addSubview(mapView)
		mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

		let initialLocation = CLLocation(latitude: 42.377806, longitude: -71.111969)
		centerMapOnLocation(location: initialLocation)
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		checkLocationAuthorizationStatus()
	}


	// MARK: - CLLocationManager
	
	func checkLocationAuthorizationStatus() {
		if CLLocationManager.authorizationStatus() == .authorizedAlways {
			mapView.showsUserLocation = true
		} else {
			locationMgr.requestAlwaysAuthorization()
		}
		//    if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
		//      mapView.showsUserLocation = true
		//    } else {
		//      locationMgr.requestWhenInUseAuthorization()
		//    }
	}


	// MARK: - Helper methods
	
	func centerMapOnLocation(location: CLLocation) {
		let coordinateRegion = MKCoordinateRegion(center: location.coordinate,
												  latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
		mapView.setRegion(coordinateRegion, animated: true)
	}
	

}


/**
NSFetchedResultsControllerDelegate, available since macOS 10.12+
*/
extension MapViewController {
	
	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		mapView.reloadInputViews()
	}

}
