//
//  TextEditorVC.swift
//  Origami
//
//  Created by CloudCraft on 03.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import Foundation
class SimpleTextEditorVC : ElementTextEditingVC
{
    var editingDelegate:TextEditingDelegate?
    override func submitPressed(sender: UIBarButtonItem) {
        editingDelegate?.textEditor(self, wantsToSubmitNewText: editorTextView.text)
    }
    override func cancelPressed(sender: UIBarButtonItem) {
        editingDelegate?.textEditorDidCancel(self)
    }
}