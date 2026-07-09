//
//  TangemMessageBubblePreviews.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

// MARK: - Showcase

public struct TangemMessageBubbleShowcase: View {
    @State private var variant: TangemMessageBubble.Variant = .success
    @State private var text: String = "Description"
    @State private var hasIcon = true
    @State private var isDarkMode = false
    @State private var frameWidth: CGFloat = 200
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
        bubble
            .frame(width: frameWidth)
            .dynamicTypeSize(dynamicTypeSize)
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .background(DesignSystem.Color.bgSecondary)
    }

    @ViewBuilder
    private var bubble: some View {
        TangemMessageBubble(text: text, onClose: {})
            .variant(variant)
            .icon(hasIcon ? DesignSystem.Icons.ChartLineVertical.regular16 : nil)
    }

    private var controls: some View {
        ScrollView {
            VStack(spacing: 12) {
                Picker("Variant", selection: $variant) {
                    Text("neutral").tag(TangemMessageBubble.Variant.neutral)
                    Text("success").tag(TangemMessageBubble.Variant.success)
                    Text("info").tag(TangemMessageBubble.Variant.info)
                }
                .pickerStyle(.segmented)

                HStack {
                    Text("text:").font(.caption)
                    TextField("Enter description", text: $text)
                        .textFieldStyle(.roundedBorder)
                }

                Toggle("Icon", isOn: $hasIcon)
                Toggle("Dark mode", isOn: $isDarkMode)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Frame width: \(Int(frameWidth))").font(.caption)
                    Slider(value: $frameWidth, in: 80 ... 360, step: 1)
                }

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

// MARK: - Previews

#if DEBUG

private struct MessageBubbleGalleryView: View {
    private let variants: [TangemMessageBubble.Variant] = [.neutral, .success, .info]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(variants, id: \.self) { variant in
                VStack(alignment: .leading, spacing: 8) {
                    Text(name(variant))
                        .foregroundStyle(DesignSystem.Color.textPrimary)

                    TangemMessageBubble(text: "Description", onClose: {})
                        .variant(variant)
                        .icon(DesignSystem.Icons.ChartLineVertical.regular16)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DesignSystem.Color.bgPrimary)
    }

    private func name(_ variant: TangemMessageBubble.Variant) -> String {
        switch variant {
        case .neutral: "Neutral"
        case .success: "Success"
        case .info: "Info"
        }
    }
}

#Preview("Gallery") {
    MessageBubbleGalleryView()
}

#Preview("Gallery — Dark") {
    MessageBubbleGalleryView()
        .preferredColorScheme(.dark)
}

@available(iOS 17.0, *)
#Preview("Showcase") {
    TangemMessageBubbleShowcase()
}

#endif // DEBUG
