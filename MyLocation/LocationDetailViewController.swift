//
//  LocationDetailViewController.swift
//  MyLocation
//
//  Created by Максим on 02.03.16.
//  Copyright © 2016 Maxim. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData

class LocationDetailViewController: UITableViewController {
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var addPhotoLabel: UILabel!
    
    var date = NSDate()
    
    var descriptionText = ""
    var categoryName = "No Category"
    var coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var placemark: CLPlacemark?
    
    var image: UIImage? {
        didSet {
            if image != nil {
                showImage(image!)
            }
        }
    }
    
    var locationToEdit: Location! {
        didSet {
            if let location = locationToEdit {
                descriptionText = location.locationDescription
                categoryName = location.category
                coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                placemark = location.placemark
                date = location.date
            }
        }
    }
    var managedObjectContext: NSManagedObjectContext!
    
    var observer: AnyObject!
    
    private let dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateStyle = .MediumStyle
        formatter.timeStyle = .ShortStyle
        return formatter
    }()
    
    
    @IBAction func done() {
        let hudView = HudView.hudInView(navigationController!.view, animated: true)
        let location: Location
        
        if let temp = locationToEdit {
            hudView.text = "Updated"
            location = temp
        } else {
            hudView.text = "Tagged"

            location = NSEntityDescription.insertNewObjectForEntityForName("Location", inManagedObjectContext: managedObjectContext) as! Location
            location.photoID = nil
        }
        
        location.locationDescription = descriptionTextView.text
        location.category = categoryName
        location.latitude = coordinate.latitude
        location.longitude = coordinate.longitude
        location.date = date
        location.placemark = placemark
        
        if let image = image {
            if !location.hasPhoto {
                location.photoID = Location.nextPhotoID()
            }
            if let data = UIImageJPEGRepresentation(image, 0.5) {
                do {
                    try data.writeToFile(location.photoPath, options: .DataWritingAtomic)
                } catch {
                    print("Error writing file: \(error)")
                }
            }
        }
        
        do {
            try managedObjectContext.save()
        } catch {
            fatalCoreDataError(error)
        }
        
        afterDelay(0.6) {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    @IBAction func cancel() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    @IBAction func categoryPickerDidPickCategory(segue: UIStoryboardSegue){
        let controller = segue.sourceViewController as! CategoryPickerViewController
        categoryName = controller.selectedCategotyName
        categoryLabel.text = categoryName
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let location = locationToEdit {
            title = "Eddit Location"
            if location.hasPhoto {
                if let image = location.photoImage{
                    showImage(image)
                }
            }
        }
        
        tableView.backgroundColor = UIColor.blackColor()
        tableView.separatorColor = UIColor(white: 1.0, alpha: 0.2)
        tableView.indicatorStyle = .White
        
        descriptionTextView.text = descriptionText
        descriptionTextView.textColor = UIColor.whiteColor()
        descriptionTextView.backgroundColor = UIColor.blackColor()
        
        categoryLabel.text = categoryName
        
        latitudeLabel.text = String(format: "%.8f", coordinate.latitude)
        longitudeLabel.text = String(format: "%.8f", coordinate.longitude)
        
        if let placemark = placemark {
            addressLabel.text = stringFromPlacemark(placemark)
        } else {
            addressLabel.text = "No Address Found"
        }
        addressLabel.textColor = UIColor(white: 1.0, alpha: 0.4)
        addressLabel.highlightedTextColor = addressLabel.textColor
        
        dateLabel.text = formatDate(date)
        
        addPhotoLabel.textColor = UIColor.whiteColor()
        addPhotoLabel.backgroundColor = UIColor.blackColor()
        
        let tapAnyWhere = UITapGestureRecognizer(target: self, action: Selector("dismissKeyboard:"))
        tapAnyWhere.cancelsTouchesInView = false
        view.addGestureRecognizer(tapAnyWhere)
        
        listenForBackgroundNotification()
    }
    
    // MARK: - UITebleViewDelegate
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            return 88
        case (1, _):
            return imageView.hidden ? 44: 220
        case (2, 2):
            addressLabel.frame.size = CGSize(width: view.bounds.size.width - 115, height: 10000)
            addressLabel.sizeToFit()
            addressLabel.frame.origin.x = view.bounds.size.width - addressLabel.frame.size.width - 15
            return addressLabel.frame.size.height + 20
        default:
            return 44
        }
    }
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if indexPath.section == 0 || indexPath.section == 1 {
            return indexPath
        } else {
            return nil
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 && indexPath.row == 0 {
            descriptionTextView.becomeFirstResponder()
        }
        if indexPath.section == 1 && indexPath.row == 0 {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            pickPhoto()
        }
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        //  called just before a cell becomes visible
        cell.backgroundColor = UIColor.blackColor()
        
        if let textLabel = cell.textLabel {
            textLabel.textColor = UIColor.whiteColor()
            textLabel.highlightedTextColor = textLabel.textColor
        }
        if let detailLabel = cell.detailTextLabel {
            detailLabel.textColor = UIColor(white: 1.0, alpha: 0.4)
            detailLabel.highlightedTextColor = detailLabel.textColor
        }
        if indexPath.row == 2 {
            let addressLabel = cell.viewWithTag(100) as! UILabel
            addressLabel.textColor = UIColor.whiteColor()
            addressLabel.highlightedTextColor = addressLabel.textColor
        }
        let selectionView = UIView(frame: CGRect.zero)
        selectionView.backgroundColor = UIColor(white: 1.0, alpha: 0.2)
        cell.selectedBackgroundView = selectionView
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "PickedCategory" {
            let controller = segue.destinationViewController as! CategoryPickerViewController
            controller.selectedCategotyName = categoryName
        }
    }
    
    private func stringFromPlacemark(placemark: CLPlacemark) -> String {
        var address = ""
        
        address.addText(placemark.subThoroughfare)
        address.addText(placemark.thoroughfare, withSeparator: " ")
        address.addText(placemark.locality, withSeparator: ", ")
        address.addText(placemark.administrativeArea, withSeparator: ", ")
        address.addText(placemark.postalCode, withSeparator: ", ")
        address.addText(placemark.country, withSeparator: ", ")
        
        return address
    }
    private func formatDate(date: NSDate) -> String {
        return dateFormatter.stringFromDate(date)
    }
    
    func dismissKeyboard(gestureRecognizer: UIGestureRecognizer) {
        let point = gestureRecognizer.locationInView(tableView) // точка в ктотрой произошло нажатие
        let indexPath = tableView.indexPathForRowAtPoint(point) // ищем по точке indexPath
        if indexPath != nil && indexPath!.row == 0 && indexPath!.section == 0 {
            return
        }
        descriptionTextView.resignFirstResponder()
    }
    
    func listenForBackgroundNotification() {
        observer = NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidEnterBackgroundNotification,
            object: nil,
            queue: NSOperationQueue.mainQueue(),
            usingBlock: { [weak self] _ in
                if let strongSelf = self {
                    if strongSelf.presentedViewController != nil {
                        strongSelf .dismissViewControllerAnimated(true, completion: nil)
                    }
                    strongSelf.descriptionTextView.resignFirstResponder()
                }
        })
    }
    
    deinit {
        print("Deinit \(self)")
        NSNotificationCenter.defaultCenter().removeObserver(observer)
    }
}

