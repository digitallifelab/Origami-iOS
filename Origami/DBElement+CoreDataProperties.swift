//
//  DBElement+CoreDataProperties.swift
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

extension DBElement {

    @NSManaged var dateArchived: NSDate?
    @NSManaged var dateChanged: NSDate?
    @NSManaged var dateCreated: NSDate?
    @NSManaged var dateFinished: NSDate?
    @NSManaged var dateRemind: NSDate?
    @NSManaged var details: String?
    @NSManaged var elementId: NSNumber?
    @NSManaged var finishState: NSNumber?
    @NSManaged var hasAttaches: NSNumber?
    @NSManaged var isFavourite: NSNumber?
    @NSManaged var isSignal: NSNumber?
    @NSManaged var responsibleId: NSNumber?
    @NSManaged var rootElementId: NSNumber?
    @NSManaged var title: String?
    @NSManaged var type: NSNumber?
    @NSManaged var attaches: NSSet?
    @NSManaged var messages: NSSet?

}
