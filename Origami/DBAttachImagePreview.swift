//
//  DBAttachImagePreview.swift
//  Origami
//
//  Created by CloudCraft on 22.10.15.
//  Copyright © 2015 CloudCraft. All rights reserved.
//

import Foundation
import CoreData

class DBAttachImagePreview: NSManagedObject {

// Insert code here to add functionality to your managed object subclass
    override func prepareForDeletion() {
        super.prepareForDeletion()
        print("Will delete  DBAttachImagePreview  for attachID: \(self.attachId)")
    }

}
