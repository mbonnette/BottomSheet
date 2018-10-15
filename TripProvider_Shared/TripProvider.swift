/*
 Copyright (C) 2018 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A class to fetch data from the remote server and save it to the Core Data store.
  When requested (by clicking the Fetch Locations button), this class creates an asynchronous `NSURLSession` task
  to retrieve JSON data about locations. Location data is compared with any existing managed objects to
  determine whether there are new locations. New managed objects are created to represent new data, and saved to
  the persistent store on a private queue.
 */

import CoreData
import MapKit

/**
 Error handling
 An error domain, and an error code enumeration.
*/
let locationsErrorDomain = "LocationsErrorDomain"

enum TripProviderErrorCode: NSInteger {
    case networkUnavailable = 101
    case wrongDataFormat = 102
}

class TripProvider: NSObject {
    
    /**
     Delegate of the fetchedResultsController.
     Give consumers a chance to upate UI when the fetchedResultsController content is changed.
    */
    weak var fetchedResultsControllerDelegate: NSFetchedResultsControllerDelegate?

    /**
     Persistent container: use NSPersistentContainer to create the Core Data stack
    */
//    lazy var persistentContainer: NSPersistentContainer = {
//
//        let container = NSPersistentContainer(name: "TripProvider")
//
//        /**
//         fatalError() causes the application to generate a crash log and terminate.
//         You should not use this function in a shipping application.
//        */
//        container.loadPersistentStores(completionHandler: { (_, error) in
//            guard let error = error as NSError? else { return }
//            fatalError("Unresolved error \(error), \(error.userInfo)")
//        })
//
//        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
//        container.viewContext.undoManager = nil // We don't need undo so set it to nil.
//        container.viewContext.shouldDeleteInaccessibleFaults = true
//
//        /**
//         Merge the changes from other contexts automatically.
//         You can also choose to merge the changes by observing NSManagedObjectContextDidSave
//         notification and calling mergeChanges(fromContextDidSave notification: Notification)
//        */
//        container.viewContext.automaticallyMergesChangesFromParent = true
//
//        return container
//    }()
	
	/**
	NSFetchedResultsController is available on macOS since 10.12.
	Create a controller for "Location" entity and perform fetch.
	*/
	lazy var fetchedLocationsResultsController: NSFetchedResultsController<Location> = {

		let controller = NSFetchedResultsController(fetchRequest: Location.sortedFetchRequest,
													managedObjectContext: PersistentContainerSingleton.shared.persistentContainer.viewContext,
													sectionNameKeyPath: nil, cacheName: nil)
		controller.delegate = fetchedResultsControllerDelegate
		
		do {
			try controller.performFetch()
		} catch {
			let nserror = error as NSError
			fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
		}
		
		return controller
	}()
	
	/**
	NSFetchedResultsController is available on macOS since 10.12.
	Create a controller for "Trip" entity, sorting with "time" field, and perform fetch.
	*/
	lazy var fetchedTripsResultsController: NSFetchedResultsController<Trip> = {
				
		let controller = NSFetchedResultsController(fetchRequest: Trip.sortedFetchRequest,
													managedObjectContext: PersistentContainerSingleton.shared.persistentContainer.viewContext,
													sectionNameKeyPath: nil, cacheName: nil)
		controller.delegate = fetchedResultsControllerDelegate
		
		do {
			try controller.performFetch()
		} catch {
			let nserror = error as NSError
			fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
		}
		
		return controller
	}()

	
	
