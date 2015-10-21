//
//  DBMessageChat+CoreDataProperties.swift
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

extension DBMessageChat {

    @NSManaged var messageId: NSNumber?
    @NSManaged var creatorId: NSNumber?
    @NSManaged var textBody: String?
    @NSManaged var dateCreated: NSDate?
    @NSManaged var firstName: String?
    @NSManaged var elementId: NSNumber?
    @NSManaged var targetElement: DBElement?
    @NSManaged var targetContact: DBContact?

}
