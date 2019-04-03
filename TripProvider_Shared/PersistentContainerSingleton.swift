//
//  JourneySingleton.swift
//  TripProvider
//
//  Created by Michael Bonnette on 10/3/18.
//  Copyright © 2018 Apple, Inc. All rights reserved.
//

import Foundation
import CoreData


class PersistentContainerSingleton {
	static let shared: PersistentContainerSingleton = {
		let instance = PersistentContainerSingleton()

		// setup code

		return instance
	}()

	/**
	Persistent container: use NSPersistentContainer to create the Core Data stack
	*/
	lazy var persistentContainer: NSPersistentContainer = {
		
		let container = NSPersistentContainer(name: "TripProvider")
		
		/**
		fatalError() causes the application to generate a crash log and terminate.
		You should not use this function in a shipping application.
		*/
		container.loadPersistentStores(completionHandler: { (_, error) in
			guard let error = error as NSError? else { return }
			fatalError("Unresolved error \(error), \(error.userInfo)")
		})
		
		container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
		container.viewContext.undoManager = nil // We don't need undo so set it to nil.
		container.viewContext.shouldDeleteInaccessibleFaults = true
		
		/**
		Merge the changes from other contexts automatically.
		You can also choose to merge the changes by observing NSManagedObjectContextDidSave
		notification and calling mergeChanges(fromContextDidSave notification: Notification)
		*/
		container.viewContext.automaticallyMergesChangesFromParent = true
		
		return container
	}()

	
	//MARK:______________________________
	//MARK: CLASS routines
	

	
	
	//MARK:______________________________
	//MARK: OBJECT routines
	
	
}
