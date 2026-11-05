//
//  TangemPaySummaryEnrollmentResolverTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemPay

@Suite("Enrollment decision from the customer summary")
struct TangemPaySummaryEnrollmentResolverTests {
    typealias Status = TangemPayCustomerSummaryResponse.Activation.Status

    @Test("A customer approved by KYC with nothing opened is verified and continues to the result screen")
    func approvedWithNothingOpenedIsVerified() {
        let summary = makeSummary(payment: activation(.notStarted), banking: activation(.notStarted))

        #expect(resolve(summary) == .verified)
    }

    @Test(
        "Any mix of not-started and unavailable products keeps the customer on the result screen",
        arguments: ["NOT_STARTED", "UNAVAILABLE"],
        ["NOT_STARTED", "UNAVAILABLE"]
    )
    func notStartedOrUnavailableIsVerified(payment: String, banking: String) throws {
        let summary = makeSummary(
            payment: activation(try #require(Status(rawValue: payment))),
            banking: activation(try #require(Status(rawValue: banking)))
        )

        #expect(resolve(summary) == .verified)
    }

    @Test(
        "An account that is opening, open, failed or closed while the card never started hides the card row",
        arguments: ["PROCESSING", "COMPLETED", "FAILED", "DEACTIVATED"]
    )
    func accountOnlyCustomerHidesCardRow(banking: String) throws {
        let summary = makeSummary(payment: activation(.notStarted), banking: activation(try #require(Status(rawValue: banking))))

        #expect(resolve(summary) == .cardNotOpened)
    }

    @Test("A card that is opening or open is enrolled whatever the account does")
    func cardOpeningOrOpenIsEnrolled() {
        #expect(resolve(makeSummary(payment: activation(.processing, step: .issuing), banking: activation(.processing))) == .enrolled)
        #expect(resolve(makeSummary(payment: activation(.completed), banking: activation(.notStarted), cards: oneActiveCard)) == .enrolled)
    }

    @Test(
        "A card that failed before anything opened is reported as failed to issue",
        arguments: [("ISSUING", "TECHNICAL"), ("AWAITING_DEPOSIT", "DEPOSIT_TIMEOUT")]
    )
    func cardFailureAtFirstOpeningIsFailedToIssue(step: String, failureReason: String) {
        let summary = makeSummary(
            payment: activation(
                .failed,
                step: .init(rawValue: step),
                failureReason: .init(rawValue: failureReason)
            ),
            banking: activation(.notStarted)
        )

        #expect(resolve(summary) == .failedToIssueCard)
    }

    @Test("A technical card failure next to an opening account is reported as failed to issue")
    func technicalCardFailureNextToAccountIsFailedToIssue() {
        let summary = makeSummary(
            payment: activation(.failed, step: .issuing, failureReason: .technical),
            banking: activation(.processing, step: .issuing)
        )

        #expect(resolve(summary) == .failedToIssueCard)
    }

    @Test("A refusal by the issuer with nothing else open declines all of Tangem Pay")
    func issuerRefusalWithNothingOpenIsDeclined() {
        let cardRefused = makeSummary(
            payment: activation(.failed, step: .issuing, failureReason: .rainRejected),
            banking: activation(.notStarted)
        )
        let accountRefused = makeSummary(
            payment: activation(.notStarted),
            banking: activation(.failed, step: .issuing, failureReason: .rainRejected)
        )

        #expect(resolve(cardRefused) == .kycDeclined)
        #expect(resolve(accountRefused) == .kycDeclined)
    }

    @Test("A refusal by the issuer for one product keeps the other product's own state")
    func issuerRefusalWithOtherProductOpenKeepsState() {
        let cardRefusedAccountOpen = makeSummary(
            payment: activation(.failed, step: .issuing, failureReason: .rainRejected),
            banking: activation(.completed)
        )
        let accountRefusedCardOpen = makeSummary(
            payment: activation(.completed),
            banking: activation(.failed, step: .issuing, failureReason: .rainRejected),
            cards: oneActiveCard
        )

        #expect(resolve(cardRefusedAccountOpen) == .failedToIssueCard)
        #expect(resolve(accountRefusedCardOpen) == .enrolled)
    }

    @Test("KYC and customer status are checked before any product", arguments: [
        ("NEW", "REQUIRED", TangemPayEnrollmentState.kycRequired),
        ("NEW", "IN_PROGRESS", .kycInProgress),
        ("NEW", "DECLINED", .kycDeclined),
        ("FORMER", "APPROVED", .cardDeactivated),
    ])
    func kycAndCustomerStatusComeFirst(customerStatus: String, kycStatus: String, expected: TangemPayEnrollmentState) throws {
        let summary = makeSummary(
            customerStatus: try #require(.init(rawValue: customerStatus)),
            kycStatus: try #require(.init(rawValue: kycStatus)),
            payment: activation(.notStarted),
            banking: activation(.notStarted)
        )

        #expect(resolve(summary) == expected)
    }

    @Test("Without the unified onboarding a not-started card still asks for a plan and ignores the account")
    func legacyFlowIgnoresAccount() {
        let summary = makeSummary(payment: activation(.notStarted), banking: activation(.processing))

        #expect(resolve(summary, isUnifiedOnboardingEnabled: false) == .planSelectNeeded)
        #expect(resolve(makeSummary(payment: activation(.unavailable), banking: activation(.notStarted)), isUnifiedOnboardingEnabled: false) == .unavailable)
    }

    // MARK: - Helpers

    private var oneActiveCard: TangemPayCustomerSummaryResponse.Cards {
        .init(active: 1, frozen: 0, pending: 0)
    }

    private func resolve(_ summary: TangemPayCustomerSummaryResponse, isUnifiedOnboardingEnabled: Bool = true) -> TangemPayEnrollmentState {
        TangemPaySummaryEnrollmentResolver.resolve(summary: summary, isUnifiedOnboardingEnabled: isUnifiedOnboardingEnabled)
    }
}

// MARK: - Fixtures

private func activation(
    _ status: TangemPayCustomerSummaryResponse.Activation.Status,
    step: TangemPayCustomerSummaryResponse.Activation.Step? = nil,
    failureReason: TangemPayCustomerSummaryResponse.Activation.FailureReason? = nil
) -> TangemPayCustomerSummaryResponse.Activation {
    TangemPayCustomerSummaryResponse.Activation(status: status, step: step, failureReason: failureReason)
}

private func makeSummary(
    customerStatus: TangemPayCustomerSummaryResponse.CustomerStatus = .new,
    kycStatus: TangemPayCustomerSummaryResponse.KYCStatus = .approved,
    payment: TangemPayCustomerSummaryResponse.Activation,
    banking: TangemPayCustomerSummaryResponse.Activation,
    cards: TangemPayCustomerSummaryResponse.Cards = .init(active: 0, frozen: 0, pending: 0)
) -> TangemPayCustomerSummaryResponse {
    TangemPayCustomerSummaryResponse(
        customerId: "customer",
        customerStatus: customerStatus,
        hidden: false,
        kycStatus: kycStatus,
        paymentAccount: .init(id: nil, activation: payment, cards: cards),
        bankingAccount: .init(id: nil, activation: banking)
    )
}
