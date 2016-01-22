//
//  DatePickerVC.swift
//  Origami
//
//  Created by CloudCraft on 28.10.15.
//  Copyright © 2015 CloudCraft. All rights reserved.
//

import UIKit

class DatePickerVC: UIViewController {
    
    var selectedDate:NSDate?
    var delegate:DatePickerDelegate?
    
    @IBOutlet var datePicker:UIDatePicker?
    
    override func viewDidLoad() {
        
        datePicker?.minimumDate = NSDate()
        //set one day ahead
        
        datePicker?.date = NSDate(timeInterval: 1.days, sinceDate: NSDate())
        
        let currentCalendar = NSCalendar.currentCalendar()
        let calendarConponentsFlags:NSCalendarUnit = [NSCalendarUnit.Year, .Month, .Day, .Hour, .Minute]
        if let datePick = datePicker
        {
            let components = currentCalendar.components(calendarConponentsFlags, fromDate: datePick.date)
            components.hour = 9
            components.minute = 0
            
            if let fixedDate = currentCalendar.dateFromComponents(components)
            {
                datePicker?.setDate(fixedDate, animated: false)// date = fixedDate
            }
        }
        
        configureDoneButton()
        
        super.viewDidLoad()
    }
    
    
    func configureDoneButton()
    {
        let doneButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "doneButtonTapped:")
        self.navigationItem.rightBarButtonItem = doneButtonItem
    }
    
    func doneButtonTapped(sender:UIBarButtonItem)
    {
        delegate?.datePickerViewController(self, didSetDate: datePicker?.date)
    }

}
