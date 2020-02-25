//
//  Methods.swift
//  TangemSdkExampleDevelopmentUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import XCTest

public class Methods {
    func scanCard() {
        expectationAndTapAction(identifier: "ScanCardButton", timeout: 10)
        RobotApi().select(card: .red)
        
        sleep(10)
        
        let textView = findTextView(identifier: "logView", timeout: 10)
        guard let textViewValue = textView.value as? String else {
            XCTAssertFalse(true, "в TextView не найден текст")
            return
        }
        
        //Вырезаем лишнее из json
        let correctedString = textViewValue.replacingOccurrences(of: "read result: ", with: "", options: NSString.CompareOptions.literal, range: nil)
        let secondCorrect = correctedString.replacingOccurrences(of: "\n\nverify result: true\n\n", with: "", options: NSString.CompareOptions.literal, range: nil)
        
        let getDictionary = convertToDictionary(text: secondCorrect)
        
        guard let plist = getPlist(withName: "CardsData") else {
            XCTAssertFalse(true, "plist с тестовыми данными не найден")
            return
        }
        if  let cardanaData = plist["Cardana"] as? NSDictionary {
            let cardanaKeys = cardanaData.allKeys
            print(cardanaKeys)
            cardanaKeys.forEach {
                if let key = $0 as? String {
                    if let getText = getDictionary[key] as? String,
                        let savedText = cardanaData[key] as? String {
                        XCTAssertTrue(getText.compare(savedText) == .orderedSame, "Не совпало: " + getText + " != " + savedText + " По ключу: " + key)
                    }
                }
            }
        }
    }
    
    func getPlist(withName name: String) -> NSDictionary?
    {
        let testBundle = Bundle(for: TangemSdkExampleDevelopmentUITests.self)
        if let url = testBundle.url(forResource: name, withExtension: "plist"),
            let dictionary = NSDictionary(contentsOf: url) {
            return dictionary
        }
        return nil
    }
    
    func convertToDictionary(text: String) -> [String: Any] {
        if let data = text.data(using: .utf8) {
            do {
                return try (JSONSerialization.jsonObject(with: data, options: []) as? [String: Any])!
            } catch {
                print(error.localizedDescription)
            }
        }
        return ["no data" : "no data"]
    }
    
    func expectationAndTapAction(identifier: String, timeout: TimeInterval) {
        print("", identifier, "Tap")
        expectation(for: NSPredicate(format: "exists == 1"), evaluatedWith: XCUIApplication().buttons[identifier])
        waitForExpectations(timeout: timeout, handler: nil)
        XCUIApplication().buttons[identifier].tap()
    }
    
    func findTextView(identifier: String, timeout: TimeInterval) -> XCUIElement {
        print("", identifier, "searching...")
        expectation(for: NSPredicate(format: "exists == 1"), evaluatedWith: XCUIApplication().textViews[identifier])
        waitForExpectations(timeout: timeout, handler: nil)
        return XCUIApplication().textViews[identifier]
    }
}
