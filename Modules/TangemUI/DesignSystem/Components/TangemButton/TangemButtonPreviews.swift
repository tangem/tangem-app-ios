//
//  TangemButtonPreviews.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

// MARK: - Showcase

public struct TangemButtonShowcase: View {
    @State private var cornerStyle: TangemButton.CornerStyle = .rectangular
    @State private var styleType: TangemButton.StyleType = .accent
    @State private var buttonState: TangemButton.ButtonState = .normal
    @State private var content: TangemButton.Content = .text("Button")
    @State private var horLayout: TangemButton.HorizontalLayout = .intrinsic
    @State private var size: TangemButton.Size = .x12

    private let cornerStyles: [TangemButton.CornerStyle] = [
        .rectangular,
        .rounded,
    ]

    private let styleTypes: [TangemButton.StyleType] = [
        .accent,
        .primary,
        .secondary,
        .outline,
        .ghost,
        .primaryInverse,
        .positive,
    ]

    private let buttonStates: [TangemButton.ButtonState] = [
        .normal,
        .disabled,
        .loading,
    ]

    private let horizontalLayouts: [TangemButton.HorizontalLayout] = [
        .intrinsic,
        .infinity,
    ]

    private let sizes: [TangemButton.Size] = [
        .x15,
        .x12,
        .x10,
        .x9,
        .x8,
        .x7,
    ]

    private let contents: [TangemButton.Content] = [
        .text("Button"),
        .icon(Assets.crossedEyeIcon),
        .combined(text: "Button", icon: Assets.crossedEyeIcon, iconPosition: .left),
        .combined(text: "Button", icon: Assets.crossedEyeIcon, iconPosition: .right),
        .text("Button alskjdhlkaujshdlagsdhaiusjcklsxcbvhjksfdskagfgasjkhdfajksdfhjkasfasdfkasdfl;a"),
    ]

    public init() {}

    public var body: some View {
        VStack(spacing: 8) {
            pickerView(
                contents: ["rectangular", "rounded"],
                selection: .init(
                    get: { cornerStyles.firstIndex(of: cornerStyle) ?? 0 },
                    set: { cornerStyle = cornerStyles[$0] }
                )
            )

            pickerView(
                contents: ["accent", "primary", "secondary", "outline", "ghost", "primaryInverse", "positive"],
                selection: .init(
                    get: { styleTypes.firstIndex(of: styleType) ?? 0 },
                    set: { styleType = styleTypes[$0] }
                )
            )

            pickerView(
                contents: ["normal", "disabled", "loading"],
                selection: .init(
                    get: { buttonStates.firstIndex(of: buttonState) ?? 0 },
                    set: { buttonState = buttonStates[$0] }
                )
            )

            pickerView(
                contents: ["intrinsic", "infinity"],
                selection: .init(
                    get: { horizontalLayouts.firstIndex(of: horLayout) ?? 0 },
                    set: { horLayout = horizontalLayouts[$0] }
                )
            )

            pickerView(
                contents: ["x15", "x12", "x10", "x9", "x8", "x7"],
                selection: .init(
                    get: { sizes.firstIndex(of: size) ?? 0 },
                    set: { size = sizes[$0] }
                )
            )

            pickerView(
                contents: ["text", "icon", "combinedLeft", "combinedRight", "gigaText"],
                selection: .init(
                    get: { contents.firstIndex(of: content) ?? 0 },
                    set: { content = contents[$0] }
                )
            )

            TangemButton(
                content: content,
                action: { print("action") }
            )
            .setButtonState(
                isLoading: buttonState.isLoading,
                isDisabled: buttonState.isDisabled
            )
            .setSize(size)
            .setStyleType(styleType)
            .setCornerStyle(cornerStyle)
            .setHorizontalLayout(horLayout)
        }
        .padding()
    }

    private func pickerView(contents: [String], selection: Binding<Int>) -> some View {
        Picker("", selection: selection) {
            ForEach(0 ..< contents.count, id: \.self) {
                Text(contents[$0]).tag($0)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    TangemButtonShowcase()
}

#endif // DEBUG
