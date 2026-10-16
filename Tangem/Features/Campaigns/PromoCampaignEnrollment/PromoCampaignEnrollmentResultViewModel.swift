//
//  PromoCampaignEnrollmentResultViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLocalization
import TangemUI

protocol PromoCampaignEnrollmentResultRoutable: AnyObject {
    func closePromoCampaignEnrollmentResult()
}

final class PromoCampaignEnrollmentResultViewModel: Identifiable {
    let state: State

    private weak var coordinator: PromoCampaignEnrollmentResultRoutable?

    init(state: State, coordinator: PromoCampaignEnrollmentResultRoutable?) {
        self.state = state
        self.coordinator = coordinator
    }

    var appearance: StatusScreenAppearance {
        switch state {
        case .enrolled, .partiallyEnrolled: .success
        case .alreadyEnrolled: .info
        case .campaignUnavailable, .temporarilyUnavailable: .warning
        case .failed: .error
        }
    }

    var title: String {
        switch state {
        case .enrolled(let campaignName, _), .partiallyEnrolled(let campaignName, _):
            Localization.promoCampaignEnrollSuccessTitle(campaignName)
        case .alreadyEnrolled(let campaignName, _):
            Localization.promoCampaignAlreadyActivatedTitle(campaignName)
        case .campaignUnavailable:
            Localization.promoCampaignUnavailableTitle
        case .temporarilyUnavailable:
            Localization.promoCampaignNotStartedTitle
        case .failed:
            Localization.commonSomethingWentWrong
        }
    }

    var description: String? {
        switch state {
        case .enrolled(_, let walletCount):
            walletCount > 1 ? Localization.promoCampaignAllWalletsEnrolled : nil
        case .partiallyEnrolled:
            Localization.promoCampaignSomeWalletsEnrolled
        case .alreadyEnrolled:
            nil
        case .campaignUnavailable:
            Localization.promoCampaignNotActiveSubtitle
        case .temporarilyUnavailable:
            Localization.commonTryAgainLater
        case .failed:
            Localization.commonUnknownError
        }
    }

    var payoutWallet: PromoCampaignEnrollmentWallet? {
        guard case .alreadyEnrolled(_, let wallets) = state, wallets.count == 1, let wallet = wallets.first, wallet.payout != nil else {
            return nil
        }

        return wallet
    }

    var enrolledWallets: [PromoCampaignEnrolledWalletViewModel] {
        guard case .partiallyEnrolled(_, let enrolledWallets) = state else {
            return []
        }

        return enrolledWallets
    }

    var actionTitle: String {
        switch state {
        case .enrolled, .partiallyEnrolled: Localization.commonGotIt
        case .alreadyEnrolled, .campaignUnavailable, .temporarilyUnavailable, .failed: Localization.commonClose
        }
    }

    func performAction() {
        coordinator?.closePromoCampaignEnrollmentResult()
    }
}

// MARK: - State

extension PromoCampaignEnrollmentResultViewModel {
    enum State {
        case enrolled(campaignName: String, walletCount: Int)
        case alreadyEnrolled(campaignName: String, wallets: [PromoCampaignEnrollmentWallet])
        case partiallyEnrolled(campaignName: String, enrolledWallets: [PromoCampaignEnrolledWalletViewModel])
        case campaignUnavailable
        case temporarilyUnavailable
        case failed
    }
}
