//
//  WCEthTransactionDetailsView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import BlockchainSdk
import TangemUI
import TangemAssets

struct WCEthTransactionDetailsView: View {
    @ObservedObject var viewModel: WCTransactionViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            connectionTargetRow

            WCTransactionNetworkRow(blockchain: viewModel.transactionData.blockchain)

            separator

            addressRowView

            feeRow
        }
        .background(Colors.Background.action)
        .cornerRadius(14, corners: .allCorners)
    }

    @ViewBuilder
    private var connectionTargetRow: some View {
        if let connectionTargetKind = viewModel.connectionTargetKind {
            WCTransactionConnectionTargetRow(kind: connectionTargetKind)
            separator
        }
    }

    @ViewBuilder
    private var addressRowView: some View {
        if let addressRowViewModel = viewModel.addressRowViewModel {
            WCTransactionAddressRowView(viewModel: addressRowViewModel)
            separator
        }
    }

    @ViewBuilder
    private var feeRow: some View {
        if let feeRowViewModel = viewModel.feeRowViewModel {
            WCFeeRowView(viewModel: feeRowViewModel)
        }
    }

    private var separator: some View {
        Separator(height: .minimal, color: Colors.Stroke.primary)
            .padding(.leading, 46)
            .padding(.trailing, 14)
    }
}
