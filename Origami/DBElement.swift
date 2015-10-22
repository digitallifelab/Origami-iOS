//
//  DBElement.swift
//  Origami
//
//  Created by CloudCraft on 22.10.15.
//  Copyright © 2015 CloudCraft. All rights reserved.
//

import Foundation
import CoreData

class DBElement: NSManagedObject {

// Insert code here to add functionality to your managed object subclass

    func fillInfoFromInMemoryElement(element:Element)
    {
        self.elementId      = element.elementId
        self.rootElementId  = NSNumber(integer: element.rootElementId)
        self.responsibleId  = NSNumber(integer: element.responsible)
        self.title          = element.title
        self.details        = element.details
        self.dateChanged    = element.changeDate?.dateFromServerDateString()
        self.dateCreated    = element.createDate.dateFromServerDateString()
        self.dateRemind     = element.remindDate
        self.dateArchived   = element.archiveDate?.dateFromServerDateString()
        self.dateFinished   = element.finishDate
        self.type           = NSNumber(integer:element.typeId)
        self.finishState    = NSNumber(integer: element.finishState)
        self.isFavourite    = NSNumber(bool:element.isFavourite)
        self.isSignal       = NSNumber(bool:element.isSignal)
        self.hasAttaches    = NSNumber(bool: element.hasAttaches)
    }
}
