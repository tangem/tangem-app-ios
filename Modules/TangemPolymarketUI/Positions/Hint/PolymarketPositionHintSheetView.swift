//
//  PolymarketPositionHintSheetView.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

public struct PolymarketPositionHintSheetView: View {
    private let model: Model

    public init(model: Model) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: 0) {
            Text(model.title)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                .lineLimit(1)
                .frame(height: Constants.toolbarHeight)
                .padding(.top, Constants.titleTopPadding)

            Text(model.message)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, Constants.messageTopPadding)
                .padding(.bottom, Constants.messageBottomPadding)
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .frame(maxWidth: .infinity)
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Model

public extension PolymarketPositionHintSheetView {
    struct Model: Identifiable, Hashable {
        public let id: String
        public let title: String
        public let message: String

        public init(id: String, title: String, message: String) {
            self.id = id
            self.title = title
            self.message = message
        }
    }
}

// MARK: - Constants

private extension PolymarketPositionHintSheetView {
    enum Constants {
        static let toolbarHeight: CGFloat = 44
        static let titleTopPadding: CGFloat = 16
        static let horizontalPadding: CGFloat = 16
        static let messageTopPadding: CGFloat = 16
        static let messageBottomPadding: CGFloat = 32
    }
}

// MARK: - Previews

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            PolymarketPositionHintSheetView(model: .init(
                id: "unrealized",
                title: "Unrealized PnL",
                message: "Your theoretical profit or loss if you were to close position at current price. Moves dynamically until you sell or the event resolves."
            ))
            .presentationDetents([.height(200)])
        }
}
