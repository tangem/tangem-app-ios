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
            case .refundOnTheWay:
                refundOnTheWay
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

    var refundOnTheWay: some View {
        ModalStatus(
            .info,
            title: Localization.collectiblesRefundOnTheWayTitle,
            description: Localization.collectiblesRefundOnTheWaySubtitle
        )
        .actions(primary: button(Localization.commonClose, action: onExplorePacks))
    }

    @ViewBuilder
    func buybackComplete(_ content: CollectiblesConfirmOrderViewModel.BuybackComplete) -> some View {
        let title = [Localization.collectiblesAutoBuybackTitle, content.cardName]
            .compactMap { $0 }
            .joined(separator: "\n")
        let openAgain = openAgainButton(price: content.price)

        switch (content.cardImageURL, content.amount.map(soldMessageText(amount:))) {
        case (let cardImageURL?, let description?):
            ModalStatus(title: title, description: description) { cardImage(url: cardImageURL) }
                .actions(primary: openAgain, secondary: explorePacksButton)
        case (let cardImageURL?, nil):
            ModalStatus(title: title) { cardImage(url: cardImageURL) }
                .actions(primary: openAgain, secondary: explorePacksButton)
        case (nil, let description?):
            ModalStatus(.success, title: title, description: description)
                .actions(primary: openAgain, secondary: explorePacksButton)
        case (nil, nil):
            ModalStatus(.success, title: title)
                .actions(primary: openAgain, secondary: explorePacksButton)
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

    func soldMessageText(amount: String) -> AttributedString {
        var text = AttributedString(Localization.collectiblesAutoBuybackMessage(amount))

        if let amountRange = text.range(of: amount) {
            text[amountRange].foregroundColor = DesignSystem.Color.textPrimary
        }

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
