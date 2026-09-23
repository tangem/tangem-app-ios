//
//  PolymarketChooseNetworkView.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

public struct PolymarketChooseNetworkView: View {
    private let rows: [PolymarketNetworkRowViewData]
    private let onClose: () -> Void

    public init(rows: [PolymarketNetworkRowViewData], onClose: @escaping () -> Void) {
        self.rows = rows
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: .zero) {
            header
                .padding(.horizontal, Constants.horizontalPadding)
                .padding(.bottom, Constants.headerBottomPadding)

            networks
                .padding(.bottom, Constants.headerBottomPadding)
        }
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackgroundColor = DesignSystem.Color.bgSecondary
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
    }
}

// MARK: - Private implementation

private extension PolymarketChooseNetworkView {
    var header: some View {
        BottomSheetHeaderView(title: Localization.commonChooseNetwork, trailing: {
            closeButton
        })
        .titleFont(DesignSystem.Font.bodyMediumToken.font)
        .titleColor(DesignSystem.Color.textPrimary)
    }

    var closeButton: some View {
        TangemUI.Button(
            icon: DesignSystem.Icons.Cross.regular20,
            accessibilityLabel: Localization.commonClose,
            action: onClose
        )
        .size(.x11)
        .styleType(.material(.glass))
    }

    var networks: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: .zero) {
                ForEach(rows) { row in
                    networkRow(row)
                }
            }
        }
    }

    func networkRow(_ row: PolymarketNetworkRowViewData) -> some View {
        Row(title: row.title, subtitle: row.subtitle)
            .titleLineLimit(1)
            .start {
                NetworkIcon(
                    imageAsset: row.icon,
                    isActive: false,
                    isMainIndicatorVisible: false,
                    size: CGSize(bothDimensions: Constants.iconSize)
                )
            }
            .onTap(row.action)
    }

    enum Constants {
        static let horizontalPadding: CGFloat = 16
        static let headerBottomPadding: CGFloat = 16
        static let iconSize: CGFloat = 36
    }
}
