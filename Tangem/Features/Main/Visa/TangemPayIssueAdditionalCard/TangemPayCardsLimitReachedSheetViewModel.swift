//
//  TangemPayCardsLimitReachedSheetViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

protocol TangemPayCardsLimitReachedSheetRoutable: AnyObject {
    func closeCardsLimitReachedSheet()
    func cardsLimitReachedSheetDidRequestPlanUpgrade()
}

final class TangemPayCardsLimitReachedSheetViewModel: TangemPayPopupViewModel {
    var icon: Image {
        DesignSystem.Icons.Error.regular28.image
    }

    var iconStyle: TangemPayPopupIconStyle {
        .warning
    }

    var title: AttributedString {
        .init(Localization.tangempayMaximumCardsIssuedForPlanTitle)
    }

    var description: AttributedString {
        .init(Localization.tangempayMaximumCardsIssuedForPlanDescription)
    }

    var primaryButton: MainButton.Settings {
        MainButton.Settings(
            title: Localization.tangempayMaximumCardsIssuedForPlanUpgradeBtn,
            style: .primary,
            size: .default,
            action: upgrade
        )
    }

    var secondaryButton: MainButton.Settings? {
        MainButton.Settings(
            title: Localization.commonCancel,
            style: .secondary,
            size: .default,
            action: dismiss
        )
    }

    private weak var coordinator: TangemPayCardsLimitReachedSheetRoutable?

    init(coordinator: TangemPayCardsLimitReachedSheetRoutable?) {
        self.coordinator = coordinator
    }

    func dismiss() {
        coordinator?.closeCardsLimitReachedSheet()
    }
}

// MARK: - Private

private extension TangemPayCardsLimitReachedSheetViewModel {
    func upgrade() {
        Analytics.log(.visaTiersChangePlanClicked)
        coordinator?.cardsLimitReachedSheetDidRequestPlanUpgrade()
    }
}
