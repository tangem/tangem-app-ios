//
//  CollectiblesConfirmOrderView+StatusSheet.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Kingfisher
import SwiftUI
import TangemAssets
import TangemCollectibles
import TangemLocalization
import TangemUI
import TangemUIUtils

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
            case .buybackComplete(let content):
                buybackComplete(content)
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
    @ViewBuilder
    func buybackComplete(_ content: CollectiblesConfirmOrderViewModel.BuybackComplete) -> some View {
        let title = [Localization.collectiblesAutoBuybackTitle, content.cardName]
            .compactMap { $0 }
            .joined(separator: "\n")

        let description = soldMessageText(amount: content.amount)

        if let cardImageURL = content.cardImageURL {
            ModalStatus(title: title, description: description) { cardImage(url: cardImageURL) }
                .actions(primary: openAgainButton(price: content.price), secondary: explorePacksButton)
        } else {
            ModalStatus(.success, title: title, description: description)
                .actions(primary: openAgainButton(price: content.price), secondary: explorePacksButton)
        }
    }

    func cardImage(url: URL) -> some View {
        KFImage(url)
            .resizable()
            .cancelOnDisappear(true)
            .cacheOriginalImage()
            .placeholder { Shimmer() }
            .onFailureView { missingCardImage }
            .aspectRatio(contentMode: .fill)
            .frame(width: Metrics.cardSize.width, height: Metrics.cardSize.height)
            .clipShape(RoundedRectangle(cornerRadius: Metrics.cardCornerRadius, style: .continuous))
            .accessibilityHidden(true)
    }

    var missingCardImage: some View {
        DesignSystem.Color.bgSecondary
            .overlay { Avatar(.icon(DesignSystem.Icons.Error.filled20), size: .size40) }
    }

    func soldMessageText(amount: String?) -> AttributedString {
        var text = AttributedString("Your common card was sold back instantly.")

        guard let amount else {
            return text
        }

        var credited = AttributedString("+\(amount)")
        credited.foregroundColor = DesignSystem.Color.textPrimary

        text.append(AttributedString("\n"))
        text.append(credited)
        let network = CollectiblesChainEnvironment.usdcTokenItem.networkName
        text.append(AttributedString(" on \(network) has been credited to your main Tangem Wallet"))
        return text
    }

    func openAgainButton(price: String) -> TangemUI.Button {
        button(Localization.collectiblesAutoBuybackOpenAgainButton(price), action: onOpenAgain)
    }

    var explorePacksButton: TangemUI.Button {
        button(Localization.collectiblesLowInventoryExplorePacks, action: onExplorePacks)
    }

    func button(_ label: String, action: @escaping () -> Void) -> TangemUI.Button {
        TangemUI.Button(label: label, accessibilityLabel: nil, action: action)
    }
}

// MARK: - Metrics

private extension CollectiblesConfirmOrderView.StatusSheet {
    enum Metrics {
        static let cardSize = CGSize(width: 97, height: 165)
        static let cardCornerRadius: CGFloat = 5
    }
}

// MARK: - Previews

#Preview {
    CollectiblesConfirmOrderView.StatusSheet(
        sheet: .buybackComplete(.init(
            cardImageURL: nil,
            cardName: "2024 Series One #216",
            amount: "40.35 USDC",
            price: "50 USDC"
        )),
        onExplorePacks: {},
        onEnableTurboMode: {},
        onOpenPack: {},
        onOpenAgain: {}
    )
}
