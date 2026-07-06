//
//  SelectorReceiveAssetsContentItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemLocalization

struct SelectorReceiveAssetsContentItemView: View {
    private(set) var viewModel: SelectorReceiveAssetsContentItemViewModel

    var body: some View {
        content
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.viewState {
        case .address(let viewModels):
            drawAddressAssets(for: viewModels)
        case .domain(let viewModels):
            drawDomainAssets(for: viewModels)
        }
    }

    // MARK: - Private Implementation

    private func drawDomainAssets(for viewModels: [SelectorReceiveAssetsDomainItemViewModel]) -> some View {
        ForEach(viewModels, id: \.id) { viewModel in
            if FeatureProvider.isAvailable(.redesign) {
                RedesignedSelectorReceiveAssetsDomainItemView(viewModel: viewModel)
            } else {
                // [REDACTED_INFO]: drop the legacy domain item once redesign ships.
                SelectorReceiveAssetsDomainItemView(viewModel: viewModel)
            }
        }
    }

    private func drawAddressAssets(for viewModels: [SelectorReceiveAssetsAddressPageItemViewModel]) -> some View {
        TangemCarousel(viewModels, initialIndex: viewModel.pageAssetIndex) { vm in
            if FeatureProvider.isAvailable(.redesign) {
                RedesignedSelectorReceiveAssetsAddressPageItemView(viewModel: vm)
            } else {
                // [REDACTED_INFO]: drop the legacy address page item once redesign ships.
                SelectorReceiveAssetsAddressPageItemView(viewModel: vm)
            }
        }
        .interItemSpacing(Layout.Container.horizontalSpacing)
        // Figma: 8 from card to the page-control frame, which adds 6 around the dots (→ 6 below them).
        .paginationSpacing(FeatureProvider.isAvailable(.redesign) ? 8 : SizeUnit.x4.value)
        .paginationVerticalPadding(FeatureProvider.isAvailable(.redesign) ? 6 : 0)
        .paginationHasBackground(false)
        .currentIndexHasChanged { viewModel.updatePageIndex($0) }
        .clipped()
    }
}

extension SelectorReceiveAssetsContentItemView {
    enum Layout {
        enum Container {
            static let horizontalPadding: CGFloat = 12
            static let horizontalSpacing: CGFloat = 12
        }
    }
}
