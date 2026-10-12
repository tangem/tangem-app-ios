//
//  CampaignDeeplinkResponder.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Shows the campaign a `tangem://campaigns` deeplink names as a floating sheet, from wherever the user is.
final class CampaignDeeplinkResponder {
    private var campaignCoordinator: CampaignCoordinator?
}

// MARK: - IncomingActionResponder

extension CampaignDeeplinkResponder: IncomingActionResponder {
    func didReceiveIncomingAction(_ action: IncomingAction) -> Bool {
        guard case .navigation(.campaigns(let deeplink)) = action else {
            return false
        }

        // A campaign is already up: the link is answered by what is already on screen.
        guard campaignCoordinator == nil else {
            return true
        }

        campaignCoordinator = CampaignFlowFactory().makeCampaignCoordinator(
            campaignId: deeplink.campaignId,
            dismissAction: { [weak self] _ in
                self?.campaignCoordinator = nil
            },
            popToRootAction: { _ in }
        )

        return true
    }
}
