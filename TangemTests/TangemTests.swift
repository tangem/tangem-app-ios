//
//  TangemTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 dns user. All rights reserved.
//

import XCTest
@testable import Tangem

class TangemTests: XCTestCase {
    
    func testCardImage() {
        
        var card = Card()
        card.batchId = 0x0008
        
        card.cardID = "AE01 0000 0000 0000"
        XCTAssertEqual(card.imageName, "card-btc001")
        
        card.cardID = "AE01 0000 0000 5000"
        XCTAssertEqual(card.imageName, "card-btc005")
    }
    
}
