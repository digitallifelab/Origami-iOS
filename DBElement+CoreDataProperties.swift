//
//  DBElement+CoreDataProperties.swift
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

extension DBElement {

    @NSManaged var elementId: NSNumber?
    @NSManaged var dateArchived: NSDate?
    @NSManaged var dateCreated: NSDate?
    @NSManaged var dateChanged: NSDate?
    @NSManaged var dateFinished: NSDate?
    @NSManaged var title: String?
    @NSManaged var details: String?
    @NSManaged var rootElementId: NSNumber?
    @NSManaged var dateRemind: NSDate?
    @NSManaged var finishState: NSNumber?
    @NSManaged var type: NSNumber?
    @NSManaged var isFavourite: NSNumber?
    @NSManaged var isSignal: NSNumber?
    @NSManaged var messages: NSSet?
    @NSManaged var attaches: NSSet?

}
