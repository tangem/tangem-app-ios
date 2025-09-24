//
//  NetworkFeeSection.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct NetworkFeeSection: View {
    let leadingTitle: String
    let state: State
    let footerText: String
    let linkTitle: String?
    let urlString: String?
    let onLinkTapAction: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            LoadableNetworkFeeRowView(leadingTitle: leadingTitle, state: state)
                .padding(.horizontal, 4)
                .defaultRoundedBackground(verticalPadding: 14)

            FooterText(footerText: footerText, linkTitle: linkTitle, urlString: urlString, onLinkTapAction: onLinkTapAction)
                .padding(.horizontal, 14)
        }
    }
}

// MARK: - State

extension NetworkFeeSection {
    enum State {
        case loading
        case loaded(fee: String)
        case error

        var isLoaded: Bool {
            if case .loaded = self {
                true
            } else {
                false
            }
        }
    }
}

// MARK: - LoadableNetworkFeeRowView

extension NetworkFeeSection {
    struct LoadableNetworkFeeRowView: View {
        let leadingTitle: String
        var state: State

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center) {
                    Text(leadingTitle)
                        .style(Fonts.Regular.body, color: Colors.Text.primary1)

                    Spacer()

                    valueView
                }
            }
        }

        @ViewBuilder
        private var valueView: some View {
            switch state {
            case .loading:
                Text("0.000000")
                    .style(Fonts.Regular.body, color: Colors.Text.primary1)
                    .skeletonable(isShown: true)

            case .loaded(let fee):
                Text(fee)
                    .style(Fonts.Regular.body, color: Colors.Text.tertiary)

            case .error:
                Text(BalanceFormatter.defaultEmptyBalanceString)
            }
        }
    }
}

// MARK: - FooterText

extension NetworkFeeSection {
    struct FooterText: View {
        let footerText: String
        let linkTitle: String?
        let urlString: String?
        let onLinkTapAction: (() -> Void)?

        var body: some View {
            let attr = makeFeePolicyAttributedString()

            return Text(attr)
                .environment(\.openURL, OpenURLAction { _ in
                    if let onLinkTapAction {
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
                attr[range].foregroundColor = Colors.Text.accent
                attr[range].link = URL(string: urlString ?? " ")
            }

            return attr
        }
    }
}
