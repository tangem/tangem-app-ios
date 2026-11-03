//
//  EarnYieldPickerViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemTestKit
@testable import Tangem

@Suite("EarnYieldPickerViewModel")
@MainActor
final class EarnYieldPickerViewModelTests: LeakTrackingTestSuite {
    @Test("Opens on the given product with the calculator projected at its rate")
    func opensOnGivenProduct() throws {
        let (sut, _) = try makeSUT(selectedProductID: .pooledStaking)

        #expect(sut.selectedProduct == Self.staking)
        #expect(sut.calculator.state == makeCalculatorState(for: Self.staking, input: .default))
    }

    @Test("Opens on the first product when the given one is not in the list")
    func opensOnFirstProductWhenGivenIsMissing() throws {
        let (sut, _) = try makeSUT(products: [Self.staking], selectedProductID: .lendingOnAave)

        #expect(sut.selectedProduct == Self.staking)
    }

    @Test("Is not created without products")
    func notCreatedWithoutProducts() {
        let sut = EarnYieldPickerViewModel(
            products: [],
            selectedProductID: .lendingOnAave,
            balanceProvider: MutableTokenBalanceProviderMock(balance: 1),
            currencyCode: Self.currencyCode,
            coordinator: nil
        )

        #expect(sut == nil)
    }

    @Test("Choosing another product projects the entered amounts at that product's rate")
    func selectKeepsInput() throws {
        let (sut, _) = try makeSUT(selectedProductID: .lendingOnAave)
        sut.calculator.increase(.initialBalance)
        var input = EarnCalculatorInput.default
        input.initialBalance += EarnCalculatorField.initialBalance.step

        sut.select(Self.staking)

        #expect(sut.selectedProduct == Self.staking)
        #expect(sut.calculator.state == makeCalculatorState(for: Self.staking, input: input))
    }

    @Test(
        "The primary action starts earning on the selected product when there are funds, otherwise adds funds",
        arguments: [true, false]
    )
    func primaryAction(hasFunds: Bool) throws {
        let (sut, coordinator) = try makeSUT(selectedProductID: .lendingOnAave, balance: MutableTokenBalanceProviderMock(balance: hasFunds ? 1 : 0))
        sut.select(Self.staking)

        sut.onPrimaryActionTap()

        #expect(coordinator.events == (hasFunds ? [.startEarning(.pooledStaking)] : [.addFunds]))
    }

    @Test("Adding funds while the screen is open turns the primary action into starting to earn")
    func primaryActionFollowsBalance() async throws {
        let balance = MutableTokenBalanceProviderMock(balance: 0)
        let (sut, _) = try makeSUT(balance: balance)

        balance.balanceType = .loaded(1)

        #expect(await waitUntilMainActorConditionMet { sut.primaryAction == .startEarning })
    }

    @Test("The incentive info opens for the selected product")
    func incentiveInfo() throws {
        let (sut, coordinator) = try makeSUT(selectedProductID: .lendingOnAave)

        sut.onIncentiveInfoTap()

        #expect(coordinator.events == [.incentiveInfo(.lendingOnAave)])
    }

    @Test("The incentive badge shows the selected product's incentive and hides without one")
    func incentiveBadge() throws {
        let (sut, _) = try makeSUT(selectedProductID: .lendingOnAave)

        #expect(sut.incentiveBadgeText == "Incentivised 1.4%")

        sut.select(Self.staking)

        #expect(sut.incentiveBadgeText == nil)
    }

    @Test("A product without benefits has no Benefits tab")
    func sectionsWithoutBenefits() throws {
        let withoutBenefits = Self.makeProduct(id: .pooledStaking, apy: Decimal(string: "0.02")!, benefits: [])
        let (sut, _) = try makeSUT(products: [withoutBenefits, Self.lending], selectedProductID: .pooledStaking)

        #expect(sut.sections == [.calculator, .details])

        sut.select(Self.lending)

        #expect(sut.sections == [.calculator, .benefits, .details])
    }

