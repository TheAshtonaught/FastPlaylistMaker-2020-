//
//  AppDelegate.swift
//  Fast Playist Maker
//
//

import UIKit
import CoreData
import Firebase
import FirebaseDynamicLinks

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let stack = CoreDataStack(modelName: "Model")!
    let customURLScheme = "com.algebet.playlistcheetah1Xz"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseOptions.defaultOptions()?.deepLinkURLScheme = self.customURLScheme

        FirebaseApp.configure()
        //GADMobileAds.configure(withApplicationID: "ca-app-pub-3821799418903504~1593747306")

        stack.autoSave(90)
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {

        if let code = url.queryItemValueFor(key: "code") {
            let codeDict: [String: Any] = ["code": code]

            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "spotifyAuth"), object: nil, userInfo: codeDict)
        }
        
        

        
        return application(app, open: url, sourceApplication: nil, annotation: [:])
    }

    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        let dynamicLink = DynamicLinks.dynamicLinks().dynamicLink(fromCustomSchemeURL: url)
        if let dynamicLink = dynamicLink {

            handleIncomingDynamicLink(dynamicLink: dynamicLink)
            return true
        }
        
        return false
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        
        let dynamicLinks = DynamicLinks.dynamicLinks()
        
        let handled = dynamicLinks.handleUniversalLink(userActivity.webpageURL!) { (dlink, error) in
            
            guard let dynamicLink = dlink else {
                print("Failed restoration handler")
                return
            }
            
            self.handleIncomingDynamicLink(dynamicLink: dynamicLink)
            
        }
        
        if !handled {
            let message = "continueUserActivity webPageURL:\n\(userActivity.webpageURL?.absoluteString ?? "")"
            showDeepLinkAlertView(withMessage: message)
        }
        return handled
    }


    func handleIncomingDynamicLink(dynamicLink: DynamicLink) {
        print(dynamicLink.url?.absoluteString ?? "No Dynamic link")
        guard let lastPath = dynamicLink.url?.lastPathComponent else {
            print("error getting path components")
            return
        }
        
        print("The last past is \(lastPath)")
        
        guard let dynamicVC = self.window?.rootViewController?.storyboard?.instantiateViewController(withIdentifier: "DynamicPlaylistController") as? DynamicPlaylistVC else {
            return
        }
        
        dynamicVC.playlistID = lastPath
        
        self.window?.rootViewController = dynamicVC
        
    }
  

    func showDeepLinkAlertView(withMessage message: String) {
        let okAction = UIAlertAction.init(title: "OK", style: .default) { (action) -> Void in
            print("OK")
        }
        
        let alertController = UIAlertController.init(title: "Deep-link Data", message: message, preferredStyle: .alert)
        alertController.addAction(okAction)
        self.window?.rootViewController?.present(alertController, animated: true, completion: nil)
    }
    
 

    func applicationWillResignActive(_ application: UIApplication) {
       
        stack.save()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
       
        stack.save()
    }


}
 


extension AppDelegate {
    
    @objc func noConnectionCheckLoop(_ delayInSeconds : Int, vc: UIViewController) {
        if delayInSeconds > 0 {
            
            if !Reachability.isConnectedToNetwork() {
                let alert = UIAlertController(title: "No Internet Connection", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "ok", style: .default, handler: nil))
                vc.present(alert, animated: true, completion: nil)
            }
            
            let delayInNanoSeconds = UInt64(delayInSeconds) * NSEC_PER_SEC
            let time = DispatchTime.now() + Double(Int64(delayInNanoSeconds)) / Double(NSEC_PER_SEC)
            
            DispatchQueue.main.asyncAfter(deadline: time) {
                self.noConnectionCheckLoop(delayInSeconds, vc: vc)
            }
        }
    }
    
}
