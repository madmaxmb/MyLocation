//
//  MapViewController.swift
//  MyLocation
//
//  Created by Максим on 07.03.16.
//  Copyright © 2016 Maxim. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class MapViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    
    var managedObjectContext: NSManagedObjectContext! {
        didSet {
            NSNotificationCenter.defaultCenter().addObserverForName(
                NSManagedObjectContextObjectsDidChangeNotification,
                object: managedObjectContext,
                queue: NSOperationQueue.mainQueue(),
                usingBlock: { notification in
                if self.isViewLoaded(){
                    self.updateLocations()
                }
            })
        }
    }
    var locations = [Location]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateLocations()
        
        if !locations.isEmpty {
            showLocation()
        }
    }
    
    @IBAction func showUser() {
        let region = MKCoordinateRegionMakeWithDistance(mapView.userLocation.coordinate, 1000, 1000)
        mapView.setRegion(mapView.regionThatFits(region), animated: true)
    }
    
    @IBAction func showLocation() {
        let region = regionForAnnotations(locations)
        mapView.setRegion(region, animated: true)
    }
    
    func updateLocations() {
        mapView.removeAnnotations(locations)
        
        let entity = NSEntityDescription.entityForName("Location", inManagedObjectContext: managedObjectContext)
        
        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = entity
        
        locations = try! managedObjectContext.executeFetchRequest(fetchRequest) as! [Location]
        
        mapView.addAnnotations(locations)
    }
    
    func regionForAnnotations(annotations: [MKAnnotation]) -> MKCoordinateRegion {
        var region: MKCoordinateRegion
        
        switch annotations.count {
        case 0:
            region = MKCoordinateRegionMakeWithDistance(mapView.userLocation.coordinate, 1000, 1000)
        case 1:
            let annotation = annotations[annotations.count - 1]
            region = MKCoordinateRegionMakeWithDistance(annotation.coordinate, 1000, 1000)
        default:
            var topLeftCoordinate = CLLocationCoordinate2D(latitude: -90, longitude: 180)
            var bottomRightCoordinate = CLLocationCoordinate2D(latitude: 90, longitude: -180)
            
            for annotation in annotations {
                topLeftCoordinate.latitude = max(topLeftCoordinate.latitude, annotation.coordinate.latitude)
                topLeftCoordinate.longitude = min(topLeftCoordinate.longitude, annotation.coordinate.longitude)
                
                bottomRightCoordinate.latitude = min(bottomRightCoordinate.latitude, annotation.coordinate.latitude)
                bottomRightCoordinate.longitude = max(bottomRightCoordinate.longitude, annotation.coordinate.longitude)
            }
            let center = CLLocationCoordinate2D(
                latitude: topLeftCoordinate.latitude - (topLeftCoordinate.latitude - bottomRightCoordinate.latitude)/2,
                longitude: topLeftCoordinate.longitude - (topLeftCoordinate.longitude -
                    bottomRightCoordinate.longitude) / 2)
            let extraSpace = 1.1
            
            let span = MKCoordinateSpan(
                latitudeDelta: abs(topLeftCoordinate.latitude - bottomRightCoordinate.latitude) * extraSpace,
                longitudeDelta: abs(topLeftCoordinate.longitude - bottomRightCoordinate.longitude) * extraSpace
            )
            
            region = MKCoordinateRegion(center: center, span: span)
        }
        return mapView.regionThatFits(region)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "EditLocation" {
            let navigator = segue.destinationViewController as! UINavigationController
            let controller = navigator.topViewController as! LocationDetailViewController
            
            controller.managedObjectContext = managedObjectContext
            
            let button = sender as! UIButton
            let location = locations[button.tag]
            controller.locationToEdit = location
        }
    }
}

extension MapViewController: MKMapViewDelegate {
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is Location else {
            return nil
        }
        
        let identifier = "Location"
        var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) as! MKPinAnnotationView!
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            
            annotationView.enabled = true
            annotationView.canShowCallout = true
            annotationView.pinTintColor = UIColor(red: 0.32, green: 0.82, blue: 0.4, alpha: 1)
            annotationView.tintColor = UIColor(white: 0.0, alpha: 0.5)
            
            let rightButton = UIButton(type: .DetailDisclosure)
            rightButton.addTarget(self, action: Selector("showLocationDetails:"), forControlEvents: .TouchUpInside)
            
            annotationView.rightCalloutAccessoryView = rightButton
        } else {
            annotationView.annotation = annotation
        }
        let button = annotationView.rightCalloutAccessoryView as! UIButton
        if let index = locations.indexOf(annotation as! Location) {
            button.tag = index
        }
        
        return annotationView
    }
    
    func showLocationDetails(sender: UIButton) {
        performSegueWithIdentifier("EditLocation", sender: sender)
    }
}

extension MapViewController: UINavigationBarDelegate {
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return .TopAttached
    }
}