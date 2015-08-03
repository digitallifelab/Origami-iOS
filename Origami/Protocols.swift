//
//  Protocols.swift
//  Origami
//
//  Created by CloudCraft on 04.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import Foundation
import UIKit

protocol MessageObserver
{
    func newMessagesAdded(messages:[Message])
}

protocol ElementSelectionDelegate
{
    func didTapOnElement(element:Element)
}

protocol AttachmentSelectionDelegate
{
    func attachedFileTapped(attachFile:AttachFile)
}

protocol ButtonTapDelegate
{
    func didTapOnButton(button:UIButton)
}

protocol ChatInputViewDelegate
{
    func chatInputView(inputView:ChatTextInputView, wantsToChangeToNewSize desiredSize:CGSize)
    func chatInputView(inputView:ChatTextInputView, sendButtonTapped button:UIButton)
    func chatInputView(inputView:ChatTextInputView, attachButtonTapped button:UIButton)
}

@objc protocol ElementTextEditingDelegate
{
    func titleCellEditTitleTapped(cell:ElementDashboardTextViewCell)
    func descriptionCellEditDescriptionTapped(cell:ElementDashboardTextViewCell)
    optional
        func titleCellwantsToChangeElementIsFavourite(cell:ElementDashboardTextViewCell)
}

protocol AttachPickingDelegate {
    func mediaPicker(picker:AnyObject, didPickMediaToAttach mediaFile:MediaFile)
    func mediaPickerDidCancel(picker:AnyObject)
}

protocol ElementComposingDelegate
{
    func newElementComposerWantsToCancel(composer:NewElementComposerViewController)
    func newElementComposer(composer:NewElementComposerViewController, finishedCreatingNewElement newElement:Element)
}

protocol TextEditingDelegate
{
    func textEditorDidCancel(editor:AnyObject)
    func textEditor(editor: AnyObject, wantsToSubmitNewText newText:String)
}

protocol MessageTapDelegate
{
    func chatMessageWasTapped(message:Message?)
}