extension LocationDetailViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func pickPhoto() {
        if UIImagePickerController.isSourceTypeAvailable(.Camera) {
            showPhotoMenu()
        } else {
            choosePhotoFromLibrary()
        }
    }
    
    func showPhotoMenu() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        let takePhotoAction = UIAlertAction(title: "Take Photo", style: .Default, handler:
            { _ in
                self.takePhotoWithCamera()
        })
        alertController.addAction(takePhotoAction)
        
        let choosePhotoAction = UIAlertAction(title: "Choose From Library", style: .Default, handler:
            { _ in
                self.choosePhotoFromLibrary()
        })
        alertController.addAction(choosePhotoAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func takePhotoWithCamera() {
        let imagePicker = MyImagePickerController()
        imagePicker.sourceType = .Camera
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.view.tintColor = view.tintColor
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    func choosePhotoFromLibrary() {
        let imagePicker = MyImagePickerController()
        imagePicker.sourceType = .PhotoLibrary
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.view.tintColor = view.tintColor
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        image = info[UIImagePickerControllerEditedImage] as? UIImage

        dismissViewControllerAnimated(true, completion: nil)
        tableView.reloadData()
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func showImage(image: UIImage) {
        imageView.image = image
        imageView.hidden = false
        imageView.frame = CGRect(x: 10, y: 10, width: 260, height: 200)
        addPhotoLabel.hidden = true
    }
}