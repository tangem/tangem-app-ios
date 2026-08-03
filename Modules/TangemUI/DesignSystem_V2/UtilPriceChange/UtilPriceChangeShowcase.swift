//
//  UtilPriceChangeShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

// MARK: - Showcase

public struct UtilPriceChangeShowcase: View {
    @State private var direction: UtilPriceChange.Direction = .positive
    @State private var value: String = "2.08%"
    @State private var isDarkMode = false
    @State private var dynamicTypeIndex: Int = Self.dynamicTypeAllCases.firstIndex(of: .large) ?? 0

    private static let dynamicTypeAllCases: [DynamicTypeSize] = Array(DynamicTypeSize.allCases)

    private var dynamicTypeSize: DynamicTypeSize {
        Self.dynamicTypeAllCases[dynamicTypeIndex]
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
        UtilPriceChange(value: value, direction: direction)
            .dynamicTypeSize(dynamicTypeSize)
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(DesignSystem.Color.bgSecondary)
    }

    private var controls: some View {
        ScrollView {
            VStack(spacing: 12) {
                Picker("Direction", selection: $direction) {
                    Text("positive").tag(UtilPriceChange.Direction.positive)
                    Text("neutral").tag(UtilPriceChange.Direction.neutral)
                    Text("negative").tag(UtilPriceChange.Direction.negative)
                }
                .pickerStyle(.segmented)

                HStack {
                    Text("value:").font(.caption)
                    TextField("Enter value", text: $value)
                        .textFieldStyle(.roundedBorder)
                }

                Toggle("Dark mode", isOn: $isDarkMode)

                Stepper(
                    "DT: \(String(describing: dynamicTypeSize))",
                    value: $dynamicTypeIndex,
                    in: 0 ... (Self.dynamicTypeAllCases.count - 1)
                )
            }
            .padding()
        }
    }
}
