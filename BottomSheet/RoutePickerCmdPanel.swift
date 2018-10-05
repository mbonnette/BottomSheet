//
//  RoutePickerCmdPanel.swift
//  BottomSheet
//
//  Created by Michael Bonnette on 10/4/18.
//  Copyright © 2018 Simon Kågedal Reimer. All rights reserved.
//

import UIKit
import MapKit

class RoutePickerCmdPanel : UITableViewCell {
	
	@IBOutlet weak var routeButton: UIButton!
	@IBAction func fetchRoute(_ sender: UIButton) {

		sender.isEnabled = false
		UIApplication.shared.isNetworkActivityIndicatorVisible = true
		
		spinner.isHidden = false
		sender.isHidden = true
		spinner.startAnimating()
		
		let begin = MKMapPoint(CLLocationCoordinate2D(latitude: 42.377806, longitude: -71.111969))
		let end = MKMapPoint(CLLocationCoordinate2D(latitude: 42.481285, longitude: -71.214729))
		
		JourneySingleton.sharedInstance.retrieveDrivingJourney(start: begin, stop: end, completionHandler: { error in
			
			DispatchQueue.main.async {
				
				sender.isEnabled = true
				UIApplication.shared.isNetworkActivityIndicatorVisible = false
				self.spinner.stopAnimating()
				sender.isHidden = false
				
				guard let error = error else { return }
				
				let alert = UIAlertController(title: "Fetch locations error!",
											  message: error.localizedDescription,
											  preferredStyle: .alert)
				
				alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
				UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
				
			}
		})

	}

	override func draw(_ rect: CGRect) {
		super.draw(rect)
		
		if spinner.superview == nil, let superView = self.superview {
			superView.addSubview(spinner)
			superView.bringSubviewToFront(spinner)
			spinner.center = routeButton.center
			spinner.isHidden = true
		}
	}

	lazy var spinner: UIActivityIndicatorView = {
		let indicator = UIActivityIndicatorView(style: .whiteLarge)
		indicator.color = .gray
		indicator.backgroundColor = .black
		indicator.hidesWhenStopped = true
		return indicator
	}()
	

}