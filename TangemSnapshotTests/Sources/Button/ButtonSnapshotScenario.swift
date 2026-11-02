//
//  ButtonSnapshotScenario.swift
//  TangemSnapshotTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemSnapshotTestSupport
import TangemUI

enum ButtonSnapshotScenario: String, SnapshotScenario {
    case styles
    case sizes
    case horizontalLayouts
    case contentRTL
    case contentLargeText

    var canvases: [SnapshotCanvas] {
        self == .horizontalLayouts ? [.fixed(width: 320, height: 112)] : [.component]
    }

    var layoutDirection: LayoutDirection {
        self == .contentRTL ? .rightToLeft : .leftToRight
    }

    var dynamicTypeSize: DynamicTypeSize {
        self == .contentLargeText ? .accessibility2 : .large
    }

    @MainActor
    @ViewBuilder
    var body: some View {
        switch self {
        case .styles:
            SnapshotGrid(styleCases, columns: 2) { sample in
                styleSample(sample.style, isEnabled: sample.isEnabled)
            }
        case .sizes:
            SnapshotGrid(sizeCases, columns: ContentSample.allCases.count) { sample in
                button(sample.content, size: sample.size)
            }
        case .horizontalLayouts:
            VStack(spacing: 16) {
                ForEach(TangemUI.Button.HorizontalLayout.allCases, id: \.self) { layout in
                    button(.bothIcons).horizontalLayout(layout)
                }
            }
            .padding(8)
        case .contentRTL, .contentLargeText:
            SnapshotGrid(contentCases, columns: ContentSample.allCases.count) { sample in
                button(sample.content, size: sample.size)
            }
        }
    }
}

@MainActor
private extension ButtonSnapshotScenario {
    enum ContentSample: CaseIterable, Hashable {
        case label
        case iconStart
        case iconEnd
        case bothIcons
        case iconOnly
    }

    typealias StyleSample = (name: String, styleType: TangemUI.Button.StyleType)

    var styleSamples: [StyleSample] {
        [
            ("Brand", .brand),
            ("Primary", .primary),
            ("Secondary", .secondary(.default)),
            ("Secondary error", .secondary(.error)),
            ("Secondary info", .secondary(.info)),
            ("Glass", .material(.glass)),
            ("Blur", .material(.blur)),
            ("Outline", .outline),
            ("Ghost", .ghost),
            ("Success", .success),
        ]
    }

    var styleCases: [(style: StyleSample, isEnabled: Bool)] {
        styleSamples.flatMap { style in
            [true, false].map { (style, $0) }
        }
    }

    var sizeCases: [(size: TangemUI.Button.Size, content: ContentSample)] {
        TangemUI.Button.Size.allCases.flatMap { size in
            ContentSample.allCases.map { (size, $0) }
        }
    }

    var contentCases: [(size: TangemUI.Button.Size, content: ContentSample)] {
        [TangemUI.Button.Size.x14, .x10, .x7].flatMap { size in
            ContentSample.allCases.map { (size, $0) }
        }
    }

    func styleSample(_ style: StyleSample, isEnabled: Bool) -> some View {
        TangemUI.Button(label: style.name, accessibilityLabel: nil, action: {})
            .iconStart(icon(for: .x10))
            .styleType(style.styleType)
            .disabled(!isEnabled)
    }

    func button(_ content: ContentSample, size: TangemUI.Button.Size = .x10) -> TangemUI.Button {
        let label = TangemUI.Button(label: "Button", accessibilityLabel: nil, action: {}).size(size)

        return switch content {
        case .label:
            label
        case .iconStart:
            label.iconStart(icon(for: size))
        case .iconEnd:
            label.iconEnd(icon(for: size))
        case .bothIcons:
            label.iconStart(icon(for: size)).iconEnd(icon(for: size))
        case .iconOnly:
            TangemUI.Button(icon: icon(for: size), accessibilityLabel: nil, action: {}).size(size)
        }
    }

    func icon(for size: TangemUI.Button.Size) -> ImageType {
        switch size {
        case .x14, .x12: DesignSystem.Icons.SignUsd.regular24
        case .x11, .x10, .x9, .x8: DesignSystem.Icons.SignUsd.regular20
        case .x7: DesignSystem.Icons.SignUsd.regular16
        }
    }
}
