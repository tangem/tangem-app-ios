//
//  CampaignFlowFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct CampaignFlowFactory {
    func makeCampaignCoordinator(
        campaignId: String,
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) -> CampaignCoordinator {
        let coordinator = CampaignCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
        let viewModel = makeCampaignViewModel(campaignId: campaignId, coordinator: coordinator)

        coordinator.start(with: .init(viewModel: viewModel))
        return coordinator
    }

    private func makeCampaignViewModel(campaignId: String, coordinator: CampaignRoutable) -> CampaignViewModel {
        let analyticsLogger = CashbackCampaign(rawValue: campaignId).map { CampaignAnalyticsLogger(campaign: $0) }

        return CampaignViewModel(
            campaignId: campaignId,
            coordinator: coordinator,
            cashbackPromoService: CashbackPromoService(),
            analyticsLogger: analyticsLogger
        )
    }
}
