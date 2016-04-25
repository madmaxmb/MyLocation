//
//  CurrentLocationViewController.swift
//  MyLocation
//
//  Created by Максим on 01.03.16.
//  Copyright © 2016 Maxim. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData
import QuartzCore
import AudioToolbox

class CurrentLocationViewController: UIViewController{

    @IBOutlet weak var messageLable: UILabel!
    @IBOutlet weak var latitudeTextLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeTextLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var tagButton: UIButton!
    @IBOutlet weak var getLocationButton: UIButton!
    
    @IBOutlet weak var containerView: UIView!
    
    let locationManager = CLLocationManager()
    var location: CLLocation?
    var updatingLocation = false
    var lastLocationError: NSError?
    
    let geocoder = CLGeocoder()
    var placemark: CLPlacemark?
    var perfomingReverseGeocoding = false
    var lastGeocodingError: NSError?
    
    var timer: NSTimer?
    
    var managedObjectContext: NSManagedObjectContext!
    
    var logoVisible = false
    lazy var logoButton: UIButton = {
        let button = UIButton(type: .Custom)
        button.setBackgroundImage(UIImage(named: "Logo"), forState: .Normal)
        button.sizeToFit()
        button.addTarget(self, action: Selector("getLocation"), forControlEvents: .TouchUpInside)
        button.center.x = CGRectGetMidX(self.view.bounds)
        button.center.y = 220
        return button
    }()
    
    var soundID: SystemSoundID = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        loadSoundEffect("Sound.caf")
        updateLabels()
        configureGetButton()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func getLocation() {
        let authStatus = CLLocationManager.authorizationStatus()
        if logoVisible {
            hideLogoView()
        }
        if authStatus == .NotDetermined { // ask authorization
            locationManager.requestWhenInUseAuthorization()
            return
        }
        if authStatus == .Denied || authStatus == .Restricted {
            showLocationServicesDeniedAlert()
            return
        }
        if updatingLocation {
            stopLocationManager()
        } else {
            location = nil
            lastLocationError = nil
            placemark = nil
            lastGeocodingError = nil
            startLocationManager()
        }
        updateLabels()
        configureGetButton()
    }
    
    func configureGetButton() {
        let spinnerTag = 1000
        
        if updatingLocation {
            getLocationButton.setTitle("Stop", forState: .Normal)
            if view.viewWithTag(spinnerTag) == nil {
                let spinner = UIActivityIndicatorView(activityIndicatorStyle: .White)
                spinner.center = messageLable.center
                spinner.center.y += spinner.bounds.size.height / 2 + 15
                spinner.startAnimating()
                spinner.tag = spinnerTag
                containerView.addSubview(spinner)
            }
        } else {
            getLocationButton.setTitle("Get My Location", forState: .Normal)
            if let spinner = view.viewWithTag(spinnerTag) {
                spinner.removeFromSuperview()
            }
        }
    }

    func updateLabels() {
        if let location = location {
            latitudeTextLabel.hidden = false
            latitudeLabel.text = String(format: "%.8f", location.coordinate.latitude)
            
            longitudeTextLabel.hidden = false
            longitudeLabel.text = String(format: "%.8f", location.coordinate.longitude)
            
            tagButton.hidden = false
            messageLable.text = ""
            if let placemark = placemark {
                addressLabel.text = stringFromPlacemark(placemark)
            } else if perfomingReverseGeocoding {
                addressLabel.text = "Searching for Address..."
            } else if lastGeocodingError != nil {
                addressLabel.text = "Error Finding Address"
            } else {
                addressLabel.text = "No Address Founf"
            }
        } else {
            latitudeTextLabel.hidden = true
            longitudeTextLabel.hidden = true
            
            // showing error message 
            let statusMessage: String
            if let error = lastLocationError {
                if error.code == CLError.Denied.rawValue && error.domain == kCLErrorDomain {
                    statusMessage = "Locatio Services Disable"
                } else {
                    statusMessage = "Error Getting Locations"
                }
            } else if !CLLocationManager.locationServicesEnabled() {
                statusMessage = "Locatio Services Disable"
            } else if updatingLocation {
                statusMessage = "Searching..."
            } else {
                statusMessage =  ""
                showLogoView()
            }
            
            messageLable.text = statusMessage
            addressLabel.text = ""
            tagButton.hidden = true
        }
    }

    func stringFromPlacemark(placemark: CLPlacemark) -> String{
        var firstAddressLine = ""
        
        firstAddressLine.addText( placemark.subThoroughfare)
        firstAddressLine.addText(placemark.thoroughfare, withSeparator: " ")
        
        var secondAddressLine = ""
        
        secondAddressLine.addText(placemark.locality)
        secondAddressLine.addText(placemark.administrativeArea, withSeparator: " ")
        secondAddressLine.addText(placemark.postalCode, withSeparator: " ")

        firstAddressLine.addText(secondAddressLine, withSeparator: "\n")
        return firstAddressLine
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "TagLocation" {
            let navigatorController = segue.destinationViewController as! UINavigationController
            let controller = navigatorController.topViewController as! LocationDetailViewController
            controller.coordinate = location!.coordinate
            controller.placemark = placemark
            controller.managedObjectContext = managedObjectContext
        }
    }
    
    // MARK: - Logo View 
    
    func showLogoView() {
        if !logoVisible{
            logoVisible = true
            containerView.hidden = true
            view.addSubview(logoButton)
        }
    }
    
