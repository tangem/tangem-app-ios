//
//  EarnGetTokenSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets
import TangemUI

final class EarnGetTokenSheetViewModel: Identifiable {
    let title: String
    let items: [TokenDetailsActionRowItem]

    init(title: String, items: [TokenDetailsActionRowItem]) {
        self.title = title
        self.items = items
    }
}

// MARK: - Factory

// [REDACTED_TODO_COMMENT]
extension EarnGetTokenSheetViewModel {
    static let order: [TokenActionType] = [.receive, .exchange, .buy]

    static func make(
        tokenSymbol: String,
        options: [TokenDetailsActionsViewModel.AddFundsOption],
        onSelect: @escaping (TokenActionType) -> Void
    ) -> EarnGetTokenSheetViewModel {
        let items = order.compactMap { type -> TokenDetailsActionRowItem? in
            guard let option = options.first(where: { $0.type == type }),
                  let copy = copy(for: type, tokenSymbol: tokenSymbol),
                  let icon = icon(for: type) else {
                return nil
            }

            return TokenDetailsActionRowItem(
                id: type,
                title: copy.title,
                subtitle: copy.subtitle,
                icon: icon,
                accessibilityIdentifier: type.accessibilityIdentifier,
                isAvailable: option.isAvailable,
                action: { onSelect(type) }
            )
        }

        return EarnGetTokenSheetViewModel(title: "Get \(tokenSymbol)", items: items)
    }

    private static func icon(for type: TokenActionType) -> ImageType? {
        switch type {
        case .receive: DesignSystem.Icons.ArrowDown.regular20
        case .exchange: DesignSystem.Icons.ArrowSwapHorizontal.regular20
        case .buy: DesignSystem.Icons.Card.regular20
        default: nil
        }
    }

    private static func copy(for type: TokenActionType, tokenSymbol: String) -> (title: String, subtitle: String)? {
        switch type {
        case .receive: ("Deposit \(tokenSymbol)", "Receive to your wallet from anywhere")
        case .exchange: ("Swap to \(tokenSymbol)", "Convert another token you already hold")
        case .buy: ("Buy \(tokenSymbol)", "Card or bank, via trusted partner")
        default: nil
        }
    }
}
