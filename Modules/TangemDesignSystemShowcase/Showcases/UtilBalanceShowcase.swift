//
//  UtilBalanceShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG
import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct UtilBalanceShowcase: View {
    @State private var value = "$12,000.00"
    @State private var isMasked = false
    @State private var isUpdating = false
    @State private var dimsDecimals = false
    @State private var style: StyleKind = .body
    @State private var lineLimit = 1
    @State private var frameWidth: CGFloat = 200

    var body: some View {
        DSShowcase("UtilBalance") { controls in
            controls.picker("Style", $style)
            controls.text("Value", $value)
            controls.toggle("Dimmed decimals", $dimsDecimals)
            controls.toggle("Masked", $isMasked)
            controls.toggle("Updating", $isUpdating)
            controls.value("Line limit", $lineLimit, in: 1 ... 4)
            controls.value("Frame width", $frameWidth, in: 80 ... 360, step: 1)
        } stage: {
            UtilBalance(balanceValue(value, dimsDecimals: dimsDecimals))
                .masked(isMasked)
                .updating(isUpdating)
                .lineLimit(lineLimit)
                .style(style.token, color: style.color)
                .frame(width: frameWidth)
        } matrix: {
            DSShowcaseMatrix(rows: StateKind.allCases, columns: StyleKind.allCases) { state, style in
                UtilBalance(balanceValue("$12,480.35", dimsDecimals: state == .dimmedDecimals))
                    .masked(state == .masked)
                    .updating(state == .updating)
                    .style(style.token, color: style.color)
            }
        }
    }

    private func balanceValue(_ value: String, dimsDecimals: Bool) -> UtilBalance.Value {
        dimsDecimals ? .attributed(AttributedBalanceFormatter.dimmingDecimals(value)) : .string(value)
    }
}

private extension UtilBalanceShowcase {
    enum StyleKind: CaseIterable {
        case body
        case subheading
        case display

        var token: TangemTypographyToken {
            switch self {
            case .body: DesignSystem.Font.bodyMediumToken
            case .subheading: DesignSystem.Font.subheadingMediumToken
            case .display: DesignSystem.Font.displayMediumToken
            }
        }

        var color: Color {
            switch self {
            case .body: DesignSystem.Color.textPrimary
            case .subheading: DesignSystem.Color.textSecondary
            case .display: DesignSystem.Color.textStatusSuccess
            }
        }
    }

    enum StateKind: CaseIterable {
        case plain
        case dimmedDecimals
        case masked
        case updating
    }
}
#endif
