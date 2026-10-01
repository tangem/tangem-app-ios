//
//  TokenIconV2Showcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG
import SwiftUI
import Kingfisher
import TangemAssets
import TangemUI
import TangemUIUtils

struct TokenIconV2Showcase: View {
    @State private var size: TokenIconV2.Size = .size56
    @State private var scenario: Scenario = .loaded
    @State private var showNetworkBadge = true
    @State private var isCustomToken = false
    @State private var isGrayscale = false
    @State private var reloadToken = 0
    @State private var simulationTask: Task<Void, Never>?

    var body: some View {
        DSShowcase("TokenIconV2") { controls in
            controls.picker("Size", $size)
            controls.picker("State", $scenario, options: Scenario.selectable + [.holding], label: \.title)
            controls.toggle("Network badge", $showNetworkBadge)
            controls.toggle("Custom token", $isCustomToken)
            controls.toggle("Grayscale (dimmed)", $isGrayscale)

            if isCustomToken {
                controls.note("Custom tokens render their identity color and never load a remote image, so there is no load lifecycle to simulate.")
            } else {
                controls.action("Simulate loading → loaded") { simulate(to: .loaded) }
                controls.action("Simulate loading → error") { simulate(to: .failing) }
                controls.note("Parks the icon on its real shimmer for \(Int(Self.shimmerHold)) s, then resolves to the artwork or the error glyph.")
            }
        } stage: {
            TokenIconV2(tokenIconInfo: tokenIconInfo(url: scenario.imageURL, isCustom: isCustomToken), size: size)
                .grayscale(isGrayscale)
                .id(reloadToken)
        } matrix: {
            DSShowcaseGroup("Size × state") {
                DSShowcaseMatrix(rows: TokenIconV2.Size.allCases, columns: Scenario.selectable, columnLabel: { $0.title }) { size, scenario in
                    TokenIconV2(tokenIconInfo: tokenIconInfo(url: scenario.imageURL, isCustom: false), size: size)
                        .grayscale(isGrayscale)
                }
            }

            DSShowcaseGroup("Custom token") {
                DSShowcaseMatrix(rows: TokenIconV2.Size.allCases, columns: [false, true], columnLabel: { $0 ? "badge" : "no badge" }) { size, hasBadge in
                    TokenIconV2(tokenIconInfo: tokenIconInfo(url: nil, isCustom: true, hasBadge: hasBadge), size: size)
                }
            }

            DSShowcaseGroup("Transparent-corner artwork") {
                artworkGrid(samples: Self.transparentArtworkSamples)
            }

            DSShowcaseGroup("Full-bleed square artwork") {
                artworkGrid(samples: Self.squareArtworkSamples)
            }
        }
        .onDisappear {
            simulationTask?.cancel()
            simulationTask = nil
        }
    }

    private func simulate(to end: Scenario) {
        simulationTask?.cancel()

        if end == .loaded, let key = end.imageURL?.absoluteString {
            ImageCache.default.removeImage(forKey: key)
        }

        scenario = .holding
        reloadToken += 1

        simulationTask = Task { @MainActor in
            try? await ContinuousClock().sleep(for: .seconds(Self.shimmerHold))
            guard !Task.isCancelled else { return }

            scenario = end
            reloadToken += 1
        }
    }

    private func artworkGrid(samples: [ArtworkSample]) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 16, alignment: .top)], alignment: .leading, spacing: 16) {
            ForEach(samples, id: \.id) { sample in
                VStack(spacing: 6) {
                    TokenIconV2(
                        tokenIconInfo: TokenIconInfo(
                            name: sample.name,
                            blockchainIconAsset: showNetworkBadge ? Tokens.ethereumFill : nil,
                            imageURL: Self.imageURL(for: sample.id),
                            isCustom: false,
                            customTokenColor: nil
                        ),
                        size: TokenIconV2.Size.size56
                    )
                    .grayscale(isGrayscale)

                    Text(sample.name)
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func tokenIconInfo(url: URL?, isCustom: Bool, hasBadge: Bool? = nil) -> TokenIconInfo {
        TokenIconInfo(
            name: "Bitcoin",
            blockchainIconAsset: hasBadge ?? showNetworkBadge ? Tokens.ethereumFill : nil,
            imageURL: url,
            isCustom: isCustom,
            customTokenColor: isCustom ? DesignSystem.Color.iconAccentBlue : nil
        )
    }

    private static var shimmerHold: Double { 2 }

    private static func imageURL(for id: String) -> URL? {
        URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/coins/large/\(id).png")
    }

    private static var transparentArtworkSamples: [ArtworkSample] {
        [
            ArtworkSample(id: "uniswap", name: "Uniswap"),
            ArtworkSample(id: "maker", name: "Maker"),
            ArtworkSample(id: "aave", name: "Aave"),
            ArtworkSample(id: "curve-dao-token", name: "Curve"),
            ArtworkSample(id: "the-graph", name: "The Graph"),
            ArtworkSample(id: "thorchain", name: "THORChain"),
            ArtworkSample(id: "pancakeswap-token", name: "PancakeSwap"),
            ArtworkSample(id: "dogecoin", name: "Dogecoin"),
            ArtworkSample(id: "havven", name: "Synthetix"),
            ArtworkSample(id: "render-token", name: "Render"),
        ]
    }

    private static var squareArtworkSamples: [ArtworkSample] {
        [
            ArtworkSample(id: "tron", name: "TRON"),
            ArtworkSample(id: "okb", name: "OKB"),
            ArtworkSample(id: "stellar", name: "Stellar"),
            ArtworkSample(id: "near", name: "NEAR"),
            ArtworkSample(id: "polkadot", name: "Polkadot"),
            ArtworkSample(id: "chainlink", name: "Chainlink"),
            ArtworkSample(id: "1inch", name: "1inch"),
            ArtworkSample(id: "algorand", name: "Algorand"),
            ArtworkSample(id: "the-sandbox", name: "The Sandbox"),
            ArtworkSample(id: "wrapped-bitcoin", name: "WBTC"),
        ]
    }
}

private extension TokenIconV2Showcase {
    struct ArtworkSample {
        let id: String
        let name: String
    }

    enum Scenario: Hashable {
        case loaded
        case missingURL
        case failing
        case holding

        static var selectable: [Scenario] {
            [.loaded, .missingURL, .failing]
        }

        var title: String {
            switch self {
            case .loaded: "loaded"
            case .missingURL: "missing URL"
            case .failing: "error (404)"
            case .holding: "loading"
            }
        }

        var imageURL: URL? {
            switch self {
            case .loaded:
                URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/coins/large/bitcoin.png")
            case .missingURL:
                nil
            case .failing:
                URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/coins/large/__tokeniconv2_demo_missing__.png")
            case .holding:
                URL(string: "https://10.255.255.1/tokeniconv2_demo_hold.png")
            }
        }
    }
}
#endif
