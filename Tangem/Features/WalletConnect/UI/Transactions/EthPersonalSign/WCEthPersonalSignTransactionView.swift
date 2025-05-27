//
//  WCEthPersonalSignTransactionView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import BlockchainSdk
import TangemUI
import TangemAssets
import TangemUIUtils

final class WCEthPersonalSignTransactionViewModel: ObservableObject {
    let userWalletName: String
    let ethereumBlockchain: Blockchain = .ethereum(testnet: false)

    private(set) lazy var ethereumIcon: TokenIconInfo? = {
        let tokenItemMapper = TokenItemMapper(supportedBlockchains: Blockchain.allMainnetCases.toSet())

        guard
            let token = tokenItemMapper.mapToTokenItem(
                id: ethereumBlockchain.coinId,
                name: ethereumBlockchain.coinDisplayName,
                symbol: ethereumBlockchain.currencySymbol,
                network: .init(networkId: ethereumBlockchain.networkId, contractAddress: nil, decimalCount: nil)
            )
        else {
            return nil
        }

        return TokenIconInfoBuilder().build(from: token, isCustom: false)
    }()

    init(userWalletName: String) {
        self.userWalletName = userWalletName
    }
}

struct WCEthPersonalSignTransactionView: View {
    @StateObject private var viewModel: WCEthPersonalSignTransactionViewModel

    init(userWalletName: String) {
        _viewModel = .init(wrappedValue: .init(userWalletName: userWalletName))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            wallet
                .padding(.init(top: 12, leading: 16, bottom: 0, trailing: 16))

            Separator(height: .minimal, color: Colors.Stroke.primary)
                .padding(.init(top: 10, leading: 46, bottom: 10, trailing: 16))

            network
                .padding(.init(top: 0, leading: 16, bottom: 12, trailing: 16))
        }
        .background(Colors.Background.action)
        .cornerRadius(14, corners: .allCorners)
    }

    // [REDACTED_TODO_COMMENT]
    var wallet: some View {
        HStack(spacing: 0) {
            Assets.Glyphs.walletNew.image
                .renderingMode(.template)
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundStyle(Colors.Icon.accent)
                .padding(.trailing, 8)
            Text("Wallet")
                .style(Fonts.Regular.body, color: Colors.Text.primary1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 8)
            Text(viewModel.userWalletName)
                .style(Fonts.Regular.body, color: Colors.Text.tertiary)
        }
    }

    // [REDACTED_TODO_COMMENT]
    var network: some View {
        HStack(spacing: 0) {
            Assets.Glyphs.networkNew.image
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundStyle(Colors.Icon.accent)
                .padding(.trailing, 8)

            Text("Networks")
                .style(Fonts.Regular.body, color: Colors.Text.primary1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 8)

            Text(viewModel.ethereumBlockchain.displayName)
                .style(Fonts.Regular.body, color: Colors.Text.tertiary)
                .padding(.trailing, 2)

            if let icon = viewModel.ethereumIcon {
                TokenIcon(tokenIconInfo: icon, size: .init(bothDimensions: 20))
            }
        }
    }
}
