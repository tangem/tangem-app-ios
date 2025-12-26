//
//  AccountsAwareGetTokenViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemUI
import TangemAccounts
import Foundation

@MainActor
final class AccountsAwareGetTokenViewModel: ObservableObject, FloatingSheetContentViewModel {
    // MARK: - Published Properties

    let tokenItemViewState: EntitySummaryView.ViewState

    // MARK: - Private Properties

    private let onBuy: () -> Void
    private let onExchange: () -> Void
    private let onReceive: () -> Void
    private let onLater: () -> Void

    // MARK: - Initialization

    init(
        tokenItem: TokenItem,
        tokenItemIconInfoBuilder: TokenIconInfoBuilder,
        onBuy: @escaping () -> Void,
        onExchange: @escaping () -> Void,
        onReceive: @escaping () -> Void,
        onLater: @escaping () -> Void
    ) {
        self.onBuy = onBuy
        self.onExchange = onExchange
        self.onReceive = onReceive
        self.onLater = onLater

        // Build token header
        let tokenIconInfo = tokenItemIconInfoBuilder.build(
            for: tokenItem.amountType,
            in: tokenItem.blockchain,
            isCustom: tokenItem.token?.isCustom ?? false
        )

        tokenItemViewState = .content(
            EntitySummaryView.ViewState.ContentState(
                imageLocation: .customView(
                    EntitySummaryView.ViewState.ContentState.ImageLocation.CustomViewWrapper(
                        content: {
                            TokenIcon(
                                tokenIconInfo: tokenIconInfo,
                                size: .init(bothDimensions: 36)
                            )
                        }
                    )
                ),
                title: tokenItem.name,
                subtitle: tokenItem.currencySymbol,
                titleInfoConfig: nil
            )
        )
    }

    // MARK: - Public Methods

    func handleViewEvent(_ event: ViewEvent) {
        switch event {
        case .buyTapped:
            onBuy()

        case .exchangeTapped:
            onExchange()

        case .receiveTapped:
            onReceive()

        case .laterTapped:
            onLater()
        }
    }
}

// MARK: - ViewEvent

extension AccountsAwareGetTokenViewModel {
    enum ViewEvent {
        case buyTapped
        case exchangeTapped
        case receiveTapped
        case laterTapped
    }
}
