//
//  AccountRowTrailingBalanceView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct AccountRowTrailingBalanceView: View {
    @ObservedObject var viewModel: AccountRowButtonViewModel

    @ScaledMetric private var loaderWidth: CGFloat = Constants.loaderSize.width
    @ScaledMetric private var loaderHeight: CGFloat = Constants.loaderSize.height

    var body: some View {
        if viewModel.isBalanceUnavailable {
            unavailableIcon
        } else if let balanceState = viewModel.trailingBalanceState {
            LoadableBalanceView(
                state: balanceState,
                style: .init(font: Fonts.Regular.subheadline, textColor: Colors.Text.primary1),
                loader: .init(size: CGSize(width: loaderWidth, height: loaderHeight))
            )
        }
    }

    private var unavailableIcon: some View {
        Assets.failedCloud.image
            .resizable()
            .renderingMode(.template)
            .foregroundStyle(DesignSystem.Color.iconTertiary)
            .frame(width: Constants.iconSize, height: Constants.iconSize)
    }
}

// MARK: - Constants

private extension AccountRowTrailingBalanceView {
    enum Constants {
        static let loaderSize = CGSize(width: 70, height: 16)
        static let iconSize: CGFloat = 12
    }
}