    @Test(
        "A chip shows the rate as a percent with up to two decimals",
        arguments: [
            (Decimal(string: "0.03")!, "3% APY"),
            (Decimal(string: "0.0387")!, "3.87% APY"),
        ]
    )
    func rate(apy: Decimal, expected: String) throws {
        let (sut, _) = try makeSUT()

        #expect(sut.rate(of: Self.makeProduct(id: .pooledStaking, apy: apy)) == expected)
    }
}

// MARK: - Helpers

private extension EarnYieldPickerViewModelTests {
    static let currencyCode = "USD"
    static let staking = makeProduct(
        id: .pooledStaking,
        apy: Decimal(string: "0.02")!,
        incentiveApy: nil,
        performanceFee: Decimal(string: "0.08")!
    )
    static let lending = makeProduct(id: .lendingOnAave, apy: Decimal(string: "0.03")!, incentiveApy: Decimal(string: "0.014")!)

    static func makeProduct(
        id: EarnYieldPickerProduct.ID,
        apy: Decimal,
        incentiveApy: Decimal? = nil,
        performanceFee: Decimal = Decimal(string: "0.15")!,
        benefits: [EarnProductDetails.Benefit]? = nil
    ) -> EarnYieldPickerProduct {
        let details = EarnProductDetails.preview

        return EarnYieldPickerProduct(
            id: id,
            name: "\(id)",
            apy: apy,
            incentiveApy: incentiveApy,
            performanceFee: performanceFee,
            description: "Description",
            details: EarnProductDetails(
                benefits: benefits ?? details.benefits,
                risk: details.risk,
                provider: details.provider,
                withdrawals: details.withdrawals,
                managementFee: details.managementFee,
                performanceFee: details.performanceFee,
                auditReport: details.auditReport
            )
        )
    }

    func makeSUT(
        products: [EarnYieldPickerProduct]? = nil,
        selectedProductID: EarnYieldPickerProduct.ID = .lendingOnAave,
        balance: TokenBalanceProvider = MutableTokenBalanceProviderMock(balance: 1)
    ) throws -> (EarnYieldPickerViewModel, EarnYieldPickerRoutableSpy) {
        let coordinator = trackForMemoryLeaks(EarnYieldPickerRoutableSpy())
        let sut = try #require(EarnYieldPickerViewModel(
            products: products ?? [Self.staking, Self.lending],
            selectedProductID: selectedProductID,
            balanceProvider: balance,
            currencyCode: Self.currencyCode,
            percentFormatter: PercentFormatter(locale: Locale(identifier: "en_US")),
            coordinator: coordinator
        ))
        return (trackForMemoryLeaks(sut), coordinator)
    }

    func makeCalculatorState(for product: EarnYieldPickerProduct, input: EarnCalculatorInput) -> EarnCalculatorViewState {
        EarnCalculatorViewModel(
            input: input,
            incentiveApy: product.incentiveApy,
            projector: CompoundingEarnCalculatorProjector(apy: product.apy, performanceFee: product.performanceFee),
            currencyCode: Self.currencyCode
        ).state
    }
}

// MARK: - Stubs

private final class EarnYieldPickerRoutableSpy: EarnYieldPickerRoutable {
    enum Event: Equatable {
        case startEarning(EarnYieldPickerProduct.ID)
        case addFunds
        case incentiveInfo(EarnYieldPickerProduct.ID)
        case url(URL)
        case dismiss
    }

    private(set) var events: [Event] = []

    func openStartEarning(for product: EarnYieldPickerProduct) {
        events.append(.startEarning(product.id))
    }

    func openAddFunds() {
        events.append(.addFunds)
    }

    func openIncentiveInfo(for product: EarnYieldPickerProduct) {
        events.append(.incentiveInfo(product.id))
    }

    func openURL(_ url: URL) {
        events.append(.url(url))
    }

    func dismissYieldPicker() {
        events.append(.dismiss)
    }
}
