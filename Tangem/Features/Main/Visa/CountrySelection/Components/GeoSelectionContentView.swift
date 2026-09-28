//
//  GeoSelectionContentView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemFoundation
import TangemLocalization
import TangemUI
import TangemUIUtils

struct GeoSelectionContentView: View {
    let state: LoadingResult<GeoSelectionSections, any Error>
    let highlightedSectionTitle: String?
    let allSectionTitle: String?
    let hasFlags: Bool
    var loadingItemId: String?
    let onItemTap: (String) -> Void

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

        case .success(let sections):
            if sections.isEmpty {
                emptyView
            } else {
                list(sections)
            }
        }
    }

    func list(_ sections: GeoSelectionSections) -> some View {
        ScrollView {
            LazyVStack(
                spacing: .zero,
                pinnedViews: [.sectionHeaders]
            ) {
                if let highlighted = sections.highlighted {
                    Section {
                        row(highlighted)
                    } header: {
                        if let highlightedSectionTitle {
                            header(highlightedSectionTitle)
                        }
                    }
                }

                Section {
                    ForEach(sections.all) { item in
                        row(item)
                    }
                } header: {
                    if sections.all.isNotEmpty, let allSectionTitle {
                        header(allSectionTitle)
                    }
                }
            }
        }
        .allowsHitTesting(loadingItemId == nil)
    }

    @ViewBuilder
    func row(_ item: GeoSelectionItem) -> some View {
        if hasFlags {
            Row(title: item.title)
                .start { CountryFlagView(url: item.flagURL) }
                .end { loader(for: item) }
                .onTap { onItemTap(item.id) }
        } else {
            Row(title: item.title)
                .end { loader(for: item) }
                .onTap { onItemTap(item.id) }
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
            .background(DesignSystem.Color.bgPrimary)
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
            // [REDACTED_TODO_COMMENT]
            message: "No results. Try to change request"
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
            GeoSelectionSections(highlighted: nil, all: GeoSelectionItem.previewCountries)
        ),
        highlightedSectionTitle: nil,
        allSectionTitle: nil,
        hasFlags: true,
        onItemTap: { _ in }
    )
}

#Preview("Countries with selection") {
    GeoSelectionContentView(
        state: .success(
            GeoSelectionSections(
                highlighted: GeoSelectionItem.previewCountries[2],
                all: GeoSelectionItem.previewCountries
            )
        ),
        highlightedSectionTitle: "Selected country",
        allSectionTitle: "Change country",
        hasFlags: true,
        onItemTap: { _ in }
    )
}

#Preview("Regions with selection") {
    GeoSelectionContentView(
        state: .success(
            GeoSelectionSections(
                highlighted: GeoSelectionItem.previewRegions[1],
                all: GeoSelectionItem.previewRegions
            )
        ),
        highlightedSectionTitle: "Selected state",
        allSectionTitle: "Select another state",
        hasFlags: false,
        onItemTap: { _ in }
    )
}

#Preview("Item loading") {
    GeoSelectionContentView(
        state: .success(
            GeoSelectionSections(highlighted: nil, all: GeoSelectionItem.previewCountries)
        ),
        highlightedSectionTitle: nil,
        allSectionTitle: nil,
        hasFlags: true,
        loadingItemId: GeoSelectionItem.previewCountries[1].id,
        onItemTap: { _ in }
    )
}

#Preview("Loading") {
    GeoSelectionContentView(
        state: .loading,
        highlightedSectionTitle: "Selected country",
        allSectionTitle: "Change country",
        hasFlags: true,
        onItemTap: { _ in }
    )
}

#Preview("Empty") {
    GeoSelectionContentView(
        state: .success(GeoSelectionSections(highlighted: nil, all: [])),
        highlightedSectionTitle: "Selected country",
        allSectionTitle: "Change country",
        hasFlags: true,
        onItemTap: { _ in }
    )
}

#Preview("Error") {
    GeoSelectionContentView(
        state: .failure(CancellationError()),
        highlightedSectionTitle: "Selected country",
        allSectionTitle: "Change country",
        hasFlags: true,
        onItemTap: { _ in }
    )
}
#endif
