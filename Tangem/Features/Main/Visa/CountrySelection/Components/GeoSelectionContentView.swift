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
    let suggestedSectionTitle: String?
    let allSectionTitle: String?
    let hasFlags: Bool
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
                spacing: Constants.sectionSpacing,
                pinnedViews: [.sectionHeaders]
            ) {
                if let suggested = sections.suggested {
                    Section {
                        row(suggested)
                    } header: {
                        if let suggestedSectionTitle {
                            header(suggestedSectionTitle)
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
    }

    func row(_ item: GeoSelectionItem) -> some View {
        Row(title: item.title)
            .start {
                if hasFlags {
                    CountryFlagView(url: item.flagURL)
                }
            }
            .onTap { onItemTap(item.id) }
    }

    func header(_ title: String) -> some View {
        Text(title)
            .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Constants.horizontalPadding)
            .padding(.vertical, Constants.titleVerticalPadding)
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
            GeoSelectionSections(suggested: nil, all: GeoSelectionItem.previewCountries)
        ),
        suggestedSectionTitle: nil,
        allSectionTitle: nil,
        hasFlags: true,
        onItemTap: { _ in }
    )
}

#Preview("Regions with suggestion") {
    GeoSelectionContentView(
        state: .success(
            GeoSelectionSections(
                suggested: GeoSelectionItem.previewRegions[1],
                all: GeoSelectionItem.previewRegions
            )
        ),
        suggestedSectionTitle: "Suggested state",
        allSectionTitle: "Select another state",
        hasFlags: false,
        onItemTap: { _ in }
    )
}

#Preview("Loading") {
    GeoSelectionContentView(
        state: .loading,
        suggestedSectionTitle: "Suggested country",
        allSectionTitle: "Change country",
        hasFlags: true,
        onItemTap: { _ in }
    )
}

#Preview("Empty") {
    GeoSelectionContentView(
        state: .success(GeoSelectionSections(suggested: nil, all: [])),
        suggestedSectionTitle: "Suggested country",
        allSectionTitle: "Change country",
        hasFlags: true,
        onItemTap: { _ in }
    )
}

#Preview("Error") {
    GeoSelectionContentView(
        state: .failure(CancellationError()),
        suggestedSectionTitle: "Suggested country",
        allSectionTitle: "Change country",
        hasFlags: true,
        onItemTap: { _ in }
    )
}
#endif
