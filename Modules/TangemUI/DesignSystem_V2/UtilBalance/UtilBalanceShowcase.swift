//
//  UtilBalanceShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

// MARK: - Showcase

public struct UtilBalanceShowcase: View {
    @State private var value: String = "$12,000.00"
    @State private var isMasked = false
    @State private var isUpdating = false
    @State private var isDarkMode = false
    @State private var dimsDecimals = false
    @State private var styleIndex: Int = 0
    @State private var lineLimit: Int = 1
    @State private var frameWidth: CGFloat = 200

    private static let styles: [(name: String, token: TangemTypographyToken, color: Color)] = [
        ("body", DesignSystem.Font.bodyMediumToken, DesignSystem.Color.textPrimary),
        ("subheading", DesignSystem.Font.subheadingMediumToken, DesignSystem.Color.textSecondary),
        ("display", DesignSystem.Font.displayMediumToken, DesignSystem.Color.textStatusSuccess),
    ]

    private var style: (name: String, token: TangemTypographyToken, color: Color) {
        Self.styles[styleIndex]
    }

    private var balanceValue: UtilBalance.Value {
        dimsDecimals ? .attributed(AttributedBalanceFormatter.dimmingDecimals(value)) : .string(value)
    }

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            previewArea
                .environment(\.colorScheme, isDarkMode ? .dark : .light)

            controls
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(DesignSystem.Color.bgPrimary)
    }

    private var previewArea: some View {
        UtilBalance(balanceValue)
            .masked(isMasked)
            .updating(isUpdating)
            .lineLimit(lineLimit)
            .style(style.token, color: style.color)
            .frame(width: frameWidth)
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .background(DesignSystem.Color.bgSecondary)
    }

    private var controls: some View {
        ScrollView {
            VStack(spacing: 12) {
                Picker("Style", selection: $styleIndex) {
                    ForEach(Self.styles.indices, id: \.self) { index in
                        Text(Self.styles[index].name).tag(index)
                    }
                }
                .pickerStyle(.segmented)

                HStack {
                    Text("value:").font(.caption)
                    TextField("Enter balance", text: $value)
                        .textFieldStyle(.roundedBorder)
                }

                Toggle("Dimmed decimals", isOn: $dimsDecimals)
                Toggle("Masked", isOn: $isMasked)
                Toggle("Updating", isOn: $isUpdating)
                Toggle("Dark mode", isOn: $isDarkMode)

                Stepper("lineLimit: \(lineLimit)", value: $lineLimit, in: 1 ... 4)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Frame width: \(Int(frameWidth))").font(.caption)
                    Slider(value: $frameWidth, in: 80 ... 360, step: 1)
                }
            }
            .padding()
        }
    }
}
