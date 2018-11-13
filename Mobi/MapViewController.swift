//
//  Copyright © 2018 Simon Kågedal Reimer. All rights reserved.
//

import MapKit
import UIKit
import CoreData

class MapViewController: UIViewController, NSFetchedResultsControllerDelegate, CLLocationManagerDelegate, MKMapViewDelegate {

    private lazy var mapView = MKMapView(frame: view.bounds)
	private lazy var locationMgr = CLLocationManager()
	private var displayedTrip:Trip? = nil
	private var displayedOverlay:MKOverlay? = nil
	private var originAnnotation:MKPointAnnotation? = nil
	private var destinationAnnotation:MKPointAnnotation? = nil
	private var mapCenteredFirstTime = false
	private var curLocation:CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
	private let regionRadius: CLLocationDistance = 100000

	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.locationMgr.requestWhenInUseAuthorization()
		mapView.showsUserLocation = true

		view.addSubview(mapView)
		mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		mapView.delegate = self

		JourneySingleton.sharedInstance.notifyOnTripChange(with: {
			self.showNewTrip(JourneySingleton.sharedInstance.curTripDisplayed)
		})
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

		if 	(lat != curLocation.latitude) &&
			(long != curLocation.longitude) {

			if (mapCenteredFirstTime == false) {
				self.mapCenteredFirstTime = true
				self.centerMapOnLocation(location: userCoordinates)
			}

			// Keep this point in the journey to grab directions
			JourneySingleton.sharedInstance.startPoint = MKMapPoint(CLLocationCoordinate2D(latitude: lat, longitude: long))

			//DEBUG SO DON't HIT SERVER
			//JourneySingleton.sharedInstance.endPoint = MKMapPoint(CLLocationCoordinate2D(latitude: lat, longitude: long))
			//self.showNewTrip(JourneySingleton.sharedInstance.getTrip(byType: .driving))
			// TODO end point would get set on search process.  Harvard set as default for now

		}
	}

	func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {

		if overlay is MKPolyline
		{
			let route: MKPolyline = overlay as! MKPolyline
			let routeRenderer = MKPolylineRenderer(polyline:route)
			routeRenderer.lineWidth = 3.0
			switch overlay.title {
			case String(TransportTypes.driving.rawValue):
				routeRenderer.strokeColor = UIColor(red: 80.0/255.0, green: 200.0/255.0, blue: 0.0/255.0, alpha: 1);
			case String(TransportTypes.bicycling.rawValue):
				routeRenderer.strokeColor = UIColor(red: 0.0/255.0, green: 80.0/255.0, blue: 200.0/255.0, alpha: 1);
			case String(TransportTypes.walking.rawValue):
				routeRenderer.strokeColor = UIColor(red: 200.0/255.0, green: 80.0/255.0, blue: 0.0/255.0, alpha: 1);
			default:
				routeRenderer.strokeColor = UIColor(red: 50.0/255.0, green: 200.0/255.0, blue: 200.0/255.0, alpha: 1);
			}
			displayedOverlay = overlay
			return routeRenderer
		}
		return MKPolylineRenderer()
	}
	
	func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

		if annotation is MKPointAnnotation {
			let pinAnnotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "myPin")
			pinAnnotationView.isDraggable = true
			pinAnnotationView.canShowCallout = true
			
