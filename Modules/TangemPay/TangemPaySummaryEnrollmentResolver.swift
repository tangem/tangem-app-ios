//
//  TangemPaySummaryEnrollmentResolver.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public enum TangemPaySummaryEnrollmentResolver {
    public static func resolve(
        summary: TangemPayCustomerSummaryResponse,
        isUnifiedOnboardingEnabled: Bool
    ) -> TangemPayEnrollmentState {
        if summary.customerStatus == .former {
            return .cardDeactivated
        }

        switch summary.kycStatus {
        case .approved:
            break
        case .declined:
            return .kycDeclined
        case .inProgress:
            return .kycInProgress
        case .required, .undefined:
            return .kycRequired
        }

        if summary.paymentAccount.areAllCardsDeactivated {
            return .cardDeactivated
        }

        guard isUnifiedOnboardingEnabled else {
            return resolveCardOnly(paymentStatus: summary.paymentAccount.activation.status)
        }

        if isDeclinedByIssuer(summary) {
            return .kycDeclined
        }

        let isAccountUntouched = [.notStarted, .unavailable].contains(summary.bankingAccount.activation.status)

        switch summary.paymentAccount.activation.status {
        case .processing, .completed:
            return .enrolled
        case .failed:
            return .failedToIssueCard
        case .notStarted, .unavailable:
            return isAccountUntouched ? .verified : .cardNotOpened
        case .deactivated, .undefined:
            return .unavailable
        }
    }

    private static func resolveCardOnly(
        paymentStatus: TangemPayCustomerSummaryResponse.Activation.Status
    ) -> TangemPayEnrollmentState {
        switch paymentStatus {
        case .processing, .completed: .enrolled
        case .failed: .failedToIssueCard
        case .notStarted: .planSelectNeeded
        case .unavailable, .deactivated, .undefined: .unavailable
        }
    }

    private static func isDeclinedByIssuer(_ summary: TangemPayCustomerSummaryResponse) -> Bool {
        let payment = summary.paymentAccount.activation
        let banking = summary.bankingAccount.activation

        if payment.status == .failed, payment.failureReason == .rainRejected {
            return ![.completed, .deactivated, .processing].contains(banking.status)
        }

        if banking.status == .failed, banking.failureReason == .rainRejected {
            return ![.completed, .processing].contains(payment.status)
        }

        return false
    }
}
