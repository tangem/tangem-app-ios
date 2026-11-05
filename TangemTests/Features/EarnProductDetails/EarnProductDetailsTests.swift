//
//  EarnProductDetailsTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("EarnProductDetails")
struct EarnProductDetailsTests {
    private static let percentFormatter = PercentFormatter(locale: Locale(identifier: "en_US"))

    @Test(
        "The performance fee row shows the fee as a share of the yield",
        arguments: [
            (Decimal(string: "0.15")!, "15% of yield"),
            (Decimal(string: "0.125")!, "12.5% of yield"),
        ]
    )
    func performanceFee(fee: Decimal, expected: String) {
        #expect(makeLendingDetails(performanceFee: fee).performanceFee.value == expected)
    }

    @Test("The performance fee sheet states the fee as a share of the yield")
    func performanceFeeInfo() {
        let info = makeLendingDetails(performanceFee: Decimal(string: "0.125")!).performanceFee.info

        #expect(info.title == "Performance fee")
        #expect(info.content == .text("12.5% of the yield you earn. It is not charged on the amount you deposit."))
    }

    @Test("The risk sheet explains the low, medium and high levels")
    func riskInfo() {
        let info = makeLendingDetails().risk.info
        guard case .levels(let levels) = info.content else {
            Issue.record("Expected risk levels, got \(info.content)")
            return
        }

        #expect(info.title == "Risk information")
        #expect(levels.map(\.title) == ["Low risk", "Medium risk", "High risk"])
    }

    @Test("Lending on Aave links the protocol row to Aave")
    func protocolLink() {
        #expect(makeLendingDetails().provider == .init(title: "Protocol", name: "Aave", url: URL(string: "https://aave.com")!))
    }

    @Test("Lending on Aave links the audits row to the given audit report")
    func auditReport() {
        #expect(makeLendingDetails().auditReport == .init(title: "Audits", name: "Reports", url: Self.auditReportURL))
    }

    @Test("Pooled staking links the validator row to P2P")
    func validatorLink() {
        #expect(makeStakingDetails().provider == .init(title: "Validator", name: "P2P", url: URL(string: "https://p2p.org")!))
    }

    @Test("Pooled staking has no audits row")
    func stakingHasNoAuditReport() {
        #expect(makeStakingDetails().auditReport == nil)
    }

    @Test("Pooled staking states its performance fee as a share of the yield")
    func stakingPerformanceFee() {
        let performanceFee = makeStakingDetails(performanceFee: Decimal(string: "0.08")!).performanceFee

        #expect(performanceFee.value == "8% of yield")
        #expect(performanceFee.info.content == .text("8% of the yield you earn. It is not charged on the amount you deposit."))
    }

    @Test(
        "The risk row shows its level and opens the shared risk sheet",
        arguments: [
            (EarnProductDetails.RiskLevel.low, "Low"),
            (.medium, "Medium"),
            (.high, "High"),
        ]
    )
    func riskLevel(level: EarnProductDetails.RiskLevel, expected: String) {
        let risk = EarnProductDetails.Detail.risk(level)

        #expect(risk.value == expected)
        #expect(risk.info == makeLendingDetails().risk.info)
    }

    @Test("Lending on Aave and Pooled staking have no management fee row")
    func noManagementFee() {
        #expect(makeLendingDetails().managementFee == nil)
        #expect(makeStakingDetails().managementFee == nil)
    }

    @Test("Pooled staking opens the same risk sheet as Lending on Aave")
    func stakingRiskInfo() {
        #expect(makeStakingDetails().risk == makeLendingDetails().risk)
    }

    @Test("Lending on Aave lists no lock-ups before withdrawing anytime")
    func benefits() {
        #expect(makeLendingDetails().benefits.map(\.title) == ["No lock-ups.", "Withdraw anytime."])
    }
}

// MARK: - Fixtures

private extension EarnProductDetailsTests {
    static let auditReportURL = URL(string: "https://example.com/audit-report.pdf")!

    func makeLendingDetails(performanceFee: Decimal = Decimal(string: "0.15")!) -> EarnProductDetails {
        EarnProductDetails.lendingOnAave(
            performanceFee: performanceFee,
            auditReportURL: Self.auditReportURL,
            percentFormatter: Self.percentFormatter
        )
    }

    func makeStakingDetails(performanceFee: Decimal = Decimal(string: "0.08")!) -> EarnProductDetails {
        EarnProductDetails.pooledStaking(performanceFee: performanceFee, percentFormatter: Self.percentFormatter)
    }
}
