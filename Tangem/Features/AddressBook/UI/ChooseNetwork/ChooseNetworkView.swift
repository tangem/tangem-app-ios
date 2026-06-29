//
//  ChooseNetworkView.swift
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

struct ChooseNetworkView: View {
    @ObservedObject var viewModel: ChooseNetworkViewModel

    var body: some View {
        NavigationStack {
            content
                .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
                .navigationTitle(Localization.commonChooseNetwork)
                .navigationBarTitleDisplayMode(.inline)
                .searchable(
                    text: $viewModel.searchText,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: Text(Localization.commonSearch)
                )
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .safeAreaInset(edge: .bottom) {
                    doneButton
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
                .toolbar {
                    NavigationToolbarButton.close(placement: .topBarTrailing, action: viewModel.close)
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        // .searchable hosts on this view; keep its identity stable across the empty<->results
        // transition so iOS 26 doesn't re-inline the search field ("search text field was already borrowed").
        ZStack {
            if viewModel.rows.isEmpty, !viewModel.searchText.isEmpty {
                noResultsView
            } else {
                networkList
            }
        }
    }

    private var noResultsView: some View {
        VStack(spacing: 8) {
            DesignSystem.Color.bgOpaquePrimary
                .frame(width: 48, height: 48)
                .overlay {
                    DesignSystem.Icons.Search.regular24.image
                        .renderingMode(.template)
                        .foregroundStyle(DesignSystem.Color.iconSecondary)
                }
                .clipShape(Circle())

            Text(Localization.commonNoResults)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .infinityFrame()
    }

    private var networkList: some View {
        GroupedScrollView(contentType: .lazy(alignment: .leading, spacing: 8)) {
            GroupedSection(viewModel.rows, isLazy: true) { row in
                ChooseNetworkRowView(viewModel: row)
            } header: {
                Text(Localization.commonAvailableNetworks)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 4)
            }
            .backgroundColor(DesignSystem.Color.bgSecondary)
            .cornerRadius(24)
            .separatorStyle(.none)
            .horizontalPadding(0)
        }
    }

    private var doneButton: some View {
        TangemButtonV2(
            label: AttributedString(Localization.commonDone),
            accessibilityLabel: Localization.commonDone,
            action: viewModel.done
        )
        .styleType(.default)
        .size(.x12)
        .horizontalLayout(.infinity)
        .disabled(!viewModel.isDoneEnabled)
    }
}

// MARK: - Previews

#Preview {
    final class PreviewHandler: ChooseNetworkOutput, ChooseNetworkRoutable {
        func chooseNetworkDidConfirm(_ selected: Set<BSDKBlockchain>) {}
        func dismissChooseNetwork() {}
    }

    let handler = PreviewHandler()

    return ChooseNetworkView(
        viewModel: ChooseNetworkViewModel(
            candidates: [
                .ethereum(testnet: false),
                .polygon(testnet: false),
                .bsc(testnet: false),
                .base(testnet: false),
            ],
            preselected: [.ethereum(testnet: false)],
            output: handler,
            routable: handler
        )
    )
}
