//
//  DBPerson+CoreDataProperties.swift
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

extension DBPerson {

    @NSManaged var firstName: String?
    @NSManaged var lastName: String?
    @NSManaged var userName: String?
    @NSManaged var mood: String?
    @NSManaged var country: NSNumber?
    @NSManaged var language: NSNumber?
    @NSManaged var sex: NSNumber?
    @NSManaged var birthDay: NSDate?
    @NSManaged var avatarPreview: NSManagedObject?

}
