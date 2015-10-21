//
//  DBMessageService+CoreDataProperties.swift
//  Origami
//
//  Created by CloudCraft on 21.10.15.
//  Copyright © 2015 CloudCraft. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension DBMessageService {

    @NSManaged var type: NSNumber?
    @NSManaged var targetId: NSNumber?
    @NSManaged var messageId: NSNumber?
    @NSManaged var dateCreated: NSDate?
    @NSManaged var firstName: String?

}
