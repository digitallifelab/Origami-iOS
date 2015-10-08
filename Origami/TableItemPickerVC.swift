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
//        switch self.pickerType
//        {
//        case .Country:
//            currentItems = createIndexedDataSourceForCountries(startItems as? [Country])
//        case .Language:
//            currentItems = createIndexedDataSourceForLanguages(startItems as? [Language])
//        }
//        
//        //self.navigationController?.navigationBar.tintColor = kDayNavigationBarBackgroundColor
//        
//        tableView.delegate = self
//        tableView.dataSource = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        switch self.pickerType
        {
        case .Country:
            currentItems = createIndexedDataSourceForCountries(startItems as? [Country])
        case .Language:
            currentItems = createIndexedDataSourceForLanguages(startItems as? [Language])
        }
        
        //self.navigationController?.navigationBar.tintColor = kDayNavigationBarBackgroundColor
        
        tableView.delegate = self
        tableView.dataSource = self
        let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 0.2))
        dispatch_after(timeout, dispatch_get_main_queue(), { () -> Void in
            self.tableView.reloadData()
        })
        
    }

    

    func createIndexedDataSourceForCountries(countries:[Country]?) -> [[String:[String]]]?
    {
        if let array = countries
        {
            var countrieNamesFirstLettersSet = Set<String>()
            for aCountry in array
            {
                if aCountry.countryName.characters.count > 1
                {
                    let endIndex = aCountry.countryName.startIndex.advancedBy(1)//advance(aCountry.countryName.startIndex, 1)
                    let firstLetterSubstring = aCountry.countryName.substringToIndex(endIndex)
                    if !countrieNamesFirstLettersSet.contains(firstLetterSubstring)
                    {
                        countrieNamesFirstLettersSet.insert(firstLetterSubstring)
                    }
                }
            }
            
            var firstLettersArray = Array(countrieNamesFirstLettersSet)
            
            firstLettersArray.sortInPlace( < )
            
            var countryNamesByLetter = [[String]]()
            
            for aLetter:String in firstLettersArray
            {
                
                let sortedCountries = array.filter { (country) in
                    
                    let endIndex = country.countryName.startIndex.advancedBy(1)//advance(country.countryName.startIndex, 1)
                    let firstLetterSubstring = country.countryName.substringToIndex(endIndex)
                    
                    return (firstLetterSubstring == aLetter)
                }
                var countryNames = [String]()
                for aCountry in sortedCountries
                {
                    countryNames.append(aCountry.countryName)
                }
                countryNamesByLetter.append(countryNames)
                //print(aLetter)
                //print(countryNames)
            }
            
            //print("\(firstLettersArray)")
            
            if countryNamesByLetter.count == firstLettersArray.count
            {
                var toReturnCurrentItems = [[String:[String]]]()
                for var i = 0 ; i < countryNamesByLetter.count; i++
                {
                    var arrayItem = [String : [String]]()
                    let letterKey = firstLettersArray[i]
                    let countryNamesValue = countryNamesByLetter[i]
                    arrayItem[letterKey] = countryNamesValue
                    toReturnCurrentItems.append(arrayItem)
                }
                
                return toReturnCurrentItems
            }
        }
        return nil
    }
    
    func createIndexedDataSourceForLanguages(languages:[Language]?) -> [[String:[String]]]?
    {
        if let array = languages
        {
            var languageNamesFirstLettersSet = Set<String>()
            for aLanguage in array
            {
                if aLanguage.languageName.characters.count > 1
                {
                    let endIndex = aLanguage.languageName.startIndex.advancedBy(1) //advance(aLanguage.languageName.startIndex, 1)
                    let firstLetterSubstring = aLanguage.languageName.substringToIndex(endIndex)
                    if !languageNamesFirstLettersSet.contains(firstLetterSubstring)
                    {
                        languageNamesFirstLettersSet.insert(firstLetterSubstring)
                    }
                }
            }
            
            var firstLettersArray = Array(languageNamesFirstLettersSet)
            
            firstLettersArray.sortInPlace( < )
            
            var languageNamesByLetter = [[String]]()
            
            for aLetter:String in firstLettersArray
            {
                
                let sortedLanguages = array.filter { (language) in
                    
                    let endIndex = language.languageName.startIndex.advancedBy(1) // advance(language.languageName.startIndex, 1)
                    let firstLetterSubstring = language.languageName.substringToIndex(endIndex)
                    
                    return (firstLetterSubstring == aLetter)
                }
                var languageNames = [String]()
                for aLanguage in sortedLanguages
                {
                    languageNames.append(aLanguage.languageName)
                }
                
                languageNamesByLetter.append(languageNames)
                //print(aLetter)
                //print(languageNames)
            }
            
            //print("\(firstLettersArray)")
            
            if languageNamesByLetter.count == firstLettersArray.count
            {
                var toReturnCurrentItems = [[String:[String]]]()
                for var i = 0 ; i < languageNamesByLetter.count; i++
                {
                    var arrayItem = [String : [String]]()
                    let letterKey = firstLettersArray[i]
                    let languageNamesValue = languageNamesByLetter[i]
                    arrayItem[letterKey] = languageNamesValue
                    toReturnCurrentItems.append(arrayItem)
                }
                
                return toReturnCurrentItems
            }
        }
        
        return nil
    }
    
    //MARK: UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let items = currentItems
        {
            //print("number of sections: \(items.count)")
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
            
            let key = item.keys.first
            //print("key for section \(section) = \(key)")
            return key
        }
        return nil
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if let title = titleForSection(section)
        {
            let anIndex = title.startIndex.advancedBy(1) //advance(title.startIndex, 1)
            return title.substringToIndex(anIndex)
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
        
        let cell = tableView.dequeueReusableCellWithIdentifier("SelectionSell", forIndexPath: indexPath)// as! UITableViewCell
        
        cell.textLabel?.text = textForCellAtIndexPath(indexPath)
        cell.selectionStyle = UITableViewCellSelectionStyle.Gray
        
        return cell
    }
    
    
    
    //MARK: UITableVIewDelegate
    func tableView(tableView:UITableView, didSelectRowAtIndexPath indexPath:NSIndexPath)
    {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        
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
