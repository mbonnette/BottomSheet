//
//  Copyright © 2018 Simon Kågedal Reimer. All rights reserved.
//

import UIKit
import CoreData
import MapKit


class LocationsTableViewController: UITableViewController, NSFetchedResultsControllerDelegate, ScrollingCommandDelegate, BottomSheet {
	
    var bottomSheetDelegate: BottomSheetDelegate?
	var tableNeedsReload = false
	var cmdPanelShowingSmall = false
	var newTripsReceived:[Trip] = []
	var tripsDisplayed:[Trip] = []
	lazy var fetchedLocationsResultsController: NSFetchedResultsController<Location> = {
		
		let controller = NSFetchedResultsController(fetchRequest: Location.sortedFetchRequest,
													managedObjectContext: PersistentContainerSingleton.shared.persistentContainer.viewContext,
													sectionNameKeyPath: nil, cacheName: nil)
		controller.delegate = self
		do {
			try controller.performFetch()
		} catch {
			let nserror = error as NSError
			fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
		}
		return controller
	}()
	
	lazy var listenForTripsResultsController: NSFetchedResultsController<Trip> = {
		let controller = Trip.getAllTripsResultsController()
		return controller
	}()

	private let initialVisibleContentHeight: CGFloat = 180.0
	private let smallVisibleContentHeight: CGFloat = 140.0
	private let numCommandRows: Int = 3			// 4th one used right now for the locations so counted by number of locations
	private var scrollingCmdPicker:ScrollingCommandPicker? = nil

	private let commands = ["Drive","Bike","Walk","Transit","Drive / Walk","Transit / Walk","Drive / Transit / Walk"]
	private var curTripTypeDisplayed = TransportTypes.driving
	

	// MARK: - View overloads
	
    override func viewDidLoad() {
        super.viewDidLoad()
        
		tableView.register(UINib(nibName: "RoutePickerCmdPanel", bundle: nil), forCellReuseIdentifier: "RoutePickerCmdPanel")
		tableView.register(UINib(nibName: "RouteSearchCmdPanel", bundle: nil), forCellReuseIdentifier: "RouteSearchCmdPanel")
		tableView.register(UINib(nibName: "ScrollingCommandPicker", bundle: nil), forCellReuseIdentifier: "ScrollingCommandPickerID")
		tableView.register(UINib(nibName: "RouteDetailsCellID", bundle: nil), forCellReuseIdentifier: "RouteDetailsCellID")

		let screenHeight = UIScreen.main.bounds.size.height

        tableView.contentInset.top = screenHeight - initialVisibleContentHeight
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
		tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
		tableView.decelerationRate = .fast
		
		self.listenForTripsResultsController.delegate = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        bottomSheetDelegate?.bottomSheet(self, didScrollTo: tableView.contentOffset)
    
        // Make sure the content is always at least as high as the table view, to prevent the sheet
        // getting stuck half-way.
        if tableView.contentSize.height < tableView.bounds.height {
            tableView.contentSize.height = tableView.bounds.height
        }
    }

	// MARK: - ScrollingCommandDelegate

	func cmd(at pos: Int) -> String {
		return commands[pos]
	}
	
	func numCmds() -> Int {
		return commands.count
	}

	func isCmdSelected(at pos: Int) -> Bool {
		switch pos {
		case 0...commands.count:
			return (curTripTypeDisplayed == cmdPosToTripType(pos))
		default:
			return false
		}
	}

	func cmdSelected(at pos: Int) {
		switch pos {
		case 0...commands.count:
			if (curTripTypeDisplayed != cmdPosToTripType(pos)) {
				curTripTypeDisplayed = cmdPosToTripType(pos)
				let newTrips:[Trip]? = newTripsReceived.filter { $0.tripType == cmdPosToTripType(pos).rawValue }
				if (newTrips?.count ?? 0 > 0) {
					let trip = newTrips?[0]
					newTripsReceived.removeAll(where: {$0.tripType == cmdPosToTripType(pos).rawValue})
					tripsDisplayed.removeAll(where: {$0.tripType == cmdPosToTripType(pos).rawValue})
					tripsDisplayed.append(trip!)
					JourneySingleton.sharedInstance.curTripDisplayed = trip
				}
				else {
					let displayedTrips:[Trip]? = tripsDisplayed.filter { $0.tripType == cmdPosToTripType(pos).rawValue }
					if (displayedTrips?.count ?? 0 > 0) {
						let trip = displayedTrips?[0]
						JourneySingleton.sharedInstance.curTripDisplayed = trip
					}
					else {
						JourneySingleton.sharedInstance.curTripDisplayed = nil
					}
				}
			}
		default:
			print(pos)
		}
	}
	
