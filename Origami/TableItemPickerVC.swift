//
//  TableListPickerVCViewController.swift
//  Origami
//
//  Created by CloudCraft on 31.08.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class TableItemPickerVC: UIViewController , UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView:UITableView!
    var delegate:TableItemPickerDelegate?
    var pickerType:TableItemPickerType = .Country
    
    var startItems:[AnyObject]?
    
    var currentItems:[[String:[String]]]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        switch self.pickerType
        {
        case .Country:
            currentItems = createIndexedDataSourceForCountries(startItems as? [Country])
        case .Language:
            currentItems = createIndexedDataSourceForLanguages(startItems as? [Language])
        }
        
        self.navigationController?.navigationBar.tintColor = kDayNavigationBarBackgroundColor
        
        tableView.delegate = self
        tableView.dataSource = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    

    func createIndexedDataSourceForCountries(countries:[Country]?) -> [[String:[String]]]?
    {
        if let array = countries
        {
            var countrieNamesFirstLettersSet = Set<String>()
            for aCountry in array
            {
                if count(aCountry.countryName) > 1
                {
                    let endIndex = advance(aCountry.countryName.startIndex, 1)
                    let firstLetterSubstring = aCountry.countryName.substringToIndex(endIndex)
                    if !countrieNamesFirstLettersSet.contains(firstLetterSubstring)
                    {
                        countrieNamesFirstLettersSet.insert(firstLetterSubstring)
                    }
                }
            }
            
            var firstLettersArray = Array(countrieNamesFirstLettersSet)
            
            firstLettersArray.sort( < )
            
            println("\(firstLettersArray)")
            
        }
        return nil
    }
    
    func createIndexedDataSourceForLanguages(languages:[Language]?) -> [[String:[String]]]?
    {
        if let array = languages
        {
            
        }
        return nil
    }
    
    //MARK: UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let items = currentItems
        {
            return items.count
        }
        return 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let items = currentItems
        {
            let dict = items[section]
            
            if let key = titleForSection(section), items = dict[key]
            {
                return items.count
            }
        }
        return 0
    }
    
    func titleForSection(section:Int) -> String?
    {
        if let items = currentItems
        {
            let item = items[section]
            
            let key = items.first?.keys.first
            return key
        }
        return nil
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if let title = titleForSection(section)
        {
            let range = advance(title.startIndex, 1)
            return title.substringToIndex(range)
        }
        return nil
    }
   
    func textForCellAtIndexPath(indexPath:NSIndexPath) -> String
    {
        if let items = currentItems
        {
            let currentDict = items[indexPath.section]
            if let titleOfSection = titleForSection(indexPath.section)
            {
                if  let values = currentDict[titleOfSection]
                {
                    let aString = values[indexPath.row]
                
                    return aString
                }
            }
        }
        return "-"
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("SelectionSell", forIndexPath: indexPath) as! UITableViewCell
        
        cell.textLabel?.text = textForCellAtIndexPath(indexPath)
        cell.selectionStyle = .None
        
        return cell
    }
    
    //MARK: UITableVIewDelegate
    func tableView(tableView:UITableView, didSelectRowAtIndexPath indexPath:NSIndexPath)
    {
        let text = textForCellAtIndexPath(indexPath)
        
        if text != "-"
        {
            switch self.pickerType
            {
            case .Country:
                if let countries = startItems as? [Country]
                {
                    for aCountry in countries
                    {
                        if aCountry.countryName == text
                        {
                            userDidSelectCountry(aCountry)
                            break
                        }
                    }
                }
            case .Language:
                if let languages = startItems as? [Language]
                {
                    for aLang in languages
                    {
                        if aLang.languageName == text
                        {
                            userDidSelectLanguage(aLang)
                            break
                        }
                    }
                }
            }
        }
    }
    //MARK: ---
    func userDidSelectCountry(country:Country)
    {
        self.delegate?.itemPicker(self, didPickItem: country)
    }
    
    func userDidSelectLanguage(language:Language)
    {
        self.delegate?.itemPicker(self, didPickItem: language)
    }
    
    
    
    
}
