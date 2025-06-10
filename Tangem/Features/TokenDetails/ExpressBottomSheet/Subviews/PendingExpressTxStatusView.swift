//
//  PendingExpressTxStatusView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets

struct PendingExpressTxStatusView: View {
    let title: String
    let statusesList: [PendingExpressTxStatusRow.StatusRowData]
    let topTrailingAction: TopTrailingAction?

    var body: some View {
        VStack(spacing: 14) {
            headerView
            statusesView
        }
        .defaultRoundedBackground(with: Colors.Background.action)
    }

    private var headerView: some View {
        HStack {
            Text(title)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

            Spacer()

            switch topTrailingAction {
            case .goToProvider(let action):
                Button(action: action) { openProviderButtonLabel }
            case .copyTxId(let id):
                PendingExpressTxIdCopyButtonView(viewModel: .init(transactionID: id))
            case .none:
                EmptyView()
            }
        }
    }

    private var openProviderButtonLabel: some View {
        HStack(spacing: 4) {
            Assets.arrowRightUpMini.image
                .resizable()
                .renderingMode(.template)
                .foregroundColor(Colors.Text.tertiary)
                .frame(size: .init(bothDimensions: 18))

            Text(Localization.commonGoToProvider)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
        }
    }

    private var statusesView: some View {
        VStack(spacing: 0) {
            ForEach(statusesList.indexed(), id: \.1) { index, status in
                PendingExpressTxStatusRow(isFirstRow: index == 0, info: status)
            }
        }
    }
}

extension PendingExpressTxStatusView {
    enum TopTrailingAction {
        case goToProvider(action: () -> Void)
        case copyTxId(id: String)
    }
}