//			if (annotation.title == displayedTrip?.stopLocation?.name) {
//				pinAnnotationView.setSelected(true, animated: false)
//			}
			return pinAnnotationView
		}
		return nil
	}
	
	func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationView.DragState, fromOldState oldState: MKAnnotationView.DragState) {
		switch newState {
		case .starting:
			view.dragState = .dragging
			if (view.annotation?.title == originAnnotation?.title) {
				if (view.annotation?.coordinate.latitude == originAnnotation?.coordinate.latitude) && (view.annotation?.coordinate.longitude == originAnnotation?.coordinate.longitude) {
					hideLastTrip(keepOriginAnnotation: true, keepDestinationAnnotation: true)
				}
			}
			if (view.annotation?.title == destinationAnnotation?.title) {
				if (view.annotation?.coordinate.latitude == destinationAnnotation?.coordinate.latitude) && (view.annotation?.coordinate.longitude == destinationAnnotation?.coordinate.longitude) {
					hideLastTrip(keepOriginAnnotation: true, keepDestinationAnnotation: true)
				}
			}
		case .ending, .canceling:
			//New cordinates
			print(view.annotation?.coordinate as Any)
			if (view.annotation?.title == originAnnotation?.title) {
				JourneySingleton.sharedInstance.startPoint = MKMapPoint(CLLocationCoordinate2D(latitude: (view.annotation?.coordinate.latitude)!, longitude: (view.annotation?.coordinate.longitude)!))
			}
			if (view.annotation?.title == destinationAnnotation?.title) {
				JourneySingleton.sharedInstance.stopPoint = MKMapPoint(CLLocationCoordinate2D(latitude: (view.annotation?.coordinate.latitude)!, longitude: (view.annotation?.coordinate.longitude)!))
			}
			view.dragState = .none
		default: break
		}
	}
	
	// MARK: - Internal Route UI
	
	private func showTripEndpoints(_ trip:Trip?) {
		// 1.
		if (originAnnotation == nil) {
			originAnnotation = MKPointAnnotation()
			originAnnotation?.title = trip?.startLocation?.displayString()
			originAnnotation?.coordinate = (JourneySingleton.sharedInstance.startPoint?.coordinate)!
		}
		
		if (destinationAnnotation == nil) {
			destinationAnnotation = MKPointAnnotation()
			destinationAnnotation?.title = trip?.stopLocation?.name
			destinationAnnotation?.subtitle = trip?.stopLocation?.address
			destinationAnnotation?.coordinate = (JourneySingleton.sharedInstance.stopPoint?.coordinate)!
		}
	}
	
	
	private func showNewTrip(_ trip:Trip?) {
		hideLastTrip(keepOriginAnnotation: true, keepDestinationAnnotation: true)
		showTripEndpoints(trip)
		
		guard (trip != nil) else {return}
		displayedTrip = trip

		// 2.
		self.mapView.showAnnotations([originAnnotation!,destinationAnnotation!], animated: true )
		
		// Pull the polyline from the trip and have it lazily build the polyline I'm expecting
		let segs:NSOrderedSet = trip?.segments ?? []
		var polyline:MKPolyline? = nil
		var locRect:MKMapRect? = nil
		for segment in segs.array as! [Segment] {
			if (segment.path == nil) {
				print("Some kind of parking location without a path")
			}
			else {
				polyline = createPolyline(using:segment)
				self.mapView.addOverlay((polyline ?? nil)!)
				if (locRect == nil) {
					locRect = polyline?.boundingMapRect
				}
				else {
					locRect = locRect!.union(polyline?.boundingMapRect ?? locRect!)
				}
			}
		}
		if (locRect?.isEmpty ?? false) {
			self.mapView.setRegion(MKCoordinateRegion(locRect!), animated: true)
			self.mapView.setVisibleMapRect(locRect!, edgePadding: UIEdgeInsets(top:10.0,left:60.0,bottom:10.0,right:60.0), animated:true)
		}
	}

	func hideLastTrip(keepOriginAnnotation:Bool = true, keepDestinationAnnotation:Bool = true) {
		guard (originAnnotation != nil) && (destinationAnnotation != nil) else {return}
		if (!keepOriginAnnotation) {
			self.mapView.removeAnnotation(originAnnotation!)
			originAnnotation = nil
		}
		if (!keepDestinationAnnotation) {
			self.mapView.removeAnnotation(destinationAnnotation!)
			destinationAnnotation = nil
		}

		guard (displayedTrip != nil) && (displayedOverlay != nil) else {return}
		self.mapView.removeOverlay(displayedOverlay!)
		displayedTrip = nil
		displayedOverlay = nil
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
	

	// MARK: - Private
	
	private func createPolyline(using seg:Segment) -> MKPolyline {

		let polyArray = Array(seg.path!.polyline!)
		var coordinateArray:[CLLocationCoordinate2D] = []
		
		for coord in polyArray as! [Coordinate]  {
			let newCoordinate = CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)
			coordinateArray.append(newCoordinate)
		}
		let polyline = MKPolyline(coordinates:coordinateArray, count:coordinateArray.count)
		polyline.title = String(seg.segmentType)
		return polyline
	}

}
