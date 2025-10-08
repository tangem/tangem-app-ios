//
//  SelectorReceiveAssetsContentItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct SelectorReceiveAssetsContentItemView: View {
    private(set) var viewModel: SelectorReceiveAssetsContentItemViewModel

    var body: some View {
        switch viewModel.stateView {
        case .address(let viewModels):
            drawAddressAssets(for: viewModels)
        case .domain(let viewModels):
            drawDomainAssets(for: viewModels)
        }
    }

    // MARK: - Private Implementation

    private func drawDomainAssets(for viewModels: [SelectorReceiveAssetsDomainItemViewModel]) -> some View {
        ForEach(viewModels, id: \.id) { viewModel in
            SelectorReceiveAssetsDomainItemView(viewModel: viewModel)
        }
    }

    private func drawAddressAssets(for viewModels: [SelectorReceiveAssetsAddressPageItemViewModel]) -> some View {
        GeometryReader { geometry in
            PagerWithDots(
                viewModels,
                indexUpdateNotifier: viewModel.pageAssetIndexUpdateNotifier,
                pageWidth: geometry.size.width
            ) {
                SelectorReceiveAssetsAddressPageItemView(viewModel: $0)
            }
        }
        .frame(minHeight: 400) // Минимальная высота для контента
    }
}
