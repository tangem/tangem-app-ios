//
//  TangemButtonShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG
import SwiftUI
import TangemAssets
import TangemUI

struct TangemButtonShowcase: View {
    @State private var cornerStyle: TangemButton.CornerStyle = .rectangular
    @State private var styleType: TangemButton.StyleType = .accent
    @State private var buttonState: TangemButton.ButtonState = .normal
    @State private var contentKind: ContentKind = .text
    @State private var horizontalLayout: TangemButton.HorizontalLayout = .intrinsic
    @State private var size: TangemButton.Size = .x12
    @State private var tapCount = 0

    var body: some View {
        DSShowcase("TangemButton") { controls in
            controls.picker("Style", $styleType, options: Self.styleTypes)
            controls.picker("State", $buttonState, options: Self.buttonStates)
            controls.picker("Size", $size, options: Self.sizes)
            controls.picker("Content", $contentKind)
            controls.picker("Corner style", $cornerStyle, options: Self.cornerStyles)
            controls.picker("Horizontal layout", $horizontalLayout, options: Self.horizontalLayouts)
            controls.readout("Taps", "\(tapCount)")
        } stage: {
            button(content: contentKind.content, styleType: styleType, state: buttonState, size: size)
                .setCornerStyle(cornerStyle)
                .setHorizontalLayout(horizontalLayout)
        } matrix: {
            DSShowcaseGroup("Style × State") {
                DSShowcaseMatrix(rows: Self.styleTypes, columns: Self.buttonStates) { styleType, state in
                    button(content: ContentKind.text.content, styleType: styleType, state: state, size: .x10)
                }
            }

            DSShowcaseGroup("Size × Content") {
                DSShowcaseMatrix(rows: Self.sizes, columns: ContentKind.compactCases) { size, kind in
                    button(content: kind.content, styleType: .accent, state: .normal, size: size)
                }
            }

            DSShowcaseGroup("Corner style") {
                DSShowcaseMatrix(rows: Self.cornerStyles) { cornerStyle in
                    button(content: ContentKind.text.content, styleType: .primary, state: .normal, size: .x10)
                        .setCornerStyle(cornerStyle)
                }
            }
        }
    }

    private func button(
        content: TangemButton.Content,
        styleType: TangemButton.StyleType,
        state: TangemButton.ButtonState,
        size: TangemButton.Size
    ) -> TangemButton {
        TangemButton(content: content, action: { tapCount += 1 })
            .setButtonState(isLoading: state.isLoading, isDisabled: state.isDisabled)
            .setSize(size)
            .setStyleType(styleType)
    }
}

private extension TangemButtonShowcase {
    static var cornerStyles: [TangemButton.CornerStyle] { [.rectangular, .rounded] }
    static var styleTypes: [TangemButton.StyleType] { [.accent, .primary, .secondary, .outline, .ghost, .primaryInverse, .positive] }
    static var buttonStates: [TangemButton.ButtonState] { [.normal, .disabled, .loading] }
    static var horizontalLayouts: [TangemButton.HorizontalLayout] { [.intrinsic, .infinity] }
    static var sizes: [TangemButton.Size] { [.x15, .x12, .x11, .x10, .x9, .x8, .x7] }

    enum ContentKind: CaseIterable {
        case text
        case icon
        case iconLeading
        case iconTrailing
        case longText

        static var compactCases: [ContentKind] { [.text, .icon, .iconLeading, .iconTrailing] }

        var content: TangemButton.Content {
            switch self {
            case .text:
                .text(AttributedString("Send"))
            case .icon:
                .icon(Assets.DesignSystem.eyeClose)
            case .iconLeading:
                .combined(text: AttributedString("Hide balance"), icon: Assets.DesignSystem.eyeClose, iconPosition: .left)
            case .iconTrailing:
                .combined(text: AttributedString("Hide balance"), icon: Assets.DesignSystem.eyeClose, iconPosition: .right)
            case .longText:
                .text(AttributedString("Confirm and send 0.004512 BTC to bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh"))
            }
        }
    }
}
#endif
