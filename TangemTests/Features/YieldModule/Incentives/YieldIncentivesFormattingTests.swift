//
//  YieldIncentivesFormattingTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import BlockchainSdk
import Testing
@testable import Tangem

@Suite("Yield incentives formatting")
struct YieldIncentivesFormattingTests {
    private typealias Fixtures = YieldIncentivesFixtures

    @Test("An eighteen decimal reward is cut to the shared crypto precision")
    func eighteenDecimalRewardIsCutToSharedPrecision() throws {
        let text = try #require(
            YieldIncentiveAmountFormatter().format(
                baseUnits: BigUInt(stringLiteral: "48669134843565400"),
                decimals: 18,
                symbol: "WMON"
            )
        )

        #expect(fractionDigits(of: text) == "04866913")
    }

    @Test("The cut rounds down, so the shown amount is never more than the claim")
    func theCutRoundsDown() throws {
        let text = try #require(
            YieldIncentiveAmountFormatter().format(
                baseUnits: BigUInt(stringLiteral: "49999999999999999"),
                decimals: 18,
                symbol: "WMON"
            )
        )

        #expect(fractionDigits(of: text) == "04999999")
    }

    @Test("A token with fewer decimals than the cap keeps its own precision")
    func smallerPrecisionTokenKeepsItsOwn() throws {
        let text = try #require(
            YieldIncentiveAmountFormatter().format(baseUnits: BigUInt(125), decimals: 3, symbol: "USDC")
        )

        #expect(fractionDigits(of: text) == "125")
    }

    @Test("Rewards are grouped by the destination the backend chose")
    func rewardsAreGroupedByDestination() {
        let viewData = makeMapper().map(
            summary: Fixtures.summary(
                rewards: [
                    Fixtures.reward(rewardTokenAddress: "0x01", destination: .module),
                    Fixtures.reward(rewardTokenAddress: "0x02", destination: .owner),
                    Fixtures.reward(rewardTokenAddress: "0x03", destination: .aave),
                    Fixtures.reward(rewardTokenAddress: "0x04", destination: .unsupported),
                ]
            )
        )

        #expect(viewData.sections.map(\.id) == ["owner", "aave", "module", "unsupported"])
        #expect(viewData.sections.flatMap { $0.rewards.map(\.id) } == ["0x02", "0x03", "0x01", "0x04"])
    }

    @Test("The total sums the net value of the supported rewards only")
    func theTotalSumsSupportedRewardsOnly() {
        let viewData = makeMapper().map(
            summary: Fixtures.summary(
                rewards: [
                    Fixtures.reward(rewardTokenAddress: "0x01", estimatedNetValueUsd: Decimal(string: "1.5")!),
                    Fixtures.reward(rewardTokenAddress: "0x02", estimatedNetValueUsd: Decimal(string: "2.25")!),
                    Fixtures.reward(
                        rewardTokenAddress: "0x03",
                        estimatedNetValueUsd: Decimal(string: "9.99")!,
                        destination: .unsupported
                    ),
                ]
            )
        )

        let expected = BalanceFormatter().formatFiatBalance(
            Decimal(string: "3.75")!,
            currencyCode: AppConstants.usdCurrencyCode
        )

        #expect(viewData.total == expected)
    }

    @Test("A reward that is only pending is left out of the claim sheet")
    func pendingRewardIsLeftOut() {
        let viewData = makeMapper().map(summary: Fixtures.summary(rewards: [Fixtures.reward(claimableAmount: 0)]))

        #expect(viewData.sections.isEmpty)
    }

    @Test("The service fee rate is stated only when the whole claim shares one")
    func serviceFeeRateIsStatedOnlyWhenShared() {
        let mapper = makeMapper()
        let amountUsd = Decimal(string: "0.25")!

        let shared = mapper.mapServiceFee(
            amountUsd: amountUsd,
            summary: Fixtures.summary(
                rewards: [
                    Fixtures.reward(rewardTokenAddress: "0x01", serviceFeeRateBps: 1500),
                    Fixtures.reward(rewardTokenAddress: "0x02", serviceFeeRateBps: 1500),
                ]
            )
        )

        let mixed = mapper.mapServiceFee(
            amountUsd: amountUsd,
            summary: Fixtures.summary(
                rewards: [
                    Fixtures.reward(rewardTokenAddress: "0x01", serviceFeeRateBps: 1500),
                    Fixtures.reward(rewardTokenAddress: "0x02", serviceFeeRateBps: 1000),
                ]
            )
        )

        let rateOnly = shared.replacingOccurrences(of: mixed, with: "")

        #expect(shared != mixed)
        #expect(shared.contains(mixed))
        #expect(digits(of: rateOnly) == "15")
    }

    @Test("The shown amount is the claim minus the service fee, floored in base units")
    func shownAmountIsTheClaimMinusTheServiceFee() {
        let viewData = makeMapper().map(
            summary: Fixtures.summary(
                rewards: [Fixtures.reward(decimals: 3, claimableAmount: BigUInt(1000), serviceFeeRateBps: 1500)]
            )
        )

        let reward = viewData.sections.first?.rewards.first
        let expected = YieldIncentiveAmountFormatter().format(baseUnits: BigUInt(850), decimals: 3, symbol: "WMON")

        #expect(reward?.amount == expected)
    }

    @Test("An unsupported reward is shown gross, since no claim will net it")
    func unsupportedRewardIsShownGross() {
        let viewData = makeMapper().map(
            summary: Fixtures.summary(
                rewards: [
                    Fixtures.reward(
                        decimals: 3,
                        claimableAmount: BigUInt(1000),
                        serviceFeeRateBps: 1500,
                        destination: .unsupported
                    ),
                ]
            )
        )

        let reward = viewData.sections.first?.rewards.first
        let expected = YieldIncentiveAmountFormatter().format(baseUnits: BigUInt(1000), decimals: 3, symbol: "WMON")

        #expect(reward?.amount == expected)
        #expect(reward?.fiatAmount == nil)
    }

    private func makeMapper() -> YieldModuleClaimViewDataMapper {
        YieldModuleClaimViewDataMapper(blockchain: .monad(testnet: false), storage: nil)
    }

    private func digits(of text: String) -> String {
        asciiDigits(of: text)
    }

    private func fractionDigits(of text: String) -> String {
        let separator = Locale.current.decimalSeparator ?? "."

        guard let range = text.range(of: separator) else {
            return ""
        }

        return asciiDigits(of: String(text[range.upperBound...].prefix { $0.isNumber }))
    }

    private func asciiDigits(of text: String) -> String {
        text.compactMap(\.wholeNumberValue).map(String.init).joined()
    }
}
