//
//  Copyright © 2018 Simon Kågedal Reimer. All rights reserved.
//

import MapKit
import UIKit
import CoreData

class MapViewController: UIViewController, NSFetchedResultsControllerDelegate, CLLocationManagerDelegate, MKMapViewDelegate {

    private lazy var mapView = MKMapView(frame: view.bounds)
	private lazy var locationMgr = CLLocationManager()
	private lazy var tripProvider: TripProvider = {
		let provider = TripProvider()
		provider.fetchedTripResultsControllerDelegate = self
		return provider
	}()
	private var displayedTrip:Trip? = nil
	private var displayedOverlay:MKOverlay? = nil
	private var mapCenteredFirstTime = false
	private var currentAddress: String? = nil
	private var curLocation:CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)

	private let regionRadius: CLLocationDistance = 100000

	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.locationMgr.requestWhenInUseAuthorization()
		mapView.showsUserLocation = true

		view.addSubview(mapView)
		mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		mapView.delegate = self
		
		// If not showing a trip on start, need to initiate fetch so will be listening
		print("Existing number of trips",tripProvider.fetchedTripsResultsController.fetchedObjects?.count as Any)

//		let initialLocation = CLLocation(latitude: 42.377806, longitude: -71.111969)
//		centerMapOnLocation(location: initialLocation)
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		checkLocationAuthorizationStatus()
	}

	
	// MARK: - MKMapViewDelegate
	func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
		
		let lat = userLocation.coordinate.latitude.rounded(toPlaces: 5)
		let long = userLocation.coordinate.longitude.rounded(toPlaces: 5)
//let lat = 42.775000  // Home
//let long = -71.616000
		let userCoordinates = CLLocation(latitude: lat,longitude: long)

		if  (lat != 0.0) &&
			(long != 0.0) &&
			(lat != curLocation.latitude) &&
			(long != curLocation.longitude) {

			print("Existing number of trips",tripProvider.fetchedTripsResultsController.fetchedObjects?.count as Any)

			if (mapCenteredFirstTime == false) {
				self.mapCenteredFirstTime = true
				self.centerMapOnLocation(location: userCoordinates)
			}

			// Lookup the information for the current location
			CLGeocoder().reverseGeocodeLocation(userCoordinates, completionHandler: {(placemarks, error)->Void in
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
					JourneySingleton.sharedInstance.startPoint = MKMapPoint(CLLocationCoordinate2D(latitude: lat, longitude: long))
//DEBUG SO DON't HIT SERVER
//JourneySingleton.sharedInstance.endPoint = MKMapPoint(CLLocationCoordinate2D(latitude: lat, longitude: long))
//self.showNewTrip(JourneySingleton.sharedInstance.getTrip(byType: .driving))
					// TODO end point would get set on search process.  Harvard set as default for now
				}
			})
		}
	}

	func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {

		if overlay is MKPolyline
		{
			let route: MKPolyline = overlay as! MKPolyline
			let routeRenderer = MKPolylineRenderer(polyline:route)
			routeRenderer.lineWidth = 3.0
			if overlay.title == "one"
			{
				routeRenderer.strokeColor = UIColor(red: 240.0/255.0, green: 68.0/255.0, blue: 0.0/255.0, alpha: 1);
			}
			else
			{
				routeRenderer.strokeColor = UIColor(red: 45.0/255.0, green: 200.0/255.0, blue: 0.0/255.0, alpha: 1);
			}
			displayedOverlay = overlay
			return routeRenderer
		}
		return MKPolylineRenderer()
	}
	
	// MARK: - Internal Route UI
	func showNewTrip(_ trip:Trip?) {
		guard (trip == nil ) else {
			if (displayedTrip != nil) {
				hideLastTrip()
			}
			displayedTrip = trip
			print(displayedTrip as Any)

			// 1.
			let sourcePlacemark = MKPlacemark(coordinate: (JourneySingleton.sharedInstance.startPoint?.coordinate)!, addressDictionary: nil)
			let destinationPlacemark = MKPlacemark(coordinate: (JourneySingleton.sharedInstance.stopPoint?.coordinate)!, addressDictionary: nil)
			
			// 2.
			let sourceAnnotation = MKPointAnnotation()
			sourceAnnotation.title = "Current Location"
			sourceAnnotation.coordinate = (sourcePlacemark.location?.coordinate)!
			let destinationAnnotation = MKPointAnnotation()
			destinationAnnotation.title = "Destination"
			destinationAnnotation.coordinate = (destinationPlacemark.location?.coordinate)!
			
			// 3.
			self.mapView.showAnnotations([sourceAnnotation,destinationAnnotation], animated: true )

			// Pull the polyline from the trip and have it lazily build the polyline I'm expecting
			let segs:NSOrderedSet = (trip?.segments!)!
			var polyline:MKPolyline? = nil
			for segment in segs.array as! [Segment] {
				polyline = createPolyline(segment)
				self.mapView.addOverlay(polyline!)
			}
			
			let rect:MKMapRect = (polyline?.boundingMapRect)!
			self.mapView.setRegion(MKCoordinateRegion(rect), animated: true)
			self.mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top:10.0,left:60.0,bottom:10.0,right:60.0), animated:true)
			return
		}
	}

	func hideLastTrip() {
		guard (displayedTrip == nil) else {
			
			self.mapView.removeOverlay(displayedOverlay!)
			displayedTrip = nil
			displayedOverlay = nil
			return
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
	

	func createPolyline(_ seg:Segment) -> MKPolyline {

		let polyArray = Array(seg.path!.polyline!)
		var coordinateArray:[CLLocationCoordinate2D] = []
		
		for coord in polyArray as! [Coordinate]  {
			let newCoordinate = CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)
			coordinateArray.append(newCoordinate)
		}
		let polyLine = MKPolyline(coordinates:coordinateArray, count:coordinateArray.count)
		print(polyLine as Any)
		return polyLine
	}

}


// MARK: - NSFetchedResultsControllerDelegate
/**
NSFetchedResultsControllerDelegate, available since macOS 10.12+
*/
extension MapViewController {
	
	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		mapView.reloadInputViews()
		showNewTrip(JourneySingleton.sharedInstance.getTrip(byType: .driving))
	}

}

