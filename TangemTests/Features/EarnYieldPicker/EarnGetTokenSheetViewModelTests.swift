//
//  EarnGetTokenSheetViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("Earn Get token sheet")
struct EarnGetTokenSheetViewModelTests {
    @Test("Rows follow the design order Deposit, Swap, Buy, whatever order the token page gives")
    func designOrder() {
        let sheet = makeSUT(options: [.init(type: .buy, isAvailable: true), .init(type: .exchange, isAvailable: true), .init(type: .receive, isAvailable: true)])

        #expect(sheet.items.map(\.id) == [.receive, .exchange, .buy])
        #expect(sheet.items.map(\.title) == ["Deposit ETH", "Swap to ETH", "Buy ETH"])
        #expect(sheet.title == "Get ETH")
    }

    @Test("A row the wallet can't use stays visible but disabled, and a missing option is left out")
    func availability() {
        let sheet = makeSUT(options: [.init(type: .receive, isAvailable: true), .init(type: .buy, isAvailable: false)])

        #expect(sheet.items.map(\.id) == [.receive, .buy])
        #expect(sheet.items.map(\.isAvailable) == [true, false])
    }

    @Test("Tapping a row reports its action")
    func tapReportsAction() throws {
        var selected: [TokenActionType] = []
        let sheet = makeSUT(options: [.init(type: .exchange, isAvailable: true)], onSelect: { selected.append($0) })

        try #require(sheet.items.first).action()

        #expect(selected == [.exchange])
    }
}

// MARK: - Helpers

private extension EarnGetTokenSheetViewModelTests {
    func makeSUT(
        options: [TokenDetailsActionsViewModel.AddFundsOption],
        onSelect: @escaping (TokenActionType) -> Void = { _ in }
    ) -> EarnGetTokenSheetViewModel {
        EarnGetTokenSheetViewModel.make(tokenSymbol: "ETH", options: options, onSelect: onSelect)
    }
}
