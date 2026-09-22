//
//  PredictionsFeedView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct PredictionsFeedView: View {
    var body: some View {
        VStack(spacing: 4) {
            ForEach(0 ..< Constants.rowCount, id: \.self) { _ in
                row
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var row: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(DesignSystem.Color.bgTertiary)
                .frame(size: Constants.iconSize)

            VStack(alignment: .leading, spacing: 6) {
                bar(width: Constants.titleBarWidth)
                bar(width: Constants.subtitleBarWidth)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
    }

    private func bar(width: CGFloat) -> some View {
        Capsule()
            .fill(DesignSystem.Color.bgTertiary)
            .frame(width: width, height: Constants.barHeight)
    }
}

// MARK: - Constants

private extension PredictionsFeedView {
    enum Constants {
        static let rowCount = 8
        static let iconSize = CGSize(bothDimensions: 40)
        static let titleBarWidth: CGFloat = 140
        static let subtitleBarWidth: CGFloat = 80
        static let barHeight: CGFloat = 12
    }
}
