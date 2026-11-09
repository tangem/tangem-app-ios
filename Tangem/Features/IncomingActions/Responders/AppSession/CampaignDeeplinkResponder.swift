//
//  CampaignDeeplinkResponder.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Shows the campaign a `tangem://campaigns` deeplink names, from wherever the user is: a numeric id opens
/// the promo campaign the main-screen banner opens for the selected wallet, any other id, or no wallet
/// selected, the cashback campaign as a floating sheet.
final class CampaignDeeplinkResponder {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.promoCampaignFlowLauncher) private var promoCampaignFlowLauncher: PromoCampaignFlowLaunching

    private var campaignCoordinator: CampaignCoordinator?
}

// MARK: - IncomingActionResponder

extension CampaignDeeplinkResponder: IncomingActionResponder {
    func didReceiveIncomingAction(_ action: IncomingAction) -> Bool {
        guard case .navigation(.campaigns(let deeplink)) = action else {
            return false
        }

        let target = CampaignDeeplinkTarget(
            deeplink: deeplink,
            selectedUserWalletId: userWalletRepository.selectedModel?.userWalletId
        )

        guard !promoCampaignFlowLauncher.isFlowActive else {
            return true
        }

        switch target {
        case .promoCampaign(let campaignId, let userWalletId):
            if campaignCoordinator == nil {
                promoCampaignFlowLauncher.startFlow(campaignId: campaignId, userWalletId: userWalletId)
            }
        case .cashbackCampaign(let campaignId):
            startCashbackCampaignFlow(campaignId: campaignId)
        }

        return true
    }
}

// MARK: - Private

private extension CampaignDeeplinkResponder {
    func startCashbackCampaignFlow(campaignId: String?) {
        // A campaign is already up: the link is answered by what is already on screen.
        guard campaignCoordinator == nil else {
            return
        }

        campaignCoordinator = CampaignFlowFactory().makeCampaignCoordinator(
            campaignId: campaignId,
            dismissAction: { [weak self] _ in
                self?.campaignCoordinator = nil
            },
            popToRootAction: { _ in }
        )
    }
}

// MARK: - CampaignDeeplinkTarget

enum CampaignDeeplinkTarget: Equatable {
    case promoCampaign(campaignId: Int, userWalletId: UserWalletId)
    case cashbackCampaign(campaignId: String?)

    init(deeplink: CampaignsDeeplink, selectedUserWalletId: UserWalletId?) {
        guard
            let campaignId = deeplink.campaignId,
            campaignId.allSatisfy({ $0.isASCII && $0.isNumber }),
            let promoCampaignId = Int(campaignId),
            let selectedUserWalletId
        else {
            self = .cashbackCampaign(campaignId: deeplink.campaignId)
            return
        }

        self = .promoCampaign(campaignId: promoCampaignId, userWalletId: selectedUserWalletId)
    }
}
