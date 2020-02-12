//
//  TangemSdkExampleDevelopmentUITests.swift
//  TangemSdkExampleDevelopmentUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import XCTest


class TangemSdkExampleDevelopmentUITests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
        
        let app = XCUIApplication()
        app.launch()
        RobotApi().select(card: .none)

    }

    override func tearDown() {
        RobotApi().select(card: .none)
        let app = XCUIApplication()
        app.terminate()
    }
    
    func testExample() {
        expectationAndTapAction(identifier: "ScanCardButton", timeout: 10)
        RobotApi().select(card: .red)
        
        sleep(5)
        
//        let readedCardID = findTextView(identifier: "logView", timeout: 10)
//        let logViewText = readedCardID.value
        
        let logViewText : NSDictionary? = ["CardID" : "test",
            "Status" : "02"
        ]
        
        if let plist = getPlist(withName: "CardsData") {
            if  let cardanaData = plist["Cardana"] as? NSDictionary {
                let cardanaKeys = cardanaData.allKeys
                print(cardanaKeys)
                cardanaKeys.forEach {
                    if let getText = logViewText?[$0] as? String,
                        let savedText = cardanaData[$0] as? String {
                        
                        XCTAssertTrue(getText.compare(savedText) == .orderedSame, "Не совпало" + getText + " != " + savedText)
                    } else {
                        let getText = logViewText?[$0]
                        let savedText = cardanaData[$0]
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
