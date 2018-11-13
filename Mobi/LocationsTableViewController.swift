//
//  LocationsTableViewController.swift
//
//  Created by Michael Bonnette on Nov 9, 2018
//  Copyright © 2018 BlueMedl Inc. All rights reserved.
//


import UIKit
import CoreData
import MapKit

class LocationsTableViewController: BottomSheetMgr, NSFetchedResultsControllerDelegate, ScrollingCommandDelegate {
	
	private let commands = ["Drive",
							"Bike",
							"Walk",
							"Transit",
							"Car Share",
							"Bike Share",
							"Ride Share",
							"Park & Walk",
							"Park & Bike Share",
							"Park & Ride Share",
							"Transit & Bike Share",
							"Transit & Ride Share",
							"Transit & Car Share",
							"Bike Share & Car Share"
							]
	private var newTripsReceived:[Trip] = []
	private var tripsDisplayed:[Trip] = []
	private let numCommandRows: Int = 3			// 4th one used right now for the locations so counted by number of locations
	private var scrollingCmdPicker:ScrollingCommandPicker? = nil
	private var tableNeedsReload = false

	
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

	

	// MARK: - View overloads
	
    override func viewDidLoad() {
        super.viewDidLoad()
        
		tableView.register(UINib(nibName: "RouteSearchCmdPanel", bundle: nil), forCellReuseIdentifier: "RouteSearchCmdPanel")
		tableView.register(UINib(nibName: "ScrollingCommandPicker", bundle: nil), forCellReuseIdentifier: "ScrollingCommandPickerID")
		tableView.register(UINib(nibName: "RouteDetailsCellID", bundle: nil), forCellReuseIdentifier: "RouteDetailsCellID")

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
			return (JourneySingleton.sharedInstance.curSelectedTransportType == cmdPosToTripType(pos))
		default:
			return false
		}
	}

	func cmdSelected(at pos: Int) {
		switch pos {
		case 0...commands.count:
			if (JourneySingleton.sharedInstance.curSelectedTransportType != cmdPosToTripType(pos)) {
				JourneySingleton.sharedInstance.curSelectedTransportType = cmdPosToTripType(pos)
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

		var cell:UITableViewCell?

		// Handles cell 0
		cell = super.tableView(tableView, cellForRowAt: indexPath)

		if (cell == nil) {
			if ( indexPath.row == 1 ) {
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
				cell?.textLabel?.text = 	loc.displayString()
			}
		}
        cell?.backgroundColor = .clear
		return cell!
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
			JourneySingleton.sharedInstance.stopPoint = stop
			JourneySingleton.sharedInstance.retrieve(journeyType: TransportTypes.driving, completionHandler: { error in

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
#if DEBUG
		assert(
			(TransportTypes.driving.rawValue==0) &&
				(TransportTypes.bicycling.rawValue==1) &&
				(TransportTypes.walking.rawValue==2) &&
				(TransportTypes.transit.rawValue==3) &&
				(TransportTypes.carshare.rawValue==4) &&
				(TransportTypes.bikeshare.rawValue==5) &&
				(TransportTypes.rideshare.rawValue==6) &&
				(TransportTypes.parkandwalk.rawValue==7) &&
				(TransportTypes.parkandride.rawValue==8) &&
				(TransportTypes.parkandbikeshare.rawValue==9) &&
				(TransportTypes.parkandrideshare.rawValue==10) &&
				(TransportTypes.transitandbikeshare.rawValue==11) &&
				(TransportTypes.transitandrideshare.rawValue==12) &&
				(TransportTypes.transitandcarshare.rawValue==13) &&
				(TransportTypes.bikeshareandcarshare.rawValue==14) &&
				(TransportTypes.unknown.rawValue==99))
#endif
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
			return TransportTypes.carshare
		case 5:
			return TransportTypes.bikeshare
		case 6:
			return TransportTypes.rideshare
		case 7:
			return TransportTypes.parkandwalk
		case 8:
			return TransportTypes.parkandride
		case 9:
			return TransportTypes.parkandbikeshare
		case 10:
			return TransportTypes.parkandrideshare
		case 11:
			return TransportTypes.transitandbikeshare
		case 12:
			return TransportTypes.transitandrideshare
		case 13:
			return TransportTypes.transitandcarshare
		case 14:
			return TransportTypes.bikeshareandcarshare
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
				if (trip?.tripType != JourneySingleton.sharedInstance.curSelectedTransportType.rawValue) {
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
