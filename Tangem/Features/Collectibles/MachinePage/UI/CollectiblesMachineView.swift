//
//  CollectiblesMachineView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct CollectiblesMachineView: View {
    @ObservedObject var viewModel: CollectiblesMachineViewModel

    let onBack: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                artwork
                    .padding(.top, Metrics.artworkTopPadding)

                content
                    .padding(.top, Metrics.contentTopPadding)
            }
            .padding(.bottom, Metrics.contentBottomPadding)
        }
        .infinityFrame()
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Footer(
                expectedValueText: viewModel.details.expectedValueText,
                openButtonText: viewModel.openButtonText,
                isTurboModeOn: $viewModel.isTurboModeOn,
                onTurboModeInfoTap: viewModel.showTurboModeInfo,
                onOpenTap: viewModel.openOrder
            )
        }
        .on(willAppear: viewModel.onWillAppear, willDisappear: viewModel.onWillDisappear)
        .collectiblesInfoSheet(viewModel: viewModel.turboModeInfoViewModel)
        .safeAreaInset(edge: .top, spacing: 0) { navigationBar }
    }
}

private extension CollectiblesMachineView {
    // MARK: - View properties

    var navigationBar: some View {
        NavigationBar(
            settings: .init(
                backgroundColor: .clear,
                horizontalPadding: Metrics.horizontalPadding,
                height: Metrics.navigationBarHeight
            ),
            titleView: {
                Text(viewModel.title)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
            },
            leftButtons: { NavigationBarButton.back(action: onBack) },
            rightButtons: EmptyView.init
        )
        .padding(.top, Metrics.navigationBarTopPadding)
        .environment(\.isRedesign, true)
        .background {
            Fade(position: .top)
                .blurred()
                .backgroundColor(DesignSystem.Color.bgPrimary)
                .ignoresSafeArea(edges: .top)
        }
    }

    var artwork: some View {
        CollectiblesPackCard.Artwork(url: viewModel.artworkURL, packSize: Metrics.packSize, hasFailureCard: true)
            .frame(width: Metrics.packSize.width, height: Metrics.packSize.height)
    }

    var content: some View {
        sections(viewModel.details)
    }

    func sections(_ details: CollectiblesMachineViewModel.Details) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(Localization.collectiblesMachineValueAndOddsSection)

            tierList(details.tiers)
                .padding(.vertical, Metrics.chipsContainerVerticalPadding)

            sectionHeader(Localization.collectiblesMachineDetailsSection)
                .padding(.top, Metrics.sectionsGap)

            detailChips(details)
                .padding(.vertical, Metrics.chipsContainerVerticalPadding)

            PoweredBy()
                .padding(.top, Metrics.poweredByTopPadding)

            CollectiblesPrizePoolView(viewModel: viewModel.prizePoolViewModel)
        }
        .padding(.horizontal, Metrics.horizontalPadding)
    }

    func sectionHeader(_ title: String) -> some View {
        Text(title)
            .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
            .padding(.vertical, Metrics.sectionHeaderVerticalPadding)
    }

    func tierList(_ tiers: [CollectiblesMachineViewModel.TierChip]) -> some View {
        VStack(spacing: Metrics.chipSpacing) {
            ForEach(tiers) { chip in
                tierChip(chip)
            }
        }
    }

    func tierChip(_ chip: CollectiblesMachineViewModel.TierChip) -> some View {
        VStack(alignment: .leading, spacing: Metrics.chipLinesSpacing) {
            HStack(spacing: 0) {
                Text(chip.title)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                    .lineLimit(1)

                Spacer(minLength: Metrics.chipSpacing)

                Circle()
                    .fill(dotColor(of: chip.tier))
                    .frame(size: CGSize(bothDimensions: Metrics.tierDotSize))
            }

            if let detailText = chip.detailText {
                Text(detailText)
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                    .lineLimit(1)
            }
        }
        .chipDecorated()
    }

    func detailChips(_ details: CollectiblesMachineViewModel.Details) -> some View {
        LazyVGrid(columns: Metrics.chipColumns, alignment: .leading, spacing: Metrics.chipSpacing) {
            if let cardsCountText = details.cardsCountText {
                detailChip(label: Localization.collectiblesMachineDetailContains, value: cardsCountText)
            }

            detailChip(label: Localization.collectiblesMachineDetailInstantBuyback, value: details.buybackText)
        }
    }

    func detailChip(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: Metrics.chipLinesSpacing) {
            Text(label)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                .lineLimit(1)

            Text(value)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                .lineLimit(1)
        }
        .chipDecorated()
    }

    // MARK: - Calculations

    func dotColor(of tier: CollectiblesMachine.Tier) -> Color {
        switch tier {
        case .common: DesignSystem.Color.bgAccentNeutral
        case .uncommon: DesignSystem.Color.bgAccentGreen
        case .rare: DesignSystem.Color.bgAccentBlue
        case .epic: DesignSystem.Color.bgAccentViolet
        // Absent from the mockup (no machine carries the tier yet); the gold-ish accent is the safe guess.
        case .legendary: DesignSystem.Color.bgAccentOrange
        }
    }
}

