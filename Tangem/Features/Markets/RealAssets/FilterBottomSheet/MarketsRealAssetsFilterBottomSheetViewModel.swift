//
//  MarketsRealAssetsFilterBottomSheetViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLocalization
import protocol TangemUI.FloatingSheetContentViewModel

@MainActor
final class MarketsRealAssetsFilterBottomSheetViewModel: ObservableObject, FloatingSheetContentViewModel {
    @Published private(set) var selectedCategoryID: Int?
    @Published private(set) var selectedSectorID: Int?

    let categories: [MarketsDTO.Categories.Category]

    var selectedCategory: MarketsDTO.Categories.Category? {
        categories.first { $0.id == selectedCategoryID }
    }

    var sectorChipItems: [SectorChipItem] {
        guard let selectedCategory, !selectedCategory.sectors.isEmpty else {
            return []
        }

        let allItem = SectorChipItem(id: Constants.allSectorsID, sectorID: nil, title: Localization.commonAll)
        let sectorItems = selectedCategory.orderedSectors.map { sector in
            SectorChipItem(
                id: sector.code,
                sectorID: sector.id,
                title: MarketsCategoryLocalizer.title(for: sector, in: selectedCategory)
            )
        }

        return [allItem] + sectorItems
    }

    var showsFooter: Bool {
        selectedCategoryID != initialCategoryID || selectedSectorID != initialSectorID
    }

    private let defaultCategoryID: Int?
    private let defaultSectorID: Int?
    private let initialCategoryID: Int?
    private let initialSectorID: Int?
    private let onApply: (RealAssetsCategorySelection) -> Void
    private let dismissAction: () -> Void

    init(input: RealAssetsCategoryFilterInput, onDismiss: @escaping () -> Void) {
        let sortedCategories = input.categories.sorted(by: \.displayOrder)
        categories = sortedCategories
        onApply = input.onApply
        dismissAction = onDismiss

        let defaultIDs = Self.validatedIDs(of: input.defaultSelection, in: sortedCategories)
            ?? (sortedCategories.first?.id, nil)
        defaultCategoryID = defaultIDs.categoryID
        defaultSectorID = defaultIDs.sectorID

        let selectedIDs = Self.validatedIDs(of: input.selection, in: sortedCategories) ?? defaultIDs
        selectedCategoryID = selectedIDs.categoryID
        selectedSectorID = selectedIDs.sectorID
        initialCategoryID = selectedIDs.categoryID
        initialSectorID = selectedIDs.sectorID
    }

    func isSelected(category: MarketsDTO.Categories.Category) -> Bool {
        category.id == selectedCategoryID
    }

    func isSelected(sectorID: Int?) -> Bool {
        sectorID == selectedSectorID
    }

    func select(category: MarketsDTO.Categories.Category) {
        guard category.id != selectedCategoryID else { return }

        selectedCategoryID = category.id
        selectedSectorID = nil
    }

    func select(sectorID: Int?) {
        guard sectorID != selectedSectorID else { return }

        selectedSectorID = sectorID
    }

    func reset() {
        selectedCategoryID = defaultCategoryID
        selectedSectorID = defaultSectorID
    }

    func apply() {
        if let selectedCategory {
            let sector = selectedCategory.sectors.first { $0.id == selectedSectorID }
            onApply(RealAssetsCategorySelection(category: selectedCategory, sector: sector))
        }

        dismiss()
    }

    func close() {
        dismiss()
    }

    private func dismiss() {
        dismissAction()
    }

    private static func validatedIDs(
        of selection: RealAssetsCategorySelection,
        in categories: [MarketsDTO.Categories.Category]
    ) -> (categoryID: Int?, sectorID: Int?)? {
        guard let category = categories.first(where: { $0.id == selection.category.id }) else {
            return nil
        }

        let sectorID = category.sectors.first { $0.id == selection.sector?.id }?.id
        return (category.id, sectorID)
    }
}

extension MarketsRealAssetsFilterBottomSheetViewModel {
    struct SectorChipItem: Hashable, Identifiable {
        let id: String
        let sectorID: Int?
        let title: String
    }

    private enum Constants {
        static let allSectorsID = "all"
    }
}
