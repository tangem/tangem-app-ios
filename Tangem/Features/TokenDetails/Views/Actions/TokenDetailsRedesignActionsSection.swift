//
//  TokenDetailsRedesignActionsSection.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct TokenDetailsRedesignActionsSection<Banners: View, QuickTopUp: View>: View {
    @ObservedObject var actionsViewModel: TokenDetailsActionsViewModel
    private let banners: Banners
    private let quickTopUp: QuickTopUp

    init(
        actionsViewModel: TokenDetailsActionsViewModel,
        @ViewBuilder banners: () -> Banners,
        @ViewBuilder quickTopUp: () -> QuickTopUp
    ) {
        self.actionsViewModel = actionsViewModel
        self.banners = banners()
        self.quickTopUp = quickTopUp()
    }

    var body: some View {
        switch bannerPlacement {
        case .aboveActions:
            quickTopUp
            banners
            TokenDetailsActionsView(viewModel: actionsViewModel)

        case .belowActions:
            TokenDetailsActionsView(viewModel: actionsViewModel)
            quickTopUp
            banners
        }
    }

    private var bannerPlacement: RedesignBannerPlacement {
        switch actionsViewModel.mode {
        case .buttonsRow:
            return .belowActions
        case .inlineList, .hidden:
            return .aboveActions
        }
    }
}

private enum RedesignBannerPlacement {
    case aboveActions
    case belowActions
}
