//
//  TangemPayFakedoorSheetViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemFoundation
import TangemLocalization

protocol TangemPayFakedoorSheetRoutable: AnyObject {
    func closeFakedoorSheet()
}

final class TangemPayFakedoorSheetViewModel: FloatingSheetContentViewModel, TangemPayPopupViewModel {
    var icon: Image {
        Assets.Visa.multipleCardsFakedoor.image
    }

    var title: AttributedString {
        .init(Localization.tangempayFeatureWillBeAvailableSoon)
    }

    var description: AttributedString {
        .init(Localization.tangempayFeatureWillBeAvailableSoonDescription)
    }

    var primaryButton: MainButton.Settings {
        MainButton.Settings(
            title: Localization.commonGotIt,
            style: .secondary,
            size: .default,
            action: { [weak self] in
                self?.dismiss()
            }
        )
    }

    private weak var coordinator: TangemPayFakedoorSheetRoutable?

    init(coordinator: TangemPayFakedoorSheetRoutable) {
        self.coordinator = coordinator
    }

    func dismiss() {
        coordinator?.closeFakedoorSheet()
    }
}
