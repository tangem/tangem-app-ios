//
//  TangemButtonPreviews.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

#if DEBUG
private typealias _Button = TangemButton

struct PickerView: View {
    let contents: [String]
    @Binding var selection: Int

    var body: some View {
        Picker("", selection: $selection) {
            ForEach(0 ..< contents.count, id: \.self) {
                Text(contents[$0]).tag($0)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }
}

private struct ButtonComponentDemoView: View {
    @State private var cornerStyle: _Button.CornerStyle = .default
    @State private var styleType: _Button.StyleType = .accent
    @State private var buttonState: _Button.ButtonState = .normal
    @State private var content: _Button.Content = .text("Button")
    @State private var horLayout: _Button.HorizontalLayout = .intrinsic
    @State private var size: _Button.Size = .x12

    let cornerStyles: [_Button.CornerStyle] = [
        .default,
        .rounded,
    ]

    let styleTypes: [_Button.StyleType] = [
        .accent,
        .primary,
        .secondary,
        .outline,
        .ghost,
        .primaryInverse,
        .positive,
    ]

    let buttonStates: [_Button.ButtonState] = [
        .normal,
        .disabled,
        .loading,
    ]

    let horizontalLayouts: [_Button.HorizontalLayout] = [
        .intrinsic,
        .infinity,
    ]

    let sizes: [_Button.Size] = [
        .x15,
        .x12,
        .x10,
        .x9,
        .x8,
        .x7,
    ]

    let contents: [_Button.Content] = [
        .text("Button"),
        .icon(demoIcon),
        .combined(text: "Button", icon: demoIcon, iconPosition: .left),
        .combined(text: "Button", icon: demoIcon, iconPosition: .right),
        .text("Button alskjdhlkaujshdlagsdhaiusjcklsxcbvhjksfdskagfgasjkhdfajksdfhjkasfasdfkasdfl;a"),
    ]

    var body: some View {
        VStack(spacing: 8) {
            PickerView(contents: [
                "default",
                "rounded",
            ], selection: .init(get: {
                cornerStyles.firstIndex(of: cornerStyle)!
            }, set: { index in
                cornerStyle = cornerStyles[index]
            }))

            PickerView(contents: [
                "accent",
                "primary",
                "secondary",
                "outline",
                "ghost",
                "primaryInverse",
                "positive",
            ], selection: .init(get: {
                styleTypes.firstIndex(of: styleType)!
            }, set: { index in
                styleType = styleTypes[index]
            }))

            PickerView(contents: [
                "normal",
                "disabled",
                "loading",
            ], selection: .init(get: {
                buttonStates.firstIndex(of: buttonState)!
            }, set: { index in
                buttonState = buttonStates[index]
            }))

            PickerView(contents: [
                "intrinsic",
                "infinity",
            ], selection: .init(get: {
                horizontalLayouts.firstIndex(of: horLayout)!
            }, set: { index in
                horLayout = horizontalLayouts[index]
            }))

            PickerView(contents: [
                "x15",
                "x12",
                "x10",
                "x9",
                "x8",
                "x7",
            ], selection: .init(get: {
                sizes.firstIndex(of: size)!
            }, set: { index in
                size = sizes[index]
            }))

            PickerView(contents: [
                "text",
                "icon",
                "combinedLeft",
                "combinedRight",
                "gigaText",
            ], selection: .init(get: {
                contents.firstIndex(of: content)!
            }, set: { index in
                content = contents[index]
            }))

            _Button(
                content: content,
                buttonState: buttonState,
                size: size,
                horizontalLayout: horLayout,
                cornerStyle: cornerStyle,
                styleType: styleType,
                action: { print("action") }
            )
        }
        .padding()
    }
}

private let demoIcon = Assets.crossedEyeIcon.image

#Preview {
    VStack(spacing: 8) {
        ButtonComponentDemoView()
    }
    .padding()
}
#endif
