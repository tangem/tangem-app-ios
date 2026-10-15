//
//  PolymarketOrderAmountEntryTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
import TangemFoundation
import TangemPolymarket
@testable import Tangem

@MainActor
@Suite("Polymarket order amount entry")
struct PolymarketOrderAmountEntryTests {
    @Test("A bet is typed down to the cent, however much the collateral could carry")
    func typedAmountStopsAtCents() async throws {
        let model = try await makeModel()

        type("1.2345", into: model.amountField)

        try await settle { model.state.enteredAmount != nil }

        #expect(model.amountField.value == Decimal(string: "1.23")!)
        #expect(model.state.enteredAmount == Decimal(string: "1.23")!)
    }

    @Test("The smallest bet the field can spell is the smallest one worth quoting")
    func theSmallestTypedAmountIsQuotable() async throws {
        let model = try await makeModel()

        type("0.019", into: model.amountField)

        try await settle { model.state.enteredAmount != nil }

        #expect(model.amountField.value == Decimal(string: "0.01")!)
        #expect(model.state.enteredAmount == Decimal(string: "0.01")!)
    }

    @Test("A bet stops at the cent, a position keeps the precision its shares are held in")
    func onlyTheBuyAmountIsCappedAtCents() {
        #expect(PolymarketOrderIntent.buy(balance: .just(output: nil)).fractionDigits == 2)
        #expect(PolymarketOrderIntent.sell(shares: 1).fractionDigits == PolymarketCollateral.decimalCount)
    }
}

// MARK: - Fixtures

private extension PolymarketOrderAmountEntryTests {
    func makeModel() async throws -> PolymarketOrderModel {
        let model = PolymarketOrderModel(
            market: .fixture,
            outcome: .fixture,
            eventTitle: "Fixture event",
            intent: .buy(balance: .just(output: 200)),
            apiProvider: PolymarketAPIProviderStub(),
            geoblockStateProvider: PolymarketGeoblockStateProviderStub(),
            positionsService: nil,
            clobService: PolymarketCLOBServiceStub(),
            isAwaitingFundsPublisher: .just(output: false),
            collateralBalancePublisher: .just(output: 200),
            addFundsReadinessStream: AsyncStream { $0.yield(.unavailable); $0.finish() }
        )

        try await settle { model.state.balance != nil }

        return model
    }

    func type(_ text: String, into field: DecimalNumberTextFieldViewModel) {
        let separator = Locale.current.decimalSeparator ?? "."

        field.textFieldTextBinding.value = text.replacingOccurrences(of: ".", with: separator)
        field.sanitize()
    }
}
