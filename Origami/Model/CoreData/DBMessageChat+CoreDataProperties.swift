//
//  DBMessageChat+CoreDataProperties.swift
//  Origami
//
//  Created by CloudCraft on 22.10.15.
//  Copyright © 2015 CloudCraft. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension DBMessageChat {

    @NSManaged var creatorId: NSNumber?
    @NSManaged var dateCreated: NSDate?
    @NSManaged var elementId: NSNumber?
    @NSManaged var firstName: String?
    @NSManaged var messageId: NSNumber?
    @NSManaged var textBody: String?
    @NSManaged var targetContact: DBContact?
    @NSManaged var targetElement: DBElement?

}