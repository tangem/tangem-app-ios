//
//  CollectiblesEntranceDestinationTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import Tangem

@Suite("CollectiblesEntranceViewModel.Destination")
struct CollectiblesEntranceDestinationTests {
    typealias SUT = CollectiblesEntranceViewModel.Destination

    @Test("Takes an account holder to the main screen whatever the region says", arguments: [true, false])
    func accountHolderGoesToMain(isRestricted: Bool) {
        #expect(SUT(hasAccount: true, isRestricted: isRestricted) == .main)
    }

    @Test("Takes a newcomer to the welcome screen while the region allows it")
    func newcomerGoesToWelcome() {
        #expect(SUT(hasAccount: false, isRestricted: false) == .welcome)
    }

    @Test("Stops a newcomer from a restricted region with the sheet")
    func restrictedNewcomerSeesSheet() {
        #expect(SUT(hasAccount: false, isRestricted: true) == .regionRestrictions)
    }
}
