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

	private var scrollingCmdPicker:ScrollingCommandPicker? = nil
	private let initialVisibleContentHeight: CGFloat = 150.0
	private let smallVisibleContentHeight: CGFloat = 120.0

	private let commands = ["Drive","Walk","Transit","Drive / Walk","Transit / Walk","Drive / Transit / Walk"]
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
		return (self.fetchedLocationsResultsController.fetchedObjects?.count)! + 2
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
			if (loc.name == "") || (loc.name == "origin") || (loc.name == "destination") && (loc.address != nil) {
				cell.textLabel?.text = loc.address
			}
			else {
				cell.textLabel?.text = loc.name
			}
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
			return 16.0
		}
		else if (indexPath.row == 1) {
			return 30.0
		}
		else if (indexPath.row == 2) {
			return 80.0
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
		if (indexPath.row > 2) {
			return true
		}
		else {
			return false
		}
	}
	
	private func locationAt(_ indexPath:IndexPath) -> Location {
		// Put state machine in here... right now just have 3 row types
		
		let newIndex = IndexPath(row:indexPath.row-2, section:indexPath.section)
		return fetchedLocationsResultsController.object(at:newIndex)
	}
	
	private func cmdPosToTripType(_ pos:Int) -> TransportTypes {
		switch pos {
		case 0:
			return TransportTypes.driving
		case 1:
			return TransportTypes.walking
		case 2:
			return TransportTypes.transit
		case 3:
			return TransportTypes.driveWalk
		case 4:
			return TransportTypes.transitWalk
		case 5:
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
			if ((fetchType == NSFetchedResultsChangeType.insert) || (fetchType == NSFetchedResultsChangeType.delete)) {
				tableNeedsReload = true
			}
		}
		else if (isTrip) {
			if (fetchType == NSFetchedResultsChangeType.insert) {
				if (trip?.tripType != curTripTypeDisplayed.rawValue) {
					newTripsReceived.removeAll {$0.tripType == trip?.tripType}
					newTripsReceived.append(trip!)
					tableView.reloadData()			// just need cmd to change to unread but this will do it
				}
				else {
					newTripsReceived.removeAll {$0.tripType == trip?.tripType}
					tripsDisplayed.removeAll {$0.tripType == trip?.tripType}
					tripsDisplayed.append(trip!)
					JourneySingleton.sharedInstance.curTripDisplayed = trip
					tableView.reloadData()
				}
			}
		}
	}

	public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		
		if ( controller is NSFetchedResultsController<Location>) {
			if (tableNeedsReload) {
				snapCmdPanel(toSmall: true)
				tableView.reloadData()
				tableNeedsReload = false
			}
		}
	}

}
