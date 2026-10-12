//
//  CryptoSearchPortfolioView.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct CryptoSearchPortfolioView: View {
    @ObservedObject var viewModel: MarketsPortfolioTokenListViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.walletSpacing) {
            ForEach(viewModel.sections, id: \.id) { wallet in
                CryptoSearchPortfolioWalletView(wallet: wallet)
            }
        }
    }
}

// MARK: - Constants

private extension CryptoSearchPortfolioView {
    enum Constants {
        static let walletSpacing: CGFloat = 16
    }
}
