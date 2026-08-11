//
//  TangemMessageBannerDemo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

final class TangemMessageBannerDemoViewModel: ObservableObject, Identifiable {}

struct TangemMessageBannerDemoView: View {
    @ObservedObject var viewModel: TangemMessageBannerDemoViewModel

    @State private var section: DemoSection = .showcase

    private enum DemoSection: String, CaseIterable {
        case showcase = "Showcase"
        case tappable = "Tappable"
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Section", selection: $section) {
                ForEach(DemoSection.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding()

            switch section {
            case .showcase:
                MessageBannerShowcase()
            case .tappable:
                tappableVariants
            }
        }
        .navigationBarTitle(Text("MessageBanner"))
    }

    private var tappableVariants: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(MessageBannerVariant.allCases, id: \.self) { variant in
                    MessageBanner(
                        title: "Tappable \(String(describing: variant))",
                        description: "Tap me — whole banner is the button"
                    )
                    .variant(variant)
                    .glowRing(demoRing(for: variant))
                    .onTap {}
                }

                MessageBanner(title: "Tappable, no glow ring", description: "Tap me")
                    .onTap {}

                MessageBanner(title: "Closable + tappable", description: "Tap body → onTap; ✕ → close")
                    .closeButton(accessibilityLabel: "Dismiss") {}
                    .onTap {}

                MessageBanner(title: "Buttons, not tappable", description: "Only the buttons act")
                    .secondaryButton(.init(title: "Later") {})
                    .primaryButton(.init(title: "Invite") {})
            }
            .padding()
        }
    }

    private func demoRing(for variant: MessageBannerVariant) -> GlowRingAppearance {
        switch variant {
        case .default, .solid: .magic
        case .success: .success
        case .error: .error
        case .warning: .warning
        case .info: .info
        }
    }
}
