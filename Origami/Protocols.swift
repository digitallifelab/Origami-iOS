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
    func newMessagesWereAdded()
}

extension MessageObserver
{
    
    func newMessagesWereAdded(){
        
    }
    
    func newMessagesAdded(messages:[Message]){
        
    }
}

protocol DatePickerDelegate
{
    func datePickerViewController(vc:DatePickerVC, didSetDate date:NSDate?)
}

protocol ElementSelectionDelegate
{
    func didTapOnElement(elementId:Int)
}

protocol AttachmentSelectionDelegate
{
    func attachedFileTapped(attachFile:AttachFile)
}

protocol AttachmentCellDelegate
{
    func attachTappedAtIndexPath(indexPath:NSIndexPath)
    func attachesCount() -> Int
    func titleForAttachmentAtIndexPath(indexPath:NSIndexPath) -> String?
    func imageForAttachmentAtIndexPath(indexPath:NSIndexPath) -> UIImage?
}

protocol AttachViewerDelegate
{
    func attachViewerDeleteAttachButtonTapped(viewer:UIViewController)
    func attachViewerShouldAllowDeletion(viewer:UIViewController) -> Bool
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

protocol AttachPickingDelegate {
    func mediaPicker(picker:AnyObject, didPickMediaToAttach mediaFile:MediaFile)
    func mediaPickerDidCancel(picker:AnyObject)
    func mediaPickerShouldAllowEditing(picker:AnyObject) -> Bool
}

protocol ElementComposingDelegate
{
    func newElementComposerWantsToCancel(composer:NewElementComposerViewController)
    func newElementComposer(composer:NewElementComposerViewController, finishedCreatingNewElement newElement:Element)
    
////optional calls. //TODO: protocol extensions?
//    func newElementComposerTitleForNewElement(composer:NewElementComposerViewController) -> String?// { return nil }
//    func newElementComposerDetailsForNewElement(composer:NewElementComposerViewController) -> String?// { return nil }
//    func newElementForComposer(composer:NewElementComposerViewController) -> Element?// { return nil }
    var newElementDetailsInfo:String? { get set }
}

extension ElementComposingDelegate
{
    func newElementComposerTitleForNewElement(composer: NewElementComposerViewController) -> String? {
        if let fullInfo = self.newElementDetailsInfo
        {
            let countChars = fullInfo.characters.count
            
            if countChars > 40
            {
                let startIndex = fullInfo.startIndex
                let toIndex = startIndex.advancedBy(40)
                let cutString = fullInfo.substringToIndex(toIndex)
                return cutString
            }
            return fullInfo
        }
        return nil
    }
    
    func newElementComposerDetailsForNewElement(composer: NewElementComposerViewController) -> String? {
        
        return self.newElementDetailsInfo
    }
    func newElementForComposer(composer:NewElementComposerViewController) -> Element? {
        return nil
    }
}


protocol MessageTapDelegate
{
    func chatMessageWasTapped(message:Message?)
}

protocol UserProfileCollectionCellDelegate
{
    func showAvatarPressed()
    func changeAvatarPressed()
    func changeInfoPressed(cellType:ProfileTextCellType)
    func changeSexSwitchPresed(newValue:Int)
}

protocol TableItemPickerDelegate
{
    func itemPicker(itemPicker:AnyObject, didPickItem item:AnyObject)
    func itemPickerDidCancel(itemPicker:AnyObject)
}

protocol AllContactsDelegate
{
    func reloadUserContactsSender(sender:UIViewController?)
}

protocol CreateDateComparable {
    var dateCreated:NSDate?{ get set }
}

enum OrigamiError: ErrorType
{
    case PreconditionFailure(message:String?)
    case UnknownError
}

