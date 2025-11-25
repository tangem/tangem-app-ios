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
            SelectorReceiveAssetsDomainItemView(viewModel: viewModel)
        }
    }

    private func drawAddressAssets(for viewModels: [SelectorReceiveAssetsAddressPageItemViewModel]) -> some View {
        GeometryReader { geometry in
            VStack(spacing: .zero) {
                PagerWithDots(
                    viewModels,
                    indexUpdateNotifier: viewModel.pageAssetIndexUpdateNotifier,
                    pageWidth: geometry.size.width
                ) {
                    SelectorReceiveAssetsAddressPageItemView(viewModel: $0)
                        .padding(.bottom, Layout.PagerWithDots.bottomPadding)
                }
            }
            .frame(width: geometry.size.width, alignment: .leading)
            .clipped()
        }
        .if(viewModels.count > 1) { view in
            view.frame(minHeight: Layout.GeometryReader.minHeightWithPager)
        } else: { view in
            view.frame(minHeight: Layout.GeometryReader.minHeightWithoutPager)
        }
    }
}

extension SelectorReceiveAssetsContentItemView {
    enum Layout {
        enum GeometryReader {
            /// 318
            static let minHeightWithPager: CGFloat = 318
            /// 286
            static let minHeightWithoutPager: CGFloat = 286
        }

        enum PagerWithDots {
            /// 8
            static let bottomPadding: CGFloat = 8
        }
    }
}
