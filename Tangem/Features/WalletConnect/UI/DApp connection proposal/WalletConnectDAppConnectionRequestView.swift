//
//  WalletConnectDAppConnectionRequestView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

struct WalletConnectDAppConnectionRequestView: View {
    @ObservedObject var viewModel: WalletConnectDAppConnectionRequestViewModel

    var body: some View {
        VStack(spacing: .zero) {
            Button("verification state") { viewModel.handle(viewEvent: .verifiedDomainIconTapped) }
            Button("wallet state") { viewModel.handle(viewEvent: .walletRowTapped) }
            Button("networks state") { viewModel.handle(viewEvent: .networksRowTapped) }
        }
        .frame(height: 500)
    }
}
