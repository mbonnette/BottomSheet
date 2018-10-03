//
//  Copyright © 2018 Simon Kågedal Reimer. All rights reserved.
//

import MapKit
import UIKit
import CoreData

class MapViewController: UIViewController, NSFetchedResultsControllerDelegate {

    private lazy var mapView = MKMapView(frame: view.bounds)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(mapView)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

	private lazy var tripProvider: TripProvider = {
		
		let provider = TripProvider()
		provider.fetchedResultsControllerDelegate = self
		return provider
	}()
	
	
	

}


/**
NSFetchedResultsControllerDelegate, available since macOS 10.12+
*/
extension MapViewController {
	
	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		mapView.reloadInputViews()
	}

}