    func hideLogoView() {
        if !logoVisible {
            return
        }
        logoVisible = false
        containerView.hidden = false
        containerView.center.x = view.bounds.size.width * 2
        containerView.center.y = 40 + containerView.bounds.size.height / 2
        
        let centerX = CGRectGetMidX(view.bounds)
        let panelMover = CABasicAnimation(keyPath: "position")
        panelMover.removedOnCompletion = false
        panelMover.fillMode = kCAFillModeForwards
        panelMover.duration = 0.6
        panelMover.fromValue = NSValue(CGPoint: containerView.center)
        panelMover.toValue = NSValue(CGPoint:CGPoint(x: centerX, y: containerView.center.y))
        
        panelMover.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        
        panelMover.delegate = self
        containerView.layer.addAnimation(panelMover, forKey: "panelMover")
        
        let logoMover = CABasicAnimation(keyPath: "position")
        logoMover.removedOnCompletion = false
        logoMover.fillMode = kCAFillModeForwards
        logoMover.duration = 0.5
        logoMover.fromValue = NSValue(CGPoint: logoButton.center)
        logoMover.toValue = NSValue(CGPoint: CGPoint(x: -centerX, y: logoButton.center.y))
        logoMover.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        
        logoButton.layer.addAnimation(logoMover, forKey: "logoMover")
        
        let logoRotator = CABasicAnimation(keyPath: "transform.rotation.z")
        
        logoRotator.removedOnCompletion = false
        logoRotator.fillMode = kCAFillModeForwards
        logoRotator.duration = 0.5
        logoRotator.fromValue = 0.0
        logoRotator.toValue = -2 * M_PI
        logoRotator.timingFunction = CAMediaTimingFunction( name: kCAMediaTimingFunctionEaseIn)
        logoButton.layer.addAnimation(logoRotator, forKey: "logoRotator")
    }
    
    override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        containerView.layer.removeAllAnimations()
        containerView.center.x = view.bounds.size.width / 2
        containerView.center.y = 40 + containerView.bounds.size.height / 2
        
        logoButton.layer.removeAllAnimations()
        logoButton.removeFromSuperview()
    }
    
    // MARK: - Sound Effect
    
    func loadSoundEffect(name: String) {
        if let path = NSBundle.mainBundle().pathForResource(name, ofType: nil) {
        
            let fileURL = NSURL.fileURLWithPath(path, isDirectory: false)
            let error = AudioServicesCreateSystemSoundID(fileURL, &soundID)
            if error != kAudioServicesNoError {
                print("Error code \(error) loading sound at path: \(path)")
            }
        }
    }
    func unloadSoundEffect() {
        AudioServicesDisposeSystemSoundID(soundID)
        soundID = 0
    }
    func playSoundEffect() {
        AudioServicesPlaySystemSound(soundID)
    }
}

extension CurrentLocationViewController: CLLocationManagerDelegate {
    // MARK: - CLLocationManagerDelegate
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
//        print("didFatalError \(error)")
        if error.code == CLError.LocationUnknown.rawValue {
            return
        }
        lastLocationError = error
        stopLocationManager()
        updateLabels()
        configureGetButton()
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations.last!
//        print("didUpdateLocation \(newLocation)")
        
        if newLocation.timestamp.timeIntervalSinceNow < -5 {
            return
        }
        if newLocation.horizontalAccuracy < 0 {
            return
        }
        
        var distance = CLLocationDistance(DBL_MAX) // DBL_MAX - double maximum
        if let lication = location {
            distance = newLocation.distanceFromLocation(lication)
        }
        
        if location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy {
            lastLocationError = nil
//            print("***Save location")
            location = newLocation
            updateLabels()
            configureGetButton()
            if location!.horizontalAccuracy <= locationManager.desiredAccuracy {
//                print("***Well done!!!!")
                stopLocationManager()
            }
            
            if distance > 0 {
                perfomingReverseGeocoding = false
            }
            
            if !perfomingReverseGeocoding {
                
//                print("*** Going to decode")
                perfomingReverseGeocoding = true
                geocoder.reverseGeocodeLocation(location!, completionHandler: {
                    placemarks, error in
                    self.lastGeocodingError = error
                    if error == nil, let pmark = placemarks where !pmark.isEmpty {
                        if self.placemark == nil {
                            self.playSoundEffect()
                        }
                        self.placemark = pmark.last!
                    } else {
                        self.placemark = nil
                    }
                    self.perfomingReverseGeocoding = false
                    self.updateLabels()
                    self.configureGetButton()
                })
            }
        } else if distance < 1.0 {
//            print("*** Bad Location")
            let timeInterval = newLocation.timestamp.timeIntervalSinceDate(location!.timestamp)
            if timeInterval > 5 {
//                print("***Force done!!!!")
                stopLocationManager()
                updateLabels()
                configureGetButton()
            }
        }

    }
    
    func startLocationManager() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            updatingLocation = true
            timer = NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: Selector("didTimeOut"), userInfo: nil, repeats: false) // создание таймера на 60 секунд.
        }
    }
    
    func didTimeOut() {
//        print("*** Time Out")
        stopLocationManager()
        
        if location == nil {
            lastLocationError = NSError(domain: "MyLocationsErrorDomain", code: 1, userInfo: nil)
        }
        
        updateLabels()
        configureGetButton()
    }
    
    private func stopLocationManager() {
        if updatingLocation {
            if let timer = timer {
                timer.invalidate()// остановка таймера
            }
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            updatingLocation = false
        }
    }
    
    private func showLocationServicesDeniedAlert() {
        let alert = UIAlertController(title: "Location Services Disable", message: "Please enable location services to this app in Settings", preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "Ok", style: .Default, handler: nil)
        alert.addAction(okAction)
        presentViewController(alert, animated: true, completion: nil)
    }
}