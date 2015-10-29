//
//  DBAttach+CoreDataProperties.swift
//  Origami
//
//  Created by CloudCraft on 29.10.15.
//  Copyright © 2015 CloudCraft. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension DBAttach : CreateDateComparable{

    @NSManaged var attachId: NSNumber?
    @NSManaged var creatorId: NSNumber?
    @NSManaged var dateCreated: NSDate?
    @NSManaged var fileName: String?
    @NSManaged var fileSize: NSNumber?
    @NSManaged var fileType: String?
    @NSManaged var preview: DBAttachImagePreview?
    @NSManaged var targetElement: DBElement?

}
