//
//  PolymarketFinishedPositionSheetView.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

public struct PolymarketFinishedPositionSheetView: View {
    private let model: Model

    public init(model: Model) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: Constants.blockSpacing) {
            Text(model.title)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                .lineLimit(1)
                .frame(height: Constants.toolbarHeight)

            PolymarketPositionHeader(model: model.header)

            PolymarketDetailsRowsBlock(rows: model.rows)
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.bottom, Constants.bottomPadding)
        .frame(maxWidth: .infinity)
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Model

public extension PolymarketFinishedPositionSheetView {
    struct Model: Identifiable {
        public let id: String
        public let title: String
        public let header: PolymarketPositionHeader.Model
        public let rows: [PolymarketDetailsRowsBlock.Row]

        public init(
            id: String,
            title: String,
            header: PolymarketPositionHeader.Model,
            rows: [PolymarketDetailsRowsBlock.Row]
        ) {
            self.id = id
            self.title = title
            self.header = header
            self.rows = rows
        }
    }
}

// MARK: - Constants

private extension PolymarketFinishedPositionSheetView {
    enum Constants {
        static let blockSpacing: CGFloat = 16
        static let horizontalPadding: CGFloat = 16
        static let toolbarHeight: CGFloat = 44
        static let bottomPadding: CGFloat = 24
    }
}
