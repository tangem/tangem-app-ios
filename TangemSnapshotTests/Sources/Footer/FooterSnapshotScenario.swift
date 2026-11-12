//
//  FooterSnapshotScenario.swift
//  TangemSnapshotTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemSnapshotTestSupport
import TangemUI
import TangemUIUtils

enum FooterSnapshotScenario: String, SnapshotScenario {
    case buttons
    case buttonsHorizontal
    case toolbar
    case search
    case signingButton
    case fade
    case fadeReduceTransparency

    var canvases: [SnapshotCanvas] {
        switch self {
        case .buttons: [.fixed(width: 402, height: 420)]
        case .buttonsHorizontal: [.fixed(width: 402, height: 180)]
        case .toolbar: [.fixed(width: 402, height: 240)]
        case .search: [.fixed(width: 402, height: 72)]
        case .signingButton: [.fixed(width: 402, height: 152)]
        case .fade, .fadeReduceTransparency: [.fixed(width: 402, height: 240)]
        }
    }

    var reduceTransparency: Bool {
        self == .fadeReduceTransparency
    }

    @MainActor
    @ViewBuilder
    var body: some View {
        switch self {
        case .buttons:
            samples([
                Footer(.buttons(primary: button("Continue"))),
                Footer(.buttons(primary: button("Continue"), secondary: secondaryButton("Cancel"))),
                Footer(.buttons(primary: button("Continue"), secondary: secondaryButton("Cancel")))
                    .caption(caption),
            ])
        case .buttonsHorizontal:
            samples([
                Footer(.buttons(primary: button("Continue"), secondary: secondaryButton("Cancel"), orientation: .horizontal)),
                Footer(.buttons(primary: button("Continue"), secondary: secondaryButton("Cancel"), orientation: .horizontal))
                    .caption(caption),
            ])
        case .toolbar:
            samples([
                Footer(.toolbar(start: toolbarButton(DesignSystem.Icons.Cross.regular24), end: toolbarButton(DesignSystem.Icons.ChevronDown.regular24))),
                Footer(.toolbar(start: toolbarButton(DesignSystem.Icons.Cross.regular24))),
                Footer(.toolbar(end: toolbarButton(DesignSystem.Icons.ChevronDown.regular24))),
            ])
        case .search:
            samples([
                Footer(.search(Search(text: .constant("")).placeholder("Search"))),
            ])
        case .signingButton:
            samples([
                Footer(.signingButton(SigningActionButtonView(type: .requiredNFCInteraction, title: "Sign", isLoading: false, isDisabled: false, action: {}))),
                Footer(.signingButton(SigningActionButtonView(type: .holdToConfirm, title: "Hold to sign", isLoading: false, isDisabled: false, action: {}))),
            ])
        case .fade, .fadeReduceTransparency:
            stripedContent
                .overlay(alignment: .bottom) {
                    Footer(.buttons(primary: button("Continue"))).showFade()
                }
        }
    }
}

@MainActor
private extension FooterSnapshotScenario {
    var caption: AttributedString {
        AttributedString("By continuing you accept the Terms of Service")
    }

    func samples(_ footers: [Footer]) -> some View {
        VStack(spacing: 16) {
            ForEach(footers.indices, id: \.self) { index in
                footers[index]
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    func button(_ label: String) -> TangemUI.Button {
        TangemUI.Button(label: label, accessibilityLabel: nil, action: {})
    }

    func secondaryButton(_ label: String) -> TangemUI.Button {
        button(label).styleType(.secondary(.default))
    }

    func toolbarButton(_ icon: ImageType) -> TangemUI.Button {
        TangemUI.Button(icon: icon, accessibilityLabel: nil, action: {}).styleType(.material(.glass))
    }

    var stripedContent: some View {
        VStack(spacing: 0) {
            ForEach(1 ... 8, id: \.self) { index in
                Text("Row \(index)")
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: 30)
                    .background(index.isMultiple(of: 2) ? DesignSystem.Color.bgSecondary : DesignSystem.Color.bgInverse.opacity(0.1))
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
}
