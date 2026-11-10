//
//  CollectiblesPendingPurchaseSheet.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

extension View {
    @ViewBuilder
    func collectiblesPendingPurchaseSheet(_ viewModel: CollectiblesPendingPurchaseBannersViewModel?) -> some View {
        if let viewModel {
            modifier(CollectiblesPendingPurchaseSheet(viewModel: viewModel))
        } else {
            self
        }
    }
}

private struct CollectiblesPendingPurchaseSheet: ViewModifier {
    @ObservedObject var viewModel: CollectiblesPendingPurchaseBannersViewModel

    func body(content: Content) -> some View {
        content
            .modalStatus(item: $viewModel.sheet, onDismiss: viewModel.sheetDidDismiss) { sheet in
                sheetView(sheet)
            }
    }
}

private extension CollectiblesPendingPurchaseSheet {
    // MARK: - View properties

    // [REDACTED_TODO_COMMENT]
    @ViewBuilder
    func sheetView(_ sheet: CollectiblesPendingPurchaseBannersViewModel.Sheet) -> some View {
        switch sheet {
        case .paymentInProgress:
            ModalStatus(
                title: "Payment in progress",
                description: "We noticed you have closed screen while the payment was in progress. Please wait a little bit for payment to be processed"
            ) {
                Avatar(.icon(DesignSystem.Icons.Clock.regular32, appearance: .info), size: .size72)
            }
            .actions(primary: button(Localization.commonClose, action: viewModel.closeSheet))
        case .packUnopened:
            ModalStatus(
                .warning,
                title: Localization.collectiblesPackUnopenedTitle,
                description: Localization.collectiblesPackUnopenedSubtitle
            )
            .actions(primary: button(Localization.collectiblesPackUnopenedOpenPack, action: viewModel.openPackFromSheet))
        }
    }

    func button(_ label: String, action: @escaping () -> Void) -> TangemUI.Button {
        TangemUI.Button(label: label, accessibilityLabel: nil, action: action)
    }
}
