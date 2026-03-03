//
//  MainUserWalletHeader.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct MainUserWalletHeader: View {
    @ObservedObject var viewModel: MainHeaderViewModel

    @ScaledSize private var loaderSize: CGSize = .init(width: 222, height: 36)

    var body: some View {
        VStack(spacing: 0) {
            balance
        }
        .frame(maxWidth: .infinity)
    }

    private var balance: some View {
        LoadableBalanceView(
            state: viewModel.balance,
            style: .init(
                font: Font.Tangem.title44,
                textColor: Color.Tangem.Text.Neutral.primary
            ),
            loader: .init(
                size: loaderSize,
                cornerRadiusStyle: .capsule
            )
        )
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 17, *)
#Preview {
    @Previewable @State var provider = FakeCardHeaderPreviewProvider()

    VStack(spacing: 20) {
        ForEach(provider.models.indices, id: \.self) { index in
            MainUserWalletHeader(viewModel: provider.models[index])
                .onTapGesture {
                    let infoProvider = provider.infoProviders[index]
                    infoProvider.tapAction(infoProvider)
                }
        }
    }
    .padding()
}
#endif // DEBUG
