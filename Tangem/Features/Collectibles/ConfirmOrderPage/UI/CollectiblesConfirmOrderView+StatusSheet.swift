//
//  CollectiblesConfirmOrderView+StatusSheet.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI

extension CollectiblesConfirmOrderView {
    struct StatusSheet: View {
        let sheet: ViewModel.Sheet
        let onExplorePacks: () -> Void
        let onEnableTurboMode: () -> Void
        let onOpenPack: () -> Void
        let onOpenAgain: () -> Void

        var body: some View {
            switch sheet {
            case .lowInventory:
                lowInventory
            case .packUnopened:
                packUnopened
            case .buybackComplete(let amount, let price):
                buybackComplete(amount: amount, price: price)
            }
        }
    }
}

private extension CollectiblesConfirmOrderView.StatusSheet {
    // MARK: - View properties

    var lowInventory: some View {
        ModalStatus(
            .error,
            title: Localization.collectiblesLowInventoryTitle,
            description: Localization.collectiblesLowInventorySubtitle
        )
        .actions(
            primary: button(Localization.collectiblesLowInventoryExplorePacks, action: onExplorePacks),
            secondary: button(Localization.collectiblesLowInventoryEnableTurboMode, action: onEnableTurboMode)
        )
    }

    var packUnopened: some View {
        ModalStatus(
            .warning,
            title: Localization.collectiblesPackUnopenedTitle,
            description: Localization.collectiblesPackUnopenedSubtitle
        )
        .actions(primary: button(Localization.collectiblesPackUnopenedOpenPack, action: onOpenPack))
    }

    // [REDACTED_TODO_COMMENT]
    func buybackComplete(amount: String?, price: String) -> some View {
        let soldMessage = "Your common card was bought back instantly."

        return ModalStatus(
            .success,
            title: "Buyback complete",
            description: amount.map { "\(soldMessage) +\($0) is in your balance" } ?? soldMessage
        )
        .actions(
            primary: button("Open again for \(price)", action: onOpenAgain),
            secondary: button(Localization.collectiblesLowInventoryExplorePacks, action: onExplorePacks)
        )
    }

    func button(_ label: String, action: @escaping () -> Void) -> TangemUI.Button {
        TangemUI.Button(label: label, accessibilityLabel: nil, action: action)
    }
}

// MARK: - Previews

#Preview {
    CollectiblesConfirmOrderView.StatusSheet(
        sheet: .buybackComplete(amount: "35.60 USDC", price: "50 USDC"),
        onExplorePacks: {},
        onEnableTurboMode: {},
        onOpenPack: {},
        onOpenAgain: {}
    )
}
