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
	
	@IBAction func fetchRoute(_ sender: UIButton) {

		sender.isEnabled = false
		UIApplication.shared.isNetworkActivityIndicatorVisible = true
		spinner.isHidden = false
		sender.isHidden = true
		spinner.startAnimating()
		
		JourneySingleton.sharedInstance.retrieveDrivingJourney(completionHandler: { error in
			DispatchQueue.main.async {
				sender.isEnabled = true
				UIApplication.shared.isNetworkActivityIndicatorVisible = false
				self.spinner.stopAnimating()
				sender.isHidden = false
				guard let error = error else {
					self.fetchBikingRoute()
					return
				}
				self.showFetchError(error: error)
			}
		})
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
		
		if spinner.superview == nil {
			self.addSubview(spinner)
			self.bringSubviewToFront(spinner)
			spinner.center = routeButton.center
			spinner.isHidden = true
		}
	}
	
	
	func showFetchError(error:Error) {
		let alert = UIAlertController(title: "Fetch locations error!",
									  message: error.localizedDescription,
									  preferredStyle: .alert)
		
		alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
		UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
	}

}
