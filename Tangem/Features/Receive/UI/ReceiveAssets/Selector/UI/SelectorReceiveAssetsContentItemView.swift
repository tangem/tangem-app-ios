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
    @State private var containerWidth: CGFloat = UIScreen.main.bounds.width

    var body: some View {
        content
            .readGeometry(\.size.width, bindTo: $containerWidth)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.viewState {
        case .address(let viewModels):
            drawAddressAssets(for: viewModels, width: containerWidth)
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

    private func drawAddressAssets(for viewModels: [SelectorReceiveAssetsAddressPageItemViewModel], width: CGFloat) -> some View {
        let pageSpacing: CGFloat = Layout.Container.horizontalSpacing
        let contentWidth = max(0, width - 2 * Layout.Container.horizontalPadding)
        let pageWidth = max(0, contentWidth)

        return VStack(spacing: .zero) {
            PagerWithDots(
                viewModels,
                indexUpdateNotifier: viewModel.pageAssetIndexUpdateNotifier,
                pageWidth: pageWidth,
                initialIndex: viewModel.pageAssetIndex
            ) {
                SelectorReceiveAssetsAddressPageItemView(viewModel: $0)
                    .padding(.horizontal, pageSpacing)
            }
        }
        .frame(width: contentWidth, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, Layout.Container.horizontalPadding)
        .clipped()
        .disableAnimations()
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
