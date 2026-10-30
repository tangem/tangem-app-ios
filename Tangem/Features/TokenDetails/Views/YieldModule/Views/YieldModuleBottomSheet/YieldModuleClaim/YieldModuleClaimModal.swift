//
//  YieldModuleClaimModal.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLocalization
import TangemUI

enum YieldModuleClaimModal {
    static func size(_ viewModel: YieldModuleClaimViewModel) -> ModalSize {
        switch viewModel.viewState {
        case .claim(let viewData): viewData.rewardsCount > 1 ? .full : .flexible
        case .success: .full
        }
    }

    static func contentLayout(_ viewModel: YieldModuleClaimViewModel) -> ModalContentLayout {
        switch viewModel.viewState {
        case .claim: .scrollable
        case .success: .fill
        }
    }

    static func navigation(_ viewModel: YieldModuleClaimViewModel) -> ModalNavigation? {
        switch viewModel.viewState {
        case .claim:
            .title(
                Localization.yieldModuleClaimSheetTitle,
                subtitle: Localization.yieldModuleClaimSheetSubtitle,
                isCloseEnabled: !viewModel.isProcessingRequest
            )
        case .success:
            .closeButton()
        }
    }
}
