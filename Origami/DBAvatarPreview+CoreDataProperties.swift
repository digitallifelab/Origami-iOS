//
//  DBAvatarPreview+CoreDataProperties.swift
//  Origami
//
//  Created by CloudCraft on 23.10.15.
//  Copyright © 2015 CloudCraft. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension DBAvatarPreview {

    @NSManaged var avatarPreviewData: NSData?
    @NSManaged var avatarUserId: NSNumber?
    @NSManaged var fileName: String?

}
