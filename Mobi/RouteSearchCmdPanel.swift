//
//  RouteSearchCmdPanel.swift
//  BottomSheet
//
//  Created by Michael Bonnette on 10/4/18.
//  Copyright © 2018 BlueMEDL. All rights reserved.
//

import UIKit
import MapKit

class RouteSearchCmdPanel : UITableViewCell {
	
	@IBOutlet weak var searchLocationTextField: UITextField!
	@IBOutlet weak var searchButton: UIButton!
	@IBOutlet weak var routeButton: UIButton!

	lazy var spinner: UIActivityIndicatorView = {
		let indicator = UIActivityIndicatorView(style: .whiteLarge)
		indicator.color = .gray
		indicator.backgroundColor = .black
		indicator.hidesWhenStopped = true
		return indicator
	}()
	lazy var tripChangedListener = {
		DispatchQueue.main.async {
			if (JourneySingleton.sharedInstance.curTripDisplayed == nil) {
				self.routeButton.isHidden = false
			}
			else {
				self.routeButton.isHidden = true
			}
		}
	}
	var listeningOnTrips:Bool = false
	
	@IBAction func fetchRoute(_ sender: UIButton) {

		// For now have driving grab 3 main forms of transportation
		sender.isEnabled = false
		UIApplication.shared.isNetworkActivityIndicatorVisible = true
		spinner.isHidden = false
		sender.isHidden = true
		spinner.startAnimating()
		switch JourneySingleton.sharedInstance.curSelectedTransportType {
		case .driving:
			JourneySingleton.sharedInstance.retrieveDrivingJourney(completionHandler: { error in
				DispatchQueue.main.async {
					UIApplication.shared.isNetworkActivityIndicatorVisible = false
					self.spinner.stopAnimating()
					sender.isEnabled = true
					guard let error = error else {
						self.fetchBikingRoute()
						return
					}
					sender.isHidden = false
					self.showFetchError(error: error)
				}
			})
		case .bicycling:
			JourneySingleton.sharedInstance.retrieve(journeyType: JourneySingleton.sharedInstance.curSelectedTransportType, completionHandler: { error in
				DispatchQueue.main.async {
					UIApplication.shared.isNetworkActivityIndicatorVisible = false
					self.spinner.stopAnimating()
					sender.isEnabled = true
					guard let error = error else {
						self.fetchWalkingRoute()
						return
					}
					sender.isHidden = false
					self.showFetchError(error: error)
				}
			})
		case .walking,
			 .transit:
			JourneySingleton.sharedInstance.retrieve(journeyType: JourneySingleton.sharedInstance.curSelectedTransportType, completionHandler: { error in
				DispatchQueue.main.async {
					UIApplication.shared.isNetworkActivityIndicatorVisible = false
					self.spinner.stopAnimating()
					sender.isEnabled = true
					guard let error = error else { return }
					sender.isHidden = false
					self.showFetchError(error: error)
				}
			})
		default:
			print("--- Unknown journey type -----")
			UIApplication.shared.isNetworkActivityIndicatorVisible = false
			sender.isEnabled = true
			sender.isHidden = false
			spinner.isHidden = true
			spinner.stopAnimating()
		}
}

	func fetchBikingRoute() {
		UIApplication.shared.isNetworkActivityIndicatorVisible = true
		spinner.isHidden = false
		spinner.startAnimating()
		
		JourneySingleton.sharedInstance.retrieveBikingJourney(completionHandler: { error in
			DispatchQueue.main.async {
				UIApplication.shared.isNetworkActivityIndicatorVisible = false
				self.spinner.stopAnimating()
				guard let error = error else {
					self.fetchWalkingRoute()
					return
				}
				self.showFetchError(error: error)
			}
		})
	}

	func fetchWalkingRoute() {
		UIApplication.shared.isNetworkActivityIndicatorVisible = true
		spinner.isHidden = false
		spinner.startAnimating()
		
		JourneySingleton.sharedInstance.retrieveWalkingJourney(completionHandler: { error in
			DispatchQueue.main.async {
				UIApplication.shared.isNetworkActivityIndicatorVisible = false
				self.spinner.stopAnimating()
				guard let error = error else { return }
				self.showFetchError(error: error)
			}
		})
	}

	@IBAction func findLocation(_ sender: Any) {
		searchLocationTextField.isHidden = !searchLocationTextField.isHidden
		if ( searchLocationTextField.isHidden ) {
			routeButton.isHidden = false
			routeButton.resignFirstResponder()
			searchLocationTextField.endEditing(true)
		}
		else {
			routeButton.isHidden = true
			searchLocationTextField.resignFirstResponder()
			searchLocationTextField.becomeFirstResponder()
		}
	}
	
	
	override func draw(_ rect: CGRect) {
		super.draw(rect)
		if (!listeningOnTrips) {
			JourneySingleton.sharedInstance.notifyOnTripChange(with: tripChangedListener)
			listeningOnTrips = true
		}

		if spinner.superview == nil {
			self.addSubview(spinner)
			self.bringSubviewToFront(spinner)
			spinner.center = routeButton.center
			spinner.isHidden = true
		}
	}
	
	
	func showFetchError(error:Error) {
		let alert = UIAlertController(title: "Mobi Result",
									  message: error.localizedDescription,
									  preferredStyle: .alert)
		
		alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
		UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
	}

}