	func fetchTrip(start startLoc:MKMapPoint, stop stopLoc:MKMapPoint, _ type:segmentTypes, completionHandler: @escaping (Error?) -> Void) {
	
		let urlString =
				"https://api.takemobi.com/intermodal/v1/routes?origin=" +
					String(startLoc.coordinate.latitude) + "," +
					String(startLoc.coordinate.longitude) +
				"&destination=" +
					String(stopLoc.coordinate.latitude) + "," +
					String(stopLoc.coordinate.longitude) +
				"&mode=" +
					Segment.segmentTypeString(type) +
				"&departure_time=now"
	
		print(urlString)
		fetchTrip(withURLString: urlString, completionHandler: completionHandler)
	}
	
	
    /**
     Fetch trip from the remote server.
	
	 --- HTTP / HTTPS note from original example
     Create an `NSURLSession` and then session task to contact the earthquake
     server and retrieve JSON data. Because this server is out of our control
     and does not offer a secure communication channel, we'll use the http
     version of the URL and add "earthquake.usgs.gov" to the "NSExceptionDomains"
     value in the apps's info.plist. When you commmunicate with your own
     servers, or when the services you use offer a secure communication
     option, you should always prefer to use HTTPS.
    */
	private func fetchTrip(withURLString:String, completionHandler: @escaping (Error?) -> Void) {
        
		let session = URLSession(configuration: .default)

		/**
         Use the http version URL and add the domain name to the "NSExceptionDomains" value in
         the NSAppTransportSecurity entry of info.plist because this server is out of our control
         and does not offer a https version.
        */
//				let jsonURL = URL(string: "http://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_month.geojson")!
//				let task = session.dataTask(with: jsonURL) { data, _, error in

//		let jsonURL = URL(string: "https://api.takemobi.com/intermodal/v1/routes?origin=42.377806,-71.111969&destination=42.481285,-71.214729&mode=driving&departure_time=now")!

		let jsonURL = URL(string: withURLString)!
		let task = session.dataTask(with: jsonURL) { data, _, error in

		
//		let jsonURL = URL(string:"https://api.takemobi.com/intermodal/v1/routes?origin=42.377806,-71.111969&destination=42.481285,-71.214729&mode=driving&departure_time=now")
//		var routeURLRequest = URLRequest(url:jsonURL!)
//		routeURLRequest.setValue("application/json", forHTTPHeaderField: "Accept")
//		routeURLRequest.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
//		routeURLRequest.setValue("Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6Ik1FUXhORUU0TjBVeE56WkJPVU01TURoRk9UQTVOamsyTmpjM1F6TkRNVGd4T1RVNVF6VkJPQSJ9.eyJpc3MiOiJodHRwczovL3Rha2Vtb2JpLmF1dGgwLmNvbS8iLCJzdWIiOiJmMnlQTjBYMDdaZDdydWNWaGdJeGo1d0pneWJoTTUxN0BjbGllbnRzIiwiYXVkIjoiaHR0cHM6Ly9hcGkudGFrZW1vYmkuY29tIiwiaWF0IjoxNTM2NjMxNDI0LCJleHAiOjE1MzY3MTc4MjQsImF6cCI6ImYyeVBOMFgwN1pkN3J1Y1ZoZ0l4ajV3Smd5YmhNNTE3IiwiZ3R5IjoiY2xpZW50LWNyZWRlbnRpYWxzIn0.PneY12AAlBe0bBn2ffhB8J_idlO87OpTIDwas3-rWSa_jgQftwzNPbtgXSXS8OnV9sk19i_HjUt6Q9OU2HxS3XIxmA7rsTGUkPgmtV5iUXr9KhpVJ2wjnvXPOIIuLLjbj1GVWNeyYWwZz7TScCbjzw8BLQHHNSPEljuOabVeopHakrDXDMKBF3E1MX9H_5zqOaXDo6DUxi8-dJb_y-_IhzIYoOKAq696GxeiXqAahlBMlzMzXeHMA7pfiitd9XhoXOrHw8efsAEev7-lTx2tSkOd7jd37IOEqkLfFsX5YlgWUcpduNp5Erqi_kOjrprNCq_srBO5OywPSRUI6KSY2A",
//			forHTTPHeaderField: "Authorization")
//		let task = session.dataTask(with: routeURLRequest) { data, _, error in
			
			
            // If we don't get data back, alert the user.
            guard let data = data else {
                let description = NSLocalizedString("Could not get data from the remote server", comment: "")
                let fetchError = NSError(domain: locationsErrorDomain, code: TripProviderErrorCode.networkUnavailable.rawValue,
                                         userInfo: [NSLocalizedDescriptionKey: description, NSUnderlyingErrorKey: error as Any])
                completionHandler(fetchError)
                return
            }
            
            // If we get data but can't digest it, alert the user.
			var newData = data
			if ( !JSONSerialization.isValidJSONObject(data) ) {
				// Specific data looking at appears to have an enclosing [] which these routines don't like
				print("Format of JSON not being read properly")
				var c = newData.first!
				print("first char - ",c," buffer size= ", newData.count)
				while (c == 91) {	// 91 == '['
					newData = newData.dropFirst()
					if ( JSONSerialization.isValidJSONObject(newData) ) {
						print("Looks okay now")
					}
					c = newData.first!
					print("new first char - ",c," buffer size= ", newData.count)
				}
				newData = newData.dropLast()
			}

            do {
                let jsonObject = try JSONSerialization.jsonObject(with: newData, options: [])
                
                if let jsonDictionary = jsonObject as? [AnyHashable: Any] {
                    try self.importTrip(from: jsonDictionary)
                }
            } catch {
                let description = NSLocalizedString("Could not digest fetched data", comment: "")
                let fetchError = NSError(domain: locationsErrorDomain, code: TripProviderErrorCode.wrongDataFormat.rawValue,
                                         userInfo: [NSLocalizedDescriptionKey: description, NSUnderlyingErrorKey: error as Any])
                completionHandler(fetchError)
                return
            }
            
            completionHandler(nil)

        }
        task.resume() // If the task is created, start it by calling resume.
    }
    
