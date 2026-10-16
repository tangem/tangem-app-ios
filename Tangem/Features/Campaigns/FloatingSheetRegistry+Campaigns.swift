//
//  FloatingSheetRegistry+Campaigns.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import class TangemUI.FloatingSheetRegistry

extension FloatingSheetRegistry {
    /// Registered outside the view tree: a campaign deeplink shows the sheet from any screen, including
    /// those presented over the main screen through UIKit.
    func registerCampaignFloatingSheets() {
        register(CampaignViewModel.self, viewBuilder: CampaignView.init)
        register(PromoCampaignPrecheckViewModel.self, viewBuilder: PromoCampaignPrecheckView.init)
    }
}
