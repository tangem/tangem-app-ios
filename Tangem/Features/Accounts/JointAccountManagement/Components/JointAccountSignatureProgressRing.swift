//
//  JointAccountSignatureProgressRing.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUIUtils

/// How close a joint account operation is to the signatures it needs: one segment per signature it takes, filled
/// for each one collected.
struct JointAccountSignatureProgressRing: View {
    /// Includes the initiator's own signature, so a fresh operation already reads `1/3`.
    let collectedCount: Int
    let requiredCount: Int

    var diameter: CGFloat = JointAccountSignatureProgressRingMetrics.diameter

    var body: some View {
        ZStack {
            ForEach(0 ..< max(requiredCount, 0), id: \.self) { index in
                segment(at: index)
            }

            Text("\(clampedCount)/\(requiredCount)")
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textStatusWarning)
                .lineLimit(1)
        }
        .frame(width: diameter, height: diameter)
        .animation(.easeInOut, value: clampedCount)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Localization.jointOperationSignaturesProgress(clampedCount, requiredCount))
    }

    private func segment(at index: Int) -> some View {
        let share = 1 / CGFloat(max(requiredCount, 1))
        let gap = Metrics.gapDegrees / 360

        return Circle()
            .trim(from: CGFloat(index) * share + gap / 2, to: CGFloat(index + 1) * share - gap / 2)
            .stroke(
                index < clampedCount ? DesignSystem.Color.iconStatusWarning : DesignSystem.Color.bgTransparentSecondary,
                style: StrokeStyle(lineWidth: Metrics.lineWidth, lineCap: .round, lineJoin: .round)
            )
            // The trim starts at three o'clock, and the stroke is centred on the path
            .rotationEffect(.degrees(-90))
            .padding(Metrics.lineWidth / 2)
    }

    /// A late signature would otherwise fill more segments than the ring has.
    private var clampedCount: Int {
        min(max(collectedCount, 0), max(requiredCount, 0))
    }
}

// MARK: - Metrics

enum JointAccountSignatureProgressRingMetrics {
    static let diameter: CGFloat = 40
    static let lineWidth: CGFloat = 2.5
    /// The same for every step count the design defines.
    static let gapDegrees: CGFloat = 18
}

private extension JointAccountSignatureProgressRing {
    typealias Metrics = JointAccountSignatureProgressRingMetrics
}

// MARK: - Previews

#Preview {
    VStack(spacing: 20) {
        ForEach(2 ... 5, id: \.self) { required in
            HStack(spacing: 16) {
                ForEach(0 ... required, id: \.self) { collected in
                    JointAccountSignatureProgressRing(collectedCount: collected, requiredCount: required)
                }
            }
        }
    }
    .padding(24)
    .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
}
