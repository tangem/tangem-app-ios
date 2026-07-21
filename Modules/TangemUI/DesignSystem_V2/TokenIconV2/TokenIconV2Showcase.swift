//
//  TokenIconV2Showcase.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher
import TangemAssets
import TangemFoundation

public struct TokenIconV2Showcase: View {
    @State private var size: TokenIconV2.Size = .size56
    @State private var scenario: Scenario = .loaded
    @State private var showNetworkBadge = true
    @State private var isCustomToken = false
    @State private var isGrayscale = false

    /// Bumped to give the icon a fresh identity, restarting its internal load state machine so the
    /// full loading → loaded / error sequence replays from scratch (rather than the static end state).
    @State private var reloadToken = 0

    @State private var simulationTask: Task<Void, Never>?

    @State private var dynamicTypeIndex = Self.dynamicTypeAllCases.firstIndex(of: .large) ?? 0
    @State private var reduceMotion = false
    @State private var isRTL = false
    @State private var isDark = false

    private static let dynamicTypeAllCases: [DynamicTypeSize] = Array(DynamicTypeSize.allCases)

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                previewSection

                simulateSection

                allSizesSection

                shapesSection

                stateControls

                environmentControls
            }
            .padding(24)
        }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
        .onDisappear {
            simulationTask?.cancel()
            simulationTask = nil
        }
    }

    // MARK: - Preview

    private var previewSection: some View {
        section(title: "Preview") {
            demoedIcon
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                // Neutral grey so the white `bgSecondary` placeholder circle and the translucent
                // shimmer read against the backdrop (they'd vanish on a white surface).
                .background(Color(uiColor: .systemGray4), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    @ViewBuilder
    private var demoedIcon: some View {
        icon
            // The four environment overrides scope to the icon subtree only, so the controls below
            // keep the app's real environment. `.preferredColorScheme` would leak to the whole view.
            .environment(\.dynamicTypeSize, dynamicTypeSize)
            .environment(\.layoutDirection, isRTL ? .rightToLeft : .leftToRight)
            .environment(\.colorScheme, isDark ? .dark : .light)
        #if DEBUG
            .environment(\._accessibilityReduceMotion, reduceMotion)
        #endif // DEBUG
    }

    private var icon: some View {
        TokenIconV2(tokenIconInfo: tokenIconInfo(url: scenario.imageURL), size: size)
            .grayscale(isGrayscale)
            .id(reloadToken)
    }

    // MARK: - Simulate

    private var simulateSection: some View {
        section(title: "Simulate transition") {
            HStack(spacing: 12) {
                Button("Loading → Loaded") {
                    simulate(to: .loaded, evictingCache: true)
                }
                .tint(.green)

                Button("Loading → Error") {
                    simulate(to: .failing, evictingCache: false)
                }
                .tint(.red)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            // Custom tokens render their identity color instead of loading a remote image, so there's
            // no load lifecycle to simulate.
            .disabled(isCustomToken)

            Text(isCustomToken
                ? "Not applicable — custom tokens render their identity color and never load a remote image."
                : "Parks the real component on the shimmer for \(Int(Self.shimmerHold)) s, then resolves to the artwork (or the error glyph on a 404) — the component's own loading → loaded / error path.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    /// Holds the component on its real shimmer, then flips to the outcome. The hold parks it on an
    /// unreachable URL (so the genuine loading state shows) rather than faking the phase; evicting the
    /// cache first forces a real network round-trip so the loaded case doesn't resolve instantly.
    private func simulate(to end: Scenario, evictingCache: Bool) {
        simulationTask?.cancel()

        // Evict here (synchronous context) so it binds to the non-async overload; the hold uses a
        // different URL, so nothing re-caches this key before the swap.
        if evictingCache, let key = end.imageURL?.absoluteString {
            ImageCache.default.removeImage(forKey: key)
        }

        scenario = .holding
        reloadToken += 1

        simulationTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(Self.shimmerHold))
            guard !Task.isCancelled else { return }

            scenario = end
            reloadToken += 1
        }
    }

    private static let shimmerHold: Double = 2

    // MARK: - Sizes

    private var allSizesSection: some View {
        section(title: "All sizes (loaded)") {
            HStack(alignment: .bottom, spacing: 20) {
                ForEach(TokenIconV2.Size.allCases, id: \.self) { size in
                    TokenIconV2(tokenIconInfo: tokenIconInfo(url: Scenario.loaded.imageURL), size: size)
                        .grayscale(isGrayscale)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Shapes

    /// Real logos with non-square / irregular artwork, to check the circular clip and the cutout
    /// against transparency, wide marks, and off-center glyphs.
    private var shapesSection: some View {
        section(title: "Irregular artwork (real logos)") {
            let columns = [GridItem(.adaptive(minimum: 72), spacing: 16, alignment: .top)]

            LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
                ForEach(Self.shapeSamples, id: \.id) { sample in
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
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    // MARK: - Controls

    private var stateControls: some View {
        section(title: "State") {
            Picker("Size", selection: $size) {
                Text("40").tag(TokenIconV2.Size.size40)
                Text("44").tag(TokenIconV2.Size.size44)
                Text("56").tag(TokenIconV2.Size.size56)
                Text("72").tag(TokenIconV2.Size.size72)
            }
            .pickerStyle(.segmented)

            Picker("State", selection: $scenario) {
                Text("Loaded").tag(Scenario.loaded)
                Text("Missing URL").tag(Scenario.missingURL)
                Text("Error (404)").tag(Scenario.failing)
            }
            .pickerStyle(.segmented)

            Toggle("Network badge", isOn: $showNetworkBadge)
            Toggle("Custom token", isOn: $isCustomToken)
            Toggle("Grayscale (dimmed)", isOn: $isGrayscale)
        }
    }

    private var environmentControls: some View {
        section(title: "Environment (icon only)") {
            Stepper(
                "Dynamic Type: \(String(describing: dynamicTypeSize))",
                value: $dynamicTypeIndex,
                in: 0 ... (Self.dynamicTypeAllCases.count - 1)
            )
            Toggle("Reduce Motion", isOn: $reduceMotion)
            Toggle("Right-to-left", isOn: $isRTL)
            Toggle("Dark theme", isOn: $isDark)
        }
    }

    // MARK: - Helpers

    private var dynamicTypeSize: DynamicTypeSize {
        Self.dynamicTypeAllCases[dynamicTypeIndex]
    }

    private func tokenIconInfo(url: URL?) -> TokenIconInfo {
        TokenIconInfo(
            name: "Bitcoin",
            blockchainIconAsset: showNetworkBadge ? Tokens.ethereumFill : nil,
            imageURL: url,
            isCustom: isCustomToken,
            customTokenColor: isCustomToken ? DesignSystem.Color.iconAccentBlue : nil
        )
    }

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            content()
        }
    }

    private static func imageURL(for id: String) -> URL? {
        URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/coins/large/\(id).png")
    }

    private struct ShapeSample {
        let id: String
        let name: String
    }

    private static let shapeSamples: [ShapeSample] = [
        ShapeSample(id: "uniswap", name: "Uniswap"),
        ShapeSample(id: "maker", name: "Maker"),
        ShapeSample(id: "chainlink", name: "Chainlink"),
        ShapeSample(id: "aave", name: "Aave"),
        ShapeSample(id: "curve-dao-token", name: "Curve"),
        ShapeSample(id: "1inch", name: "1inch"),
        ShapeSample(id: "the-graph", name: "The Graph"),
        ShapeSample(id: "thorchain", name: "THORChain"),
        ShapeSample(id: "pancakeswap-token", name: "PancakeSwap"),
        ShapeSample(id: "dogecoin", name: "Dogecoin"),
        ShapeSample(id: "havven", name: "Synthetix"),
        ShapeSample(id: "render-token", name: "Render"),
    ]
}

// MARK: - Scenario

private extension TokenIconV2Showcase {
    enum Scenario: Hashable {
        case loaded
        case missingURL
        case failing
        /// Non-routable host — the request stays in flight, so the component sits on its real shimmer
        /// for the demo's hold window before the simulation swaps in the outcome.
        case holding

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
