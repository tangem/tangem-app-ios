//
//  GeoSelectionContentView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemFoundation
import TangemLocalization
import TangemUI
import TangemUIUtils

struct GeoSelectionContentView: View {
    let state: LoadingResult<GeoSelectionList, any Error>
    let highlightedSectionTitle: String?
    let allSectionTitle: String?
    let hasFlags: Bool
    var loadingItemId: String?
    let onItemTap: (_ id: String, _ isHighlighted: Bool) -> Void

    var body: some View {
        content
            .background {
                DesignSystem.Color.bgPrimary.ignoresSafeArea()
            }
    }
}

// MARK: - Content

private extension GeoSelectionContentView {
    @ViewBuilder
    var content: some View {
        switch state {
        case .loading:
            loadingView

        case .failure:
            emptyView

        case .success(let selectionList):
            if selectionList.isEmpty {
                emptyView
            } else {
                list(selectionList)
            }
        }
    }

    func list(_ selectionList: GeoSelectionList) -> some View {
        ScrollView {
            LazyVStack(spacing: .zero) {
                switch selectionList {
                case .sections(let highlighted, let all):
                    sections(highlighted: highlighted, all: all)

                case .searchResults(let items):
                    ForEach(items) { item in
                        row(item, isHighlighted: false)
                    }
                }
            }
        }
        .allowsHitTesting(loadingItemId == nil)
    }

    @ViewBuilder
    func sections(highlighted: GeoSelectionItem?, all: [GeoSelectionItem]) -> some View {
        if let highlighted {
            Section {
                row(highlighted, isHighlighted: true)
            } header: {
                if let highlightedSectionTitle {
                    header(highlightedSectionTitle)
                }
            }
        }

        Section {
            ForEach(all) { item in
                row(item, isHighlighted: false)
            }
        } header: {
            if all.isNotEmpty, let allSectionTitle {
                header(allSectionTitle)
            }
        }
    }

    @ViewBuilder
    func row(_ item: GeoSelectionItem, isHighlighted: Bool) -> some View {
        if hasFlags {
            Row(title: item.title)
                .start { CountryFlagView(url: item.flagURL) }
                .end { loader(for: item) }
                .onTap { onItemTap(item.id, isHighlighted) }
                .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.geoSelectionRow)
        } else {
            Row(title: item.title)
                .end { loader(for: item) }
                .onTap { onItemTap(item.id, isHighlighted) }
                .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.geoSelectionRow)
        }
    }

    @ViewBuilder
    func loader(for item: GeoSelectionItem) -> some View {
        if item.id == loadingItemId {
            Loader()
                .loaderSize(.size20)
        }
    }

    func header(_ title: String) -> some View {
        Text(title)
            .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Constants.horizontalPadding)
            .padding(.top, Constants.sectionSpacing)
            .padding(.bottom, Constants.titleVerticalPadding)
    }
}

// MARK: - States

private extension GeoSelectionContentView {
    var loadingView: some View {
        VStack(spacing: Constants.skeletonRowSpacing) {
            ForEach(0 ..< Constants.skeletonRowCount, id: \.self) { _ in
                GeoSelectionRowSkeleton(hasFlag: hasFlags)
            }

            Spacer(minLength: .zero)
        }
    }

    var emptyView: some View {
        messageView(
            icon: DesignSystem.Icons.Binoculars.regular20,
            message: Localization.tangempayResidencySearchEmpty
        )
    }

    func messageView(icon: ImageType, message: String) -> some View {
        VStack(spacing: Constants.messageSpacing) {
            DesignSystem.Color.bgSecondary
                .frame(width: Constants.iconBackgroundSide, height: Constants.iconBackgroundSide)
                .overlay {
                    icon.image
                        .renderingMode(.template)
                        .foregroundStyle(DesignSystem.Color.iconSecondary)
                }
                .clipShape(Circle())

            Text(message)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .infinityFrame()
    }
}

// MARK: - Constants

private extension GeoSelectionContentView {
    enum Constants {
        static let skeletonRowSpacing: CGFloat = 12
        static let sectionSpacing: CGFloat = 16
        static let horizontalPadding: CGFloat = 16
        static let titleVerticalPadding: CGFloat = 8
        static let messageSpacing: CGFloat = 12
        static let errorSpacing: CGFloat = 16
        static let iconBackgroundSide: CGFloat = 40
        static let skeletonRowCount = 8
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Countries") {
    GeoSelectionContentView(
        state: .success(
            .sections(highlighted: nil, all: GeoSelectionItem.previewCountries)
        ),
        highlightedSectionTitle: nil,
        allSectionTitle: nil,
        hasFlags: true,
        onItemTap: { _, _ in }
    )
}

#Preview("Countries with selection") {
    GeoSelectionContentView(
        state: .success(
            .sections(
                highlighted: GeoSelectionItem.previewCountries[2],
                all: GeoSelectionItem.previewCountries
            )
        ),
        highlightedSectionTitle: "Selected country",
        allSectionTitle: "Change country",
        hasFlags: true,
        onItemTap: { _, _ in }
    )
}

#Preview("Regions with selection") {
    GeoSelectionContentView(
        state: .success(
            .sections(
                highlighted: GeoSelectionItem.previewRegions[1],
                all: GeoSelectionItem.previewRegions
            )
        ),
        highlightedSectionTitle: "Selected state",
        allSectionTitle: "Select another state",
        hasFlags: false,
        onItemTap: { _, _ in }
    )
}

#Preview("Search results") {
    GeoSelectionContentView(
        state: .success(
            .searchResults(Array(GeoSelectionItem.previewCountries.prefix(2)))
        ),
        highlightedSectionTitle: "Selected country",
        allSectionTitle: "Change country",
        hasFlags: true,
        onItemTap: { _, _ in }
    )
}

#Preview("Item loading") {
    GeoSelectionContentView(
        state: .success(
            .sections(highlighted: nil, all: GeoSelectionItem.previewCountries)
        ),
        highlightedSectionTitle: nil,
        allSectionTitle: nil,
        hasFlags: true,
        loadingItemId: GeoSelectionItem.previewCountries[1].id,
        onItemTap: { _, _ in }
    )
}

#Preview("Loading") {
    GeoSelectionContentView(
        state: .loading,
        highlightedSectionTitle: "Selected country",
        allSectionTitle: "Change country",
        hasFlags: true,
        onItemTap: { _, _ in }
    )
}

#Preview("Empty") {
    GeoSelectionContentView(
        state: .success(.searchResults([])),
        highlightedSectionTitle: "Selected country",
        allSectionTitle: "Change country",
        hasFlags: true,
        onItemTap: { _, _ in }
    )
}

#Preview("Error") {
    GeoSelectionContentView(
        state: .failure(CancellationError()),
        highlightedSectionTitle: "Selected country",
        allSectionTitle: "Change country",
        hasFlags: true,
        onItemTap: { _, _ in }
    )
}
#endif
