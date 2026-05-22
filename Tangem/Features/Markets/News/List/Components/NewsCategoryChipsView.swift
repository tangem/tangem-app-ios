//
//  NewsCategoryChipsView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI
import TangemFoundation

struct NewsCategoryChipsView: View {
    let categories: [NewsDTO.Categories.Item]
    @Binding var selectedCategoryId: Int?

    var body: some View {
        if FeatureProvider.isAvailable(.redesign) {
            redesignContent
        } else {
            legacyContent
        }
    }

    // MARK: - Redesign

    private var redesignContent: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            TangemTabs(
                data: redesignTabs,
                selection: redesignSelectionBinding
            )
            .padding(.horizontal, Constants.horizontalChipsViewInset)
        }
    }

    private var redesignTabs: [Tab] {
        var result: [Tab] = [Tab(id: Constants.allCategoryId, title: Localization.commonAll)]
        result.append(contentsOf: categories.map { Tab(id: String($0.id), title: $0.name) })
        return result
    }

    private var redesignSelectionBinding: Binding<Tab> {
        Binding(
            get: {
                let id = selectedCategoryId.map { String($0) } ?? Constants.allCategoryId
                return redesignTabs.first { $0.id == id } ?? redesignTabs[0]
            },
            set: { newValue in
                if newValue.id == Constants.allCategoryId {
                    selectedCategoryId = nil
                } else {
                    selectedCategoryId = Int(newValue.id)
                }
            }
        )
    }

    // MARK: - Legacy

    private var legacyContent: some View {
        HorizontalChipsView(
            chips: legacyChips,
            selectedId: legacySelectedIdBinding,
            horizontalInset: Constants.horizontalChipsViewInset
        )
    }

    private var legacyChips: [Chip] {
        var result: [Chip] = [Chip(id: Constants.allCategoryId, title: Localization.commonAll)]
        result.append(contentsOf: categories.map { Chip(id: String($0.id), title: $0.name) })
        return result
    }

    private var legacySelectedIdBinding: Binding<String?> {
        Binding(
            get: { selectedCategoryId.map { String($0) } ?? Constants.allCategoryId },
            set: { newValue in
                if newValue == Constants.allCategoryId {
                    selectedCategoryId = nil
                } else if let newValue {
                    selectedCategoryId = Int(newValue)
                } else {
                    selectedCategoryId = nil
                }
            }
        )
    }
}

extension NewsCategoryChipsView {
    enum Constants {
        static let allCategoryId = Localization.commonAll
        static let horizontalChipsViewInset: CGFloat = 16
    }

    fileprivate struct Tab: TangemTabsTextProvider {
        let id: String
        let title: String

        var text: String { title }
    }
}
