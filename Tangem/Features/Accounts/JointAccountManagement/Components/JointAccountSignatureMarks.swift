//
//  JointAccountSignatureMarks.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemFoundation
import TangemUI

/// One mark per signature a joint operation needs, filled for each one it has collected.
///
/// The marks overlap like a stack of faces, so a threshold of five takes barely more room than a threshold of two and
/// the row it sits in keeps its shape.
struct JointAccountSignatureMarks: View {
    /// Includes the initiator's own signature, so an operation that exists never shows an empty row.
    let collectedCount: Int
    /// The signatures the operation needs to go through, not every member of the account.
    let requiredCount: Int

    @ScaledMetric private var markSide: CGFloat = Constants.markSide
    @ScaledMetric private var markOverlap: CGFloat = Constants.markOverlap
    @ScaledMetric private var cutoutGap: CGFloat = Constants.cutoutGap
    @ScaledMetric private var checkmarkSide: CGFloat = Constants.checkmarkSide

    private var total: Int { min(max(requiredCount, 1), Constants.maximumMarks) }
    private var collected: Int { min(max(collectedCount, 0), total) }

    var body: some View {
        HStack(spacing: -markOverlap) {
            ForEach(0 ..< total, id: \.self) { index in
                mark(isCollected: index < collected, hasCutout: index > 0)
                    // The leading mark sits on top, so each one is bitten into by the mark in front of it
                    .zIndex(Double(total - index))
            }
        }
    }

    private func mark(isCollected: Bool, hasCutout: Bool) -> some View {
        markFill(isCollected: isCollected)
            .overlay {
                // Every mark but the leading one is partly covered, and a row of clipped checkmarks reads worse
                // than a plain fill — so only the front one carries it
                if isCollected, !hasCutout {
                    DesignSystem.Icons.Checkmark.regular20.image
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: checkmarkSide, height: checkmarkSide)
                        .foregroundStyle(DesignSystem.Color.iconInverse)
                }
            }
            .frame(width: markSide, height: markSide)
            .mask { markShape(hasCutout: hasCutout) }
    }

    @ViewBuilder
    private func markFill(isCollected: Bool) -> some View {
        if isCollected {
            Circle()
                .fill(DesignSystem.Color.bgStatusWarning)
        } else {
            Circle()
                .fill(DesignSystem.Color.bgTransparentSecondary)
                .background(Circle().fill(DesignSystem.Color.bgStatusWarningSubtle))
        }
    }

    /// Bites a crescent out of the mark where the one in front of it overlaps, leaving a gap of whatever the row is
    /// painted with between them. Cutting the gap rather than stroking it keeps the marks the size the mockup gives
    /// them, and needs to know nothing about the background.
    private func markShape(hasCutout: Bool) -> some View {
        Canvas { context, size in
            context.fill(Path(ellipseIn: CGRect(origin: .zero, size: size)), with: .color(.black))

            guard hasCutout else {
                return
            }

            let radius = size.width / 2 + cutoutGap
            let center = CGPoint(x: markOverlap - size.width / 2, y: size.height / 2)
            let cutout = CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2,
                height: radius * 2
            )

            context.blendMode = .destinationOut
            context.fill(Path(ellipseIn: cutout), with: .color(.black))
        }
    }
}

// MARK: - Constants

private extension JointAccountSignatureMarks {
    enum Constants {
        static let markSide: CGFloat = 20
        /// Leaves the 8pt step between marks that the mockup spaces them by.
        static let markOverlap: CGFloat = 12
        static let cutoutGap: CGFloat = 2
        static let checkmarkSide: CGFloat = 16
        /// The mockup draws no more than five, which is also the largest account there is.
        static let maximumMarks = 5
    }
}

// MARK: - Previews

#Preview("Progress") {
    VStack(alignment: .leading, spacing: 20) {
        ForEach(0 ... 5, id: \.self) { collected in
            HStack(spacing: 16) {
                Text("\(collected) of 5")
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .frame(width: 60, alignment: .leading)

                JointAccountSignatureMarks(collectedCount: collected, requiredCount: 5)
            }
        }
    }
    .padding(20)
    .background(DesignSystem.Color.bgStatusWarningSubtle)
}

#Preview("Thresholds") {
    VStack(alignment: .leading, spacing: 20) {
        ForEach(2 ... 5, id: \.self) { required in
            HStack(spacing: 16) {
                Text("1 of \(required)")
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .frame(width: 60, alignment: .leading)

                JointAccountSignatureMarks(collectedCount: 1, requiredCount: required)
            }
        }
    }
    .padding(20)
    .background(DesignSystem.Color.bgStatusWarningSubtle)
}
