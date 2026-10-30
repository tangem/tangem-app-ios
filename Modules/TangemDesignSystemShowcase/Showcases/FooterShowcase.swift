//
//  FooterShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG
import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct FooterShowcase: View {
    @State private var variant: Variant = .default
    @State private var showsSecondary = true
    @State private var toolbarItems: ToolbarItems = .both
    @State private var showsCaption = false
    @State private var showsFade = true
    @State private var isPrimaryLoading = false
    @State private var searchText = ""
    @State private var taps = 0
    @State private var isModalPresented = false

    var body: some View {
        DSShowcase("Footer", layout: .fill) { controls in
            controls.picker("Variant", $variant)

            switch variant {
            case .default:
                controls.toggle("Secondary button", $showsSecondary)
                controls.toggle("Primary loading", $isPrimaryLoading)
            case .toolbar:
                controls.picker("Buttons", $toolbarItems)
            case .search:
                EmptyView()
            }

            if variant != .search {
                controls.toggle("Caption", $showsCaption)
                controls.toggle("Fade", $showsFade)
            }
            controls.readout("Taps", "\(taps)")
            controls.action("Present in modal") { isModalPresented = true }
            controls.note("Focus the search field: the footer rides above the keyboard. In the modal, .footer hands search to tangemSearchable: the native bottom field on iOS 26+, this footer below; search has no caption or fade. The modal drops the extra inset and tints the fade to the sheet.")
        } stage: {
            ScrollView {
                FooterShowcaseTokenList()
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                footer
            }
            .modal(
                isPresented: $isModalPresented,
                navigation: .title("Send BTC"),
                content: { FooterShowcaseTokenList().footer { footer } }
            )
        } matrix: {
            DSShowcaseMatrix(
                rows: Variant.allCases,
                columns: [false, true],
                columnLabel: { $0 ? "caption" : "no caption" }
            ) { variant, showsCaption in
                Footer(content(for: variant, toolbarItems: .both, showsSecondary: true, isPrimaryLoading: false))
                    .caption(showsCaption ? Self.caption : nil)
                    .frame(width: 360)
            }
        }
    }

    private var footer: Footer {
        Footer(content(for: variant, toolbarItems: toolbarItems, showsSecondary: showsSecondary, isPrimaryLoading: isPrimaryLoading))
            .caption(variant != .search && showsCaption ? Self.caption : nil)
            .showFade(variant != .search && showsFade)
    }

    private func content(
        for variant: Variant,
        toolbarItems: ToolbarItems,
        showsSecondary: Bool,
        isPrimaryLoading: Bool
    ) -> FooterContent {
        switch variant {
        case .default:
            let primary = TangemUI.Button(label: "Continue", accessibilityLabel: nil, action: tap)
                .styleType(.primary)
                .loading(.spinner(if: isPrimaryLoading))
            let secondary = TangemUI.Button(label: "Not now", accessibilityLabel: nil, action: tap)
                .styleType(.secondary(.default))
            return .buttons(primary: primary, secondary: showsSecondary ? secondary : nil)
        case .toolbar:
            let start = TangemUI.Button(icon: DesignSystem.Icons.Filter.regular20, accessibilityLabel: "Filter", action: tap)
                .styleType(.material(.glass))
            let end = TangemUI.Button(icon: DesignSystem.Icons.ScanQr.regular20, accessibilityLabel: "Scan QR", action: tap)
                .styleType(.primary)
            switch toolbarItems {
            case .both: return .toolbar(start: start, end: end)
            case .start: return .toolbar(start: start)
            case .end: return .toolbar(end: end)
            }
        case .search:
            return .search(Search(text: $searchText).placeholder("Search tokens"))
        }
    }

    private func tap() {
        taps += 1
    }

    private static var caption: AttributedString {
        var text = AttributedString("By continuing you agree to the Terms of Service and Privacy Policy")
        if let range = text.range(of: "Terms of Service") {
            text[range].link = URL(string: "https://tangem.com/terms")
        }
        if let range = text.range(of: "Privacy Policy") {
            text[range].link = URL(string: "https://tangem.com/privacy")
        }
        return text
    }
}

private extension FooterShowcase {
    enum Variant: CaseIterable, Hashable {
        case `default`
        case toolbar
        case search
    }

    enum ToolbarItems: CaseIterable, Hashable {
        case both
        case start
        case end
    }
}

private struct FooterShowcaseTokenList: View {
    private let tokens = [
        ("Bitcoin", "0.0421 BTC"), ("Ethereum", "1.2804 ETH"), ("Solana", "36.17 SOL"),
        ("Tether", "1,250.00 USDT"), ("Toncoin", "412.9 TON"), ("Polygon", "880.4 POL"),
        ("Cardano", "2,031.6 ADA"), ("Dogecoin", "9,412 DOGE"), ("Litecoin", "3.88 LTC"),
        ("Avalanche", "44.2 AVAX"), ("USD Coin", "320.15 USDC"), ("Wrapped Bitcoin", "0.0103 WBTC"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(tokens, id: \.0) { name, balance in
                HStack {
                    Text(name)
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

                    Spacer()

                    Text(balance)
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
        }
    }
}
#endif