	func cmdHasNewInfo(at pos:Int) -> Bool {
		switch pos {
		case 0...commands.count:
			let matchingTrips = newTripsReceived.filter { $0.tripType == cmdPosToTripType(pos).rawValue }
			return (matchingTrips.isEmpty == false)
		default:
			return false
		}
	}
	

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return (self.fetchedLocationsResultsController.fetchedObjects?.count)! + numCommandRows
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
		var cell:UITableViewCell
		if ( indexPath.row == 0 ) {
			cell = tableView.dequeueReusableCell(withIdentifier: "RoutePickerCmdPanel")!
		}
		else if ( indexPath.row == 1 ) {
			cell = tableView.dequeueReusableCell(withIdentifier: "ScrollingCommandPickerID")!
			scrollingCmdPicker = cell as?ScrollingCommandPicker
			scrollingCmdPicker?.config(scrollingCommandDelegate:self)
		}
		else if ( indexPath.row == 2 ) {
			cell = tableView.dequeueReusableCell(withIdentifier: "RouteSearchCmdPanel")!
		}
		else {
			cell = tableView.dequeueReusableCell(withIdentifier: "RouteDetailsCellID")!
			let loc = locationAt(indexPath)
			cell.textLabel?.text = 	loc.displayString()
		}
        cell.backgroundColor = .clear
        return cell
    }
	
	override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
		if (isLocationRow(indexPath)) {
			return true
		}
		else {
			return false
		}
	}
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		if (indexPath.row == 0) {
			return 26.0
		}
		else if (indexPath.row == 1) {
			return 30.0
		}
		else if (indexPath.row == 2) {
			return 110.0
		}
		else {
			return super.tableView(tableView, heightForRowAt: indexPath)
		}
	}
	
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

		if (isLocationRow(indexPath)) {
			let loc = locationAt(indexPath)
			let stop = MKMapPoint(CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude))
			JourneySingleton.sharedInstance.retrieveDrivingJourney(stop:stop, completionHandler: { error in
				
				DispatchQueue.main.async {
					
					tableView.deselectRow(at: indexPath, animated: true)
					
					// Auto collapse the view???
				}
			})
		}
		else {
			tableView.deselectRow(at: indexPath, animated: false)
		}
    }
	
	// MARK: - Custom routines
	
	func snapCmdPanel(toSmall small:Bool){
		let screenHeight = UIScreen.main.bounds.size.height
		if (small) {
			tableView.contentInset.top = screenHeight - smallVisibleContentHeight
			tableView.frame.origin.y = smallVisibleContentHeight
			tableView.setNeedsDisplay()
			bottomSheetDelegate?.snapToHeight(self, smallVisibleContentHeight)
			cmdPanelShowingSmall = true
		}
		else {
			tableView.contentInset.top = screenHeight - initialVisibleContentHeight
			tableView.frame.origin.y = initialVisibleContentHeight
			tableView.setNeedsDisplay()
			bottomSheetDelegate?.snapToHeight(self, initialVisibleContentHeight)
			cmdPanelShowingSmall = false
		}
	}
	
    // MARK: - Scroll view delegate
    
    override func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let targetOffset = targetContentOffset.pointee.y
        let pulledUpOffset: CGFloat = 0
		let pulledDownOffset: CGFloat = cmdPanelShowingSmall ? -smallVisibleContentHeight : -initialVisibleContentHeight
        if (pulledDownOffset...pulledUpOffset).contains(targetOffset) {
            if velocity.y < 0 {
                targetContentOffset.pointee.y = pulledDownOffset
            } else {
                targetContentOffset.pointee.y = pulledUpOffset
            }
        }
    }
	
	
	// MARK: - Private Convenience
	
	private func isLocationRow(_ indexPath:IndexPath) -> Bool {
		if (indexPath.row >= numCommandRows) {
			return true
		}
		else {
			return false
		}
	}
	
	private func locationAt(_ indexPath:IndexPath) -> Location {
		// Put state machine in here... right now just have 3 row types
		
		let newIndex = IndexPath(row:indexPath.row-numCommandRows, section:indexPath.section)
		return fetchedLocationsResultsController.object(at:newIndex)
	}
	
	private func cmdPosToTripType(_ pos:Int) -> TransportTypes {
		assert(
			(TransportTypes.driving.rawValue==0) &&
			(TransportTypes.bicycling.rawValue==1) &&
			(TransportTypes.walking.rawValue==2) &&
			(TransportTypes.transit.rawValue==3) &&
			(TransportTypes.driveWalk.rawValue==4) &&
			(TransportTypes.transitWalk.rawValue==5) &&
			(TransportTypes.driveTransitWalk.rawValue==6) &&
			(TransportTypes.unknown.rawValue==99))
		switch pos {
		case 0:
			return TransportTypes.driving
		case 1:
			return TransportTypes.bicycling
		case 2:
			return TransportTypes.walking
		case 3:
			return TransportTypes.transit
		case 4:
			return TransportTypes.driveWalk
		case 5:
			return TransportTypes.transitWalk
		case 6:
			return TransportTypes.driveTransitWalk
		default:
			return TransportTypes.unknown
		}
	}
}

// MARK: - NSFetchedResultsControllerDelegate
extension LocationsTableViewController {
	
	public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for fetchType: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
		
		// Might be a better way to figure out which kind of controller is calling but...
		let trip = anObject as? Trip
		let isTrip = trip?.arrivalTime != nil
		let location = anObject as? Location
		let isLocation = location?.latitude != nil

		if (isLocation) {
			tableNeedsReload = true
		}
		else if (isTrip) {
			if (fetchType == NSFetchedResultsChangeType.insert) || (fetchType == NSFetchedResultsChangeType.delete) {
				if (trip?.tripType != curTripTypeDisplayed.rawValue) {
					newTripsReceived.removeAll {$0.tripType == trip?.tripType}
					newTripsReceived.append(trip!)
				}
				else {
					newTripsReceived.removeAll {$0.tripType == trip?.tripType}
					tripsDisplayed.removeAll {$0.tripType == trip?.tripType}
					tripsDisplayed.append(trip!)
					JourneySingleton.sharedInstance.curTripDisplayed = trip
				}
				tableNeedsReload = true
			}
		}
	}

	public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		if (tableNeedsReload) {
			DispatchQueue.main.async {
				self.snapCmdPanel(toSmall: true)
				self.tableView.reloadData()
				self.scrollingCmdPicker?.collectionView.reloadData()		// hack but it won't refresh the unread properly
			}
			self.tableNeedsReload = false
		}
	}

}
