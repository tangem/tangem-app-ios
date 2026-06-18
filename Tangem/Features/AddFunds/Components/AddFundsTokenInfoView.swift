//
//  AddFundsTokenInfoView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccounts
import TangemAssets
import TangemUI

struct AddFundsTokenInfoView: View {
    let viewData: ViewData

    var body: some View {
        VStack(spacing: 12) {
            TokenIcon(tokenIconInfo: viewData.tokenIconInfo, size: CGSize(width: 64, height: 64))

            VStack(spacing: 4) {
                LoadableTextView(
                    state: viewData.fiatBalance,
                    font: Font.Tangem.Body16.regular.font,
                    textColor: .Tangem.Text.Neutral.primary,
                    loaderSize: Constants.fiatLoaderSize
                )
                .minimumScaleFactor(0.5)

                LoadableTextView(
                    state: viewData.cryptoBalance,
                    font: Font.Tangem.Subheadline.regular.font,
                    textColor: .Tangem.Text.Neutral.tertiary,
                    loaderSize: Constants.cryptoLoaderSize
                )
            }

            AccountInlineHeaderView(iconData: viewData.accountBadge.iconData, name: viewData.accountBadge.name)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Colors.Background.action)
                )
        }
        .infinityFrame(axis: .horizontal)
    }
}

// MARK: - Constants

private extension AddFundsTokenInfoView {
    enum Constants {
        static let fiatLoaderSize = CGSize(width: 140, height: 28)
        static let cryptoLoaderSize = CGSize(width: 100, height: 18)
    }
}

// MARK: - ViewData

extension AddFundsTokenInfoView {
    struct ViewData: Hashable {
        let tokenIconInfo: TokenIconInfo
        let fiatBalance: LoadableTextView.State
        let cryptoBalance: LoadableTextView.State
        let accountBadge: AccountBadge
    }

    struct AccountBadge: Hashable {
        let iconData: AccountIconView.ViewData
        let name: String
    }
}

// MARK: - FormattedTokenBalanceType + LoadableTextView.State

extension FormattedTokenBalanceType {
    var loadableTextViewState: LoadableTextView.State {
        switch self {
        case .loading: .loading
        case .loaded(let value): .loaded(text: value)
        case .failure(let cached): .loaded(text: cached.value)
        }
    }
}
