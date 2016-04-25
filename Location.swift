//
//  Location.swift
//  MyLocation
//
//  Created by Максим on 04.03.16.
//  Copyright © 2016 Maxim. All rights reserved.
//

import Foundation
import CoreData
import MapKit

let applicationDocumentDirectory: String = {
    let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
    return paths[0]
}()

class Location: NSManagedObject, MKAnnotation {

// Insert code here to add functionality to your managed object subclass
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(latitude, longitude)
    }
    var title: String? {
        if locationDescription.isEmpty {
            return "(No Description)"
        } else {
            return locationDescription
        }
    }
    var subtitle: String? {
        return category
    }
    
    var hasPhoto: Bool {
        return photoID != nil
    }
    var photoPath: String {
        assert(photoID != nil, "No photo ID set")
        let fileName = "Photo-\(photoID!.integerValue).jpg"
        return (applicationDocumentDirectory as NSString).stringByAppendingPathComponent(fileName)
    }
    var photoImage: UIImage? {
        return UIImage(contentsOfFile: photoPath)
    }
    
    class func nextPhotoID() -> Int {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let currentID = userDefaults.integerForKey("PhotoID")
        userDefaults.setInteger(currentID + 1, forKey: "PhotoID")
        userDefaults.synchronize()
        return currentID
    }
    
    func removePhotoFile() {
        if hasPhoto {
            let path = photoPath
            let fileManager = NSFileManager.defaultManager()
            if fileManager.fileExistsAtPath(path) {
                do {
                    try fileManager.removeItemAtPath(path)
                } catch {
                    print("Error removing file \(error)")
                }
            }
        }
    }
}
