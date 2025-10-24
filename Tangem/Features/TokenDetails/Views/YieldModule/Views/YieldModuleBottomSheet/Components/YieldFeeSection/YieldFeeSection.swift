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

struct YieldFeeSection<LeadingTextAccessoryView: View>: View {
    let leadingTitle: String
    let linkTitle: String?
    let url: URL?
    let needsBackground: Bool
    let onLinkTapAction: (() -> Void)?
    let notification: YieldModuleNotificationBannerParams?
    let leadingTextAccessoryView: LeadingTextAccessoryView

    let sectionState: YieldFeeSectionState

    init(
        sectionState: YieldFeeSectionState,
        leadingTitle: String,
        needsBackground: Bool = true,
        linkTitle: String? = nil,
        url: URL? = nil,
        onLinkTapAction: (() -> Void)? = nil,
        notification: YieldModuleNotificationBannerParams? = nil,
        @ViewBuilder leadingTextAccessoryView: () -> LeadingTextAccessoryView = { EmptyView() }
    ) {
        self.leadingTitle = leadingTitle
        self.sectionState = sectionState
        self.needsBackground = needsBackground
        self.linkTitle = linkTitle
        self.url = url
        self.onLinkTapAction = onLinkTapAction
        self.notification = notification
        self.leadingTextAccessoryView = leadingTextAccessoryView()
    }

    var body: some View {
        VStack(spacing: 14) {
            feeSection
            notificationView
        }
    }

    @ViewBuilder
    private var notificationView: some View {
        if let notification {
            YieldModuleBottomSheetNotificationBannerView(params: notification)
        }
    }

    private var feeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            LoadableFeeRowView(
                leadingTitle: leadingTitle,
                state: sectionState.feeState,
                isHighlighted: sectionState.isHighlighted,
                leadingTextAccessoryView: leadingTextAccessoryView
            )
            .padding(.horizontal, 4)

            .if(needsBackground) { view in
                view.defaultRoundedBackground(
                    with: Colors.Background.action,
                    verticalPadding: 14
                )
            }

            if let footerText = sectionState.footerText {
                FooterText(
                    footerText: footerText,
                    linkTitle: linkTitle,
                    url: url,
                    isLinkActive: sectionState.isLinkActive,
                    onLinkTapAction: onLinkTapAction
                )
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
        let state: LoadableTextView.State
        let isHighlighted: Bool
        let leadingTextAccessoryView: LeadingTextAccessoryView

        init(
            leadingTitle: String,
            state: LoadableTextView.State,
            isHighlighted: Bool,
            leadingTextAccessoryView: LeadingTextAccessoryView
        ) {
            self.leadingTitle = leadingTitle
            self.state = state
            self.isHighlighted = isHighlighted
            self.leadingTextAccessoryView = leadingTextAccessoryView
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center) {
                    Text(leadingTitle)
                        .style(
                            Fonts.Regular.body,
                            color: isHighlighted ? Colors.Text.warning : Colors.Text.primary1
                        )

                    Spacer()

                    HStack {
                        leadingTextAccessoryView
                            .foregroundStyle(isHighlighted ? Colors.Text.warning : Colors.Text.tertiary)

                        LoadableTextView(
                            state: state,
                            font: Fonts.Regular.body,
                            textColor: isHighlighted ? Colors.Text.warning : Colors.Text.tertiary,
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
