//
//  YieldFeeSection.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization
import TangemUIUtils

struct YieldFeeSection<LeadingTextAccesoryView: View>: View {
    let leadingTitle: String
    let state: LoadableTextView.State
    let footerText: String?
    let linkTitle: String?
    let url: URL?
    let isLinkActive: Bool
    let onLinkTapAction: (() -> Void)?
    let needsBackground: Bool
    let leadingTextAccesoryView: LeadingTextAccesoryView

    private var settings: Settings = .init()

    // MARK: - Init

    init(
        leadingTitle: String,
        state: LoadableTextView.State,
        footerText: String?,
        needsBackground: Bool = true,
        linkTitle: String? = nil,
        url: URL? = nil,
        isLinkActive: Bool = false,
        @ViewBuilder leadingTextAccesoryView: () -> LeadingTextAccesoryView = { EmptyView() },
        onLinkTapAction: (() -> Void)? = nil
    ) {
        self.leadingTitle = leadingTitle
        self.state = state
        self.footerText = footerText
        self.linkTitle = linkTitle
        self.url = url
        self.isLinkActive = isLinkActive
        self.onLinkTapAction = onLinkTapAction
        self.needsBackground = needsBackground
        self.leadingTextAccesoryView = leadingTextAccesoryView()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            LoadableFeeRowView(
                leadingTitle: leadingTitle,
                state: state, leadingTextColor: settings.leadingTextColor,
                trailingTextColor: settings.trailingTextColor,
                leadingTextAccesoryView: leadingTextAccesoryView
            )
            .padding(.horizontal, 4)
            .if(needsBackground) {
                $0.defaultRoundedBackground(with: Colors.Background.action, verticalPadding: 14)
            }

            if let footerText {
                FooterText(footerText: footerText, linkTitle: linkTitle, url: url, isLinkActive: isLinkActive, onLinkTapAction: onLinkTapAction)
                    .padding(.horizontal, 14)
            }
        }
    }
}

// MARK: - State

extension YieldFeeSection {
    enum State {
        case loading
        case loaded(fee: String)
        case error

        var isLoaded: Bool {
            if case .loaded = self {
                return true
            }

            return false
        }
    }
}

// MARK: - LoadableNetworkFeeRowView

extension YieldFeeSection {
    struct LoadableFeeRowView: View {
        let leadingTitle: String
        var state: LoadableTextView.State
        let leadingTextColor: Color
        let trailingTextColor: Color
        let leadingTextAccesoryView: LeadingTextAccesoryView

        init(
            leadingTitle: String,
            state: LoadableTextView.State,
            leadingTextColor: Color,
            trailingTextColor: Color,
            leadingTextAccesoryView: LeadingTextAccesoryView
        ) {
            self.leadingTitle = leadingTitle
            self.state = state
            self.trailingTextColor = trailingTextColor
            self.leadingTextColor = leadingTextColor
            self.leadingTextAccesoryView = leadingTextAccesoryView
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center) {
                    Text(leadingTitle)
                        .style(Fonts.Regular.subheadline, color: leadingTextColor)

                    Spacer()

                    HStack {
                        leadingTextAccesoryView

                        LoadableTextView(
                            state: state,
                            font: Fonts.Regular.subheadline,
                            textColor: trailingTextColor,
                            loaderSize: .init(width: 90, height: 20)
                        )
                    }
                }
            }
        }
    }
}

// MARK: - FooterText

extension YieldFeeSection {
    struct FooterText: View {
        let footerText: String
        let linkTitle: String?
        let url: URL?
        let isLinkActive: Bool
        let onLinkTapAction: (() -> Void)?

        var body: some View {
            let attr = makeFeePolicyAttributedString()

            return Text(attr)
                .environment(\.openURL, OpenURLAction { _ in
                    if let onLinkTapAction, isLinkActive {
                        onLinkTapAction()
                        return .handled
                    }

                    return .systemAction
                })
        }

        func makeFeePolicyAttributedString() -> AttributedString {
            var fullText: String

            if let linkTitle {
                fullText = "\(footerText) \(linkTitle)"
            } else {
                fullText = footerText
            }

            var attr = AttributedString(fullText)

            attr.font = Fonts.Regular.footnote
            attr.foregroundColor = Colors.Text.tertiary

            if let linkTitle, let range = attr.range(of: linkTitle) {
                attr[range].foregroundColor = isLinkActive ? Colors.Text.accent : Colors.Text.disabled

                if let url {
                    attr[range].link = url
                } else if let emptyUrl = URL(string: " ") {
                    attr[range].link = emptyUrl
                }
            }

            return attr
        }
    }
}

extension YieldFeeSection {
    struct Settings {
        var leadingTextColor: Color = Colors.Text.primary1
        var trailingTextColor: Color = Colors.Text.tertiary
    }
}

extension YieldFeeSection: Setupable {
    public func settings<V>(_ keyPath: WritableKeyPath<Settings, V>, _ value: V) -> Self {
        map { $0.settings[keyPath: keyPath] = value }
    }

    public func trailingTextColor(_ color: Color) -> Self {
        settings(\.trailingTextColor, color)
    }

    public func leadingTextColor(_ color: Color) -> Self {
        settings(\.leadingTextColor, color)
    }
}
