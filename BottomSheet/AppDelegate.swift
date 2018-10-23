//
//  Copyright © 2018 Simon Kågedal Reimer. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		
		// Print the db location?
		let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
		print(urls[urls.count-1] as URL)

		let window = UIWindow(frame: UIScreen.main.bounds)
        
        let mapViewController = MapViewController()
        let shortcutsViewController = LocationsTableViewController()
        window.rootViewController = BottomSheetContainerViewController(mainViewController: mapViewController,
                                                                       sheetViewController: shortcutsViewController)
        window.makeKeyAndVisible()
        self.window = window
        
        return true
    }
    
}

