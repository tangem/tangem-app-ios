//
//  Footer.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

public struct Footer: View, Setupable {
    let content: FooterContent
    private var caption: AttributedString?
    private var showsFade = false

    @Environment(\.footerHost) private var host
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    public init(_ content: FooterContent) {
        self.content = content
    }

    public var body: some View {
        stack
            .frame(maxWidth: .infinity)
            .background {
                if showsFade {
                    Fade(position: .bottom)
                        .variant(.hard)
                        .blurred(!reduceTransparency)
                        .backgroundColor(host.modalSurface ?? DesignSystem.Color.bgPrimary)
                        .padding(.top, -Metrics.fadeOverhang)
                        .ignoresSafeArea(edges: .bottom)
                }
            }
    }

    private var stack: some View {
        VStack(spacing: Metrics.contentSpacing) {
            if let caption {
                Text(caption)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .tint(DesignSystem.Color.textPrimary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }

            mainContent
        }
        .padding(.horizontal, Metrics.horizontalPadding)
        .padding(.vertical, Metrics.verticalPadding)
    }

    @ViewBuilder
    private var mainContent: some View {
        switch content.kind {
        case .buttons(let primary, let secondary):
            VStack(spacing: Metrics.buttonSpacing) {
                if let secondary {
                    secondary
                        .size(.x12)
                        .horizontalLayout(.infinity)
                }

                primary
                    .size(.x12)
                    .horizontalLayout(.infinity)
            }

        case .toolbar(let start, let end):
            HStack(spacing: 0) {
                start?.size(.x11)

                Spacer(minLength: Metrics.buttonSpacing)

                end?.size(.x11)
            }
            .padding(.horizontal, utilityBarPadding)

        case .search(let search):
            search
                .padding(.horizontal, utilityBarPadding)
        }
    }

    private var utilityBarPadding: CGFloat {
        host.isModal ? 0 : Metrics.utilityBarPadding
    }
}

// MARK: - Setupable

public extension Footer {
    func caption(_ text: AttributedString?) -> Self {
        map { $0.caption = text }
    }

    func showFade(_ isVisible: Bool = true) -> Self {
        map { $0.showsFade = isVisible }
    }
}

// MARK: - Metrics

private extension Footer {
    enum Metrics {
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 8
        static let contentSpacing: CGFloat = 12
        static let buttonSpacing: CGFloat = 8
        static let utilityBarPadding: CGFloat = 16
        static let fadeOverhang: CGFloat = 16
    }
}