// MARK: - Chip decoration

private extension View {
    func chipDecorated() -> some View {
        padding(CollectiblesMachineView.Metrics.chipContentPadding)
            .infinityFrame(axis: .horizontal, alignment: .leading)
            .background(DesignSystem.Color.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: CollectiblesMachineView.Metrics.chipCornerRadius, style: .continuous))
    }
}

// MARK: - Metrics

extension CollectiblesMachineView {
    enum Metrics {
        static let navigationBarTopPadding: CGFloat = 8
        static let navigationBarHeight: CGFloat = 56

        static let packSize = CGSize(width: 252, height: 378)
        static let artworkTopPadding: CGFloat = 6
        static let contentTopPadding: CGFloat = 6
        static let contentBottomPadding: CGFloat = 24
        static let horizontalPadding: CGFloat = 16

        static let chipColumns = [
            GridItem(.flexible(), spacing: chipSpacing),
            GridItem(.flexible(), spacing: chipSpacing),
        ]

        static let chipSpacing: CGFloat = 8
        static let chipContentPadding: CGFloat = 16
        static let chipLinesSpacing: CGFloat = 2
        static let chipCornerRadius: CGFloat = 20
        static let tierDotSize: CGFloat = 14
        static let chipsContainerVerticalPadding: CGFloat = 8
        static let poweredByTopPadding: CGFloat = 4

        static let sectionHeaderVerticalPadding: CGFloat = 10
        static let sectionsGap: CGFloat = 24
    }
}

// MARK: - Previews

private struct PreviewPrizePoolProvider: CollectiblesPrizePoolProvider {
    func load(machineID: String, page: Int) async throws -> CollectiblesPrizePoolPage {
        let prizes = (1 ... 4).map { index in
            CollectiblesPrize(id: "prize-\(index)", name: "Charizard \(index)", imageURL: nil, grade: "PSA 9", insuredValue: Decimal(1000 * index))
        }
        return CollectiblesPrizePoolPage(prizes: prizes, hasNext: false)
    }
}

private struct PreviewMachineProvider: CollectiblesMachineProvider {
    static let machine = CollectiblesMachine(
        name: "Elite pack",
        artworkURL: nil,
        price: 50,
        platformFee: 1,
        cardsPerPack: 1,
        buybackRate: 0.85,
        expectedValue: 53.95,
        tiers: [
            .init(tier: .common, odds: 0.8, valueRange: 15 ... 40),
            .init(tier: .uncommon, odds: 0.15, valueRange: 60 ... 110),
            .init(tier: .rare, odds: 0.04, valueRange: 110 ... 250),
            .init(tier: .epic, odds: 0.01, valueRange: 250 ... 5001),
        ]
    )

    func load(id: String) async throws -> CollectiblesMachine {
        Self.machine
    }
}

#Preview {
    NavigationStack {
        CollectiblesMachineView(
            viewModel: CollectiblesMachineViewModel(
                pack: CollectiblesPack(
                    id: "pokemon_50",
                    loreID: "pokemon",
                    currencyCode: "USD",
                    machine: PreviewMachineProvider.machine
                ),
                routable: nil,
                prizePoolProvider: PreviewPrizePoolProvider(),
                provider: PreviewMachineProvider()
            ),
            onBack: {}
        )
    }
}
