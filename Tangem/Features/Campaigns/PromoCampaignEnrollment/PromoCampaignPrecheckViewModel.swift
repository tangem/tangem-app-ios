//
//  PromoCampaignPrecheckViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

final class PromoCampaignPrecheckViewModel: FloatingSheetContentViewModel {
    let state: State

    private weak var coordinator: CampaignRoutable?

    init(state: State, coordinator: CampaignRoutable?) {
        self.state = state
        self.coordinator = coordinator
    }

    var title: String {
        switch state {
        case .alreadyEnrolled(let campaignName, _): Localization.promoCampaignAlreadyActivatedTitle(campaignName)
        case .campaignUnavailable: Localization.promoCampaignUnavailableTitle
        case .temporarilyUnavailable: Localization.promoCampaignNotStartedTitle
        }
    }

    var subtitle: String? {
        switch state {
        case .alreadyEnrolled: nil
        case .campaignUnavailable: Localization.promoCampaignNotActiveSubtitle
        case .temporarilyUnavailable: Localization.commonTryAgainLater
        }
    }

    var payoutWallet: PromoCampaignEnrollmentWallet? {
        guard case .alreadyEnrolled(_, let wallets) = state, wallets.count == 1, let wallet = wallets.first, wallet.payout != nil else {
            return nil
        }

        return wallet
    }

    var icon: ImageType {
        switch state {
        case .alreadyEnrolled: DesignSystem.Icons.Info.regular28
        case .campaignUnavailable, .temporarilyUnavailable: DesignSystem.Icons.Warning.regular28
        }
    }

    var iconColor: Color {
        switch state {
        case .alreadyEnrolled: DesignSystem.Color.iconStatusInfo
        case .campaignUnavailable, .temporarilyUnavailable: DesignSystem.Color.iconStatusWarning
        }
    }

    var iconBackgroundColor: Color {
        switch state {
        case .alreadyEnrolled: DesignSystem.Color.bgStatusInfoSubtle
        case .campaignUnavailable, .temporarilyUnavailable: DesignSystem.Color.bgStatusWarningSubtle
        }
    }

    func close() {
        coordinator?.closeCampaign()
    }
}

// MARK: - State

extension PromoCampaignPrecheckViewModel {
    enum State {
        case alreadyEnrolled(campaignName: String, wallets: [PromoCampaignEnrollmentWallet])
        case campaignUnavailable
        case temporarilyUnavailable
    }
}
