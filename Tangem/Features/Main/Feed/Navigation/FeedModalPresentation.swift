//
//  FeedModalPresentation.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct FeedModalPresentation: ViewModifier {
    @ObservedObject var coordinator: FeedCoordinator

    func body(content: Content) -> some View {
        content.background {
            Color.clear.modal(
                item: modal,
                size: size(for:),
                header: header(for:),
                content: modalContent(for:),
                footer: footer(for:)
            )
        }
    }

    private var modal: Binding<FeedModal?> {
        Binding(
            get: { coordinator.modal },
            set: { modal in
                if modal == nil {
                    coordinator.dismissModal()
                }
            }
        )
    }

    private func size(for modal: FeedModal) -> ModalSize {
        switch modal {
        case .marketCapInfo, .earnTypeFilter: .flexible
        case .pulseTagFilter, .realAssetsCategoryFilter, .earnNetworkFilter: .full
        }
    }

    @ViewBuilder
    private func header(for modal: FeedModal) -> some View {
        switch modal {
        case .pulseTagFilter(let viewModel):
            PulseTagFilterHeaderView(viewModel: viewModel)
        case .marketCapInfo(let viewModel):
            FeedModalHeaderView(title: nil, onClose: viewModel.closeAction)
        case .realAssetsCategoryFilter(let viewModel):
            FeedModalHeaderView(title: Localization.marketsRealAssetsFilterTitle, onClose: viewModel.close)
        case .earnNetworkFilter(let viewModel):
            FeedModalHeaderView(title: viewModel.title, onClose: viewModel.onCloseTap)
        case .earnTypeFilter(let viewModel):
            FeedModalHeaderView(title: viewModel.title, onClose: viewModel.onCloseTap)
        }
    }

    @ViewBuilder
    private func modalContent(for modal: FeedModal) -> some View {
        switch modal {
        case .pulseTagFilter(let viewModel):
            PulseTagFilterBottomSheetView(viewModel: viewModel)
        case .marketCapInfo(let viewModel):
            MarketCapInfoBottomSheetView(viewModel: viewModel)
        case .realAssetsCategoryFilter(let viewModel):
            MarketsRealAssetsFilterContentView(viewModel: viewModel)
                .padding(.horizontal, Constants.horizontalPadding)
        case .earnNetworkFilter(let viewModel):
            EarnNetworkFilterContentView(viewModel: viewModel)
                .padding(.horizontal, Constants.horizontalPadding)
        case .earnTypeFilter(let viewModel):
            EarnTypeFilterContentView(viewModel: viewModel)
                .padding(.horizontal, Constants.horizontalPadding)
                .padding(.bottom, Constants.bottomPadding)
        }
    }

    @ViewBuilder
    private func footer(for modal: FeedModal) -> some View {
        switch modal {
        case .pulseTagFilter(let viewModel):
            PulseTagFilterFooterView(viewModel: viewModel)
        case .marketCapInfo, .earnTypeFilter:
            EmptyView()
        case .realAssetsCategoryFilter(let viewModel):
            MarketsRealAssetsFilterFooterView(viewModel: viewModel)
        case .earnNetworkFilter(let viewModel):
            EarnNetworkFilterFooterView(viewModel: viewModel)
        }
    }
}

private extension FeedModalPresentation {
    enum Constants {
        static let horizontalPadding: CGFloat = 16
        static let bottomPadding: CGFloat = 16
    }
}

// MARK: - Header

struct FeedModalHeaderView: View {
    let title: String?
    let onClose: () -> Void

    @ScaledMetric private var closeButtonSide: CGFloat = 44
    @ScaledMetric private var horizontalPadding: CGFloat = 16
    @ScaledMetric private var verticalPadding: CGFloat = 12

    var body: some View {
        HStack(spacing: .zero) {
            Color.clear
                .frame(width: closeButtonSide, height: closeButtonSide)

            Text(title ?? "")
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                .lineLimit(1)
                .frame(maxWidth: .infinity)

            FeedModalCloseButton(action: onClose)
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
    }
}

struct FeedModalCloseButton: View {
    let action: () -> Void

    var body: some View {
        TangemUI.Button(
            icon: DesignSystem.Icons.Cross.regular20,
            accessibilityLabel: Localization.commonClose,
            action: action
        )
        .size(.x11)
        .styleType(.material(.glass))
    }
}
