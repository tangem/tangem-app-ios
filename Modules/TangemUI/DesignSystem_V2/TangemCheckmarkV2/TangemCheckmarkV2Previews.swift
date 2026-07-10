//
//  TangemCheckmarkV2Previews.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

// MARK: - Showcase

public struct TangemCheckmarkV2Showcase: View {
    @State private var isOn: Bool = false
    @State private var isEnabled: Bool = true
    @State private var typeSize: DynamicTypeSize = .large
    @State private var isDarkMode: Bool = false

    public init() {}

    public var body: some View {
        VStack(spacing: 24) {
            preview
            controls
        }
        .padding()
    }

    private var preview: some View {
        TangemCheckmarkV2(isOn: $isOn)
            .accessibilityLabel("Showcase checkmark")
            .disabled(!isEnabled)
            .dynamicTypeSize(typeSize)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            .background(Color(uiColor: .systemBackground))
            .environment(\.colorScheme, isDarkMode ? .dark : .light)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16).stroke(.secondary.opacity(0.2))
            }
    }

    private var controls: some View {
        VStack(spacing: 16) {
            Toggle("Enabled", isOn: $isEnabled)
            Toggle("Dark mode", isOn: $isDarkMode)

            Picker("Dynamic Type", selection: $typeSize) {
                ForEach(DynamicTypeSize.allCases, id: \.self) { size in
                    Text(size.showcaseLabel).tag(size)
                }
            }
        }
    }
}

private extension DynamicTypeSize {
    var showcaseLabel: String {
        switch self {
        case .xSmall: "XS"
        case .small: "S"
        case .medium: "M"
        case .large: "L (default)"
        case .xLarge: "XL"
        case .xxLarge: "XXL"
        case .xxxLarge: "XXXL"
        case .accessibility1: "AX1"
        case .accessibility2: "AX2"
        case .accessibility3: "AX3"
        case .accessibility4: "AX4"
        case .accessibility5: "AX5"
        @unknown default: "?"
        }
    }
}

// MARK: - Previews

private struct CheckmarkMatrixView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach([true, false], id: \.self) { enabled in
                VStack(alignment: .leading, spacing: 12) {
                    Text(enabled ? "Enabled" : "Disabled")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 24) {
                        ForEach([false, true], id: \.self) { checked in
                            TangemCheckmarkV2(checked: checked) {}
                                .accessibilityLabel(checked ? "checked" : "unchecked")
                                .disabled(!enabled)
                        }
                    }
                }
            }
        }
        .padding()
    }
}

#Preview("Interactive Demo") {
    TangemCheckmarkV2Showcase()
}

#Preview("Matrix — Light") {
    CheckmarkMatrixView()
}

#Preview("Matrix — Dark") {
    CheckmarkMatrixView()
        .preferredColorScheme(.dark)
}
