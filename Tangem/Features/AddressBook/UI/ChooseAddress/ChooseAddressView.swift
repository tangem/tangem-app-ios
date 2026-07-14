//
//  ChooseAddressView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization
import BlockchainSdk

struct ChooseAddressView: View {
    let viewModel: ChooseAddressViewModel

    var body: some View {
        FloatingSheetContentWithHeader(
            headerConfig: .init(
                title: Localization.tokenDetailsChooseAddress,
                backAction: nil,
                closeAction: viewModel.close
            ),
            content: { sheetContent }
        )
        .floatingSheetConfiguration { configuration in
            configuration.backgroundInteractionBehavior = .tapToDismiss
            configuration.sheetBackgroundColor = DesignSystem.Color.bgPrimary
        }
    }

    private var sheetContent: some View {
        VStack(spacing: 16) {
            addressList
            cancelButton
        }
        .padding(.top, 8)
        .padding([.horizontal, .bottom], 16)
    }

    private var addressList: some View {
        GroupedSection(viewModel.rows) { row in
            ChooseAddressRowView(viewModel: row)
        }
        .backgroundColor(DesignSystem.Color.bgSecondary)
        .cornerRadius(20)
        .horizontalPadding(0)
        .separatorStyle(.none)
    }

    private var cancelButton: some View {
        TangemButtonV2(
            label: AttributedString(Localization.commonCancel),
            accessibilityLabel: Localization.commonCancel,
            action: viewModel.close
        )
        .styleType(.secondary)
        .size(.x12)
        .horizontalLayout(.infinity)
    }
}

// MARK: - Previews

#Preview {
    ChooseAddressView(
        viewModel: ChooseAddressViewModel(
            groups: [
                .init(
                    address: "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045",
                    memo: nil,
                    networks: [.init(id: .init(), blockchain: .ethereum(testnet: false))]
                ),
                .init(
                    address: "bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq",
                    memo: nil,
                    networks: [.init(id: .init(), blockchain: .bitcoin(testnet: false))]
                ),
                .init(
                    address: "0x742d35Cc6634C0532925a3b844Bc454e4438f44e",
                    memo: nil,
                    networks: [
                        .init(id: .init(), blockchain: .ethereum(testnet: false)),
                        .init(id: .init(), blockchain: .polygon(testnet: false)),
                    ]
                ),
            ],
            router: nil,
            onSelect: { _ in }
        )
    )
    .frame(maxHeight: .infinity, alignment: .bottom)
    .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
}