    /**
     Private functions for saving JSON to the Core Data store.
     Import a json dictionary into the Core Data store.
    */
    private func importTrip(from jsonDictionary: [AnyHashable: Any]) throws {
		/**
		Create a context on a private queue to:
		- Fetch existing locations to compare with incoming data.
		- Create new locations as required.
		*/
		let taskContext = PersistentContainerSingleton.shared.persistentContainer.newBackgroundContext()
		taskContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
		taskContext.undoManager = nil // We don't need undo so set it to nil.
		

		// Build out the trip and start/stop locatioins
		var trip:Trip? = nil
		do {
			trip = Trip.newTrip(inContext: taskContext)
			try trip?.update(with:jsonDictionary, inContext:taskContext )
		} catch {
			let nserror = error as NSError
			fatalError("Error reading trip \(nserror), \(nserror.userInfo)")
		}

       /**
         Sort the dictionaries by code so they can be compared in parallel with
         existing segments.
        */
//		guard let quakeDictionaries = jsonDictionary["features"] as? [[String: AnyObject]] else {
		guard let segmentDictionaries = jsonDictionary["segments"] as? [[String: AnyObject]] else {

			let description = NSLocalizedString("Segments data doesn't have the right type!", comment: "")
            throw NSError(domain: locationsErrorDomain, code: TripProviderErrorCode.wrongDataFormat.rawValue,
                          userInfo: [NSLocalizedDescriptionKey: description])
        }
        
        let sortedSegmentDictionaries = try segmentDictionaries.sorted { lhs, rhs in
            
//			guard let lhsResult = lhs["properties"]?["code"] as? String, let rhsResult = rhs["properties"]?["code"] as? String else {
			guard let lhsResult = lhs["id"] as? String, let rhsResult = rhs["id"] as? String else {

                let description = NSLocalizedString("Segments do not have right id type!", comment: "")
                throw NSError(domain: locationsErrorDomain, code: TripProviderErrorCode.wrongDataFormat.rawValue,
                              userInfo: [NSLocalizedDescriptionKey: description])
            }
            return lhsResult < rhsResult
        }
        
        // To avoid a high memory footprint, process records in batches.
        let batchSize = 256
        let count = sortedSegmentDictionaries.count
        
        var numBatches = count / batchSize
        numBatches += count % batchSize > 0 ? 1 : 0
        
        for batchNumber in 0 ..< numBatches {
            let batchStart = batchNumber * batchSize
            let batchEnd = batchStart + min(batchSize, count - batchNumber * batchSize)
            let range = batchStart..<batchEnd
            
            let segmentsBatch = Array(sortedSegmentDictionaries[range])
            
            // Stop importing if hitting an unsuccessful import.
            if !importOneBatch(segmentsBatch, trip!, taskContext) {
                return
            }
        }
    }
    
    /**
     Import one batch of locations.
     NSManagedObjectContext.performAndWait doesn't rethrow so we catch throws
     within the closure and use a return value to indicate if the import is successfult.
     Note that we reset the context to clean up the cache and low the memory footprint.
    */
	private func importOneBatch(_ segmentsBatch: [[String: AnyObject]],_ trip:Trip,_ taskContext: NSManagedObjectContext) -> Bool {
        
        var success = false
        taskContext.performAndWait { // Wait doesn't block as taskContext is a background context
            
            /**
             Fetch the existing records with the same code, then remove them and create new records with the latest data
             to replace them.
            */
            let matchingSegmentRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Segment")
            
            let codesOrNil: [NSNumber?] = segmentsBatch.map { dictionary in
				//                return dictionary["properties"]?["code"] as? String
				// print (dictionary["id"] as? NSNumber as Any)
				return dictionary["id"] as? NSNumber
            }
            guard let codes = codesOrNil as? [NSNumber] else {
                print("Error: Properties or code doesn't have the right type!")
                return
            }

			matchingSegmentRequest.predicate = NSPredicate(format: "identifier in %@", argumentArray: [codes])

            // Create batch delete request and set the result type to .resultTypeObjectIDs so that we can merge the changes
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: matchingSegmentRequest)
            batchDeleteRequest.resultType = .resultTypeObjectIDs
            
            // Execute the request to de batch delete and merge the changes to viewContext, which triggers the UI update
            do {
                let batchDeleteResult = try taskContext.execute(batchDeleteRequest) as? NSBatchDeleteResult
                
                if let deletedObjectIDs = batchDeleteResult?.result as? [NSManagedObjectID] {
                    NSManagedObjectContext.mergeChanges(fromRemoteContextSave: [NSDeletedObjectsKey: deletedObjectIDs],
                                                        into: [PersistentContainerSingleton.shared.persistentContainer.viewContext])
                }
            } catch {
                print("Error: \(error)\nCould not batch delete existing records.")
                return
            }
            
            // Create new records.
            for segmentDictionary in segmentsBatch {
                
				let segment = Segment.newSegment(inContext: taskContext)
				
                /**
                 Set the attribute values the location and overall trip objects object.
                 If the data is not valid, delete the object and continue to process the next one.
                */
				do {
					try segment.update(with: segmentDictionary, inContext: taskContext)
					trip.addToSegments(segment)
				} catch {
					print("Error: \(error)\nThe segment object will be deleted.")
					taskContext.delete(segment)
				}
			}
            
            // Save all the changes just made and reset the taskContext to free the cache.
            if taskContext.hasChanges {
                do {
                    try taskContext.save()
                } catch {
                    print("Error: \(error)\nCould not save Core Data context.")
                    return
                }
                taskContext.reset() // Reset the context to clean up the cache and low the memory footprint.
            }
            success = true
        }
        return success
    }
}
