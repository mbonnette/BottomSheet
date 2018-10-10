//
//  Copyright © 2018 Simon Kågedal Reimer. All rights reserved.
//

import MapKit
import UIKit
import CoreData

class MapViewController: UIViewController, NSFetchedResultsControllerDelegate, CLLocationManagerDelegate, MKMapViewDelegate {

    private lazy var mapView = MKMapView(frame: view.bounds)
	private lazy var mapCenteredFirstTime = false
	private lazy var locationMgr = CLLocationManager()
	private lazy var currentAddress: String? = nil
	private lazy var curLocation:CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
	private lazy var tripProvider: TripProvider = {
		let provider = TripProvider()
		provider.fetchedResultsControllerDelegate = self
		return provider
	}()

	private let regionRadius: CLLocationDistance = 100000

	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.locationMgr.requestWhenInUseAuthorization()
		mapView.showsUserLocation = true

		view.addSubview(mapView)
		mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		mapView.delegate = self
		
//		let initialLocation = CLLocation(latitude: 42.377806, longitude: -71.111969)
//		centerMapOnLocation(location: initialLocation)
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		checkLocationAuthorizationStatus()
	}

	// MARK: - MKMapViewDelegate
	func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
		
		let lat = userLocation.coordinate.latitude.rounded(toPlaces: 6)
		let long = userLocation.coordinate.longitude.rounded(toPlaces: 6)

		if  (lat != 0.0) &&
			(long != 0.0) &&
			(lat != curLocation.latitude) &&
			(long != curLocation.longitude) {

			if (mapCenteredFirstTime == false) {
				self.mapCenteredFirstTime = true
				self.centerMapOnLocation(location: userLocation.location!)
			}

			// Lookup the information for the current location
			CLGeocoder().reverseGeocodeLocation(userLocation.location!, completionHandler: {(placemarks, error)->Void in
				if error == nil && (placemarks?.count)! > 0 {
					let placemark = placemarks![0] as CLPlacemark
					
					var addressString : String = ""
					if placemark.isoCountryCode == "TW" /*Address Format in Chinese*/ {
						if placemark.country != nil {
							addressString = placemark.country!
						}
						if placemark.subAdministrativeArea != nil {
							addressString = addressString + placemark.subAdministrativeArea! + "\n"
						}
						if placemark.postalCode != nil {
							addressString = addressString + placemark.postalCode! + " "
						}
						if placemark.locality != nil {
							addressString = addressString + placemark.locality!
						}
						if placemark.thoroughfare != nil {
							addressString = addressString + placemark.thoroughfare!
						}
						if placemark.subThoroughfare != nil {
							addressString = addressString + placemark.subThoroughfare!
						}
					} else {
						if placemark.subThoroughfare != nil {
							addressString = placemark.subThoroughfare! + " "
						}
						if placemark.thoroughfare != nil {
							addressString = addressString + placemark.thoroughfare! + "\n"
						}
						if placemark.postalCode != nil {
							addressString = addressString + placemark.postalCode! + " "
						}
						if placemark.locality != nil {
							addressString = addressString + placemark.locality! + "\n"
						}
						if placemark.administrativeArea != nil {
							addressString = addressString + placemark.administrativeArea! + " "
						}
						if placemark.country != nil {
							addressString = addressString + placemark.country!
						}
					}
					self.currentAddress = addressString
					print (lat, long)
					print (addressString)
					JourneySingleton.sharedInstance.startPoint = MKMapPoints(CLLocationCoordinate2D(latitude: lat, longitude: long))
				}
			})
		}
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


extension Double {
	/// Rounds the double to decimal places value
	func rounded(toPlaces places:Int) -> Double {
		let divisor = pow(10.0, Double(places))
		return (self * divisor).rounded() / divisor
	}
}
