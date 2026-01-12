//
//  NewsCategoryChipsView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemLocalization

struct NewsCategoryChipsView: View {
    let categories: [NewsDTO.Categories.Item]
    @Binding var selectedCategoryId: Int?

    private var chips: [Chip] {
        var result: [Chip] = [Chip(id: Constants.allCategoryId, title: Localization.commonAll)]
        result.append(contentsOf: categories.map { Chip(id: String($0.id), title: $0.name) })
        return result
    }

    @State private var selectedId: String? = Constants.allCategoryId

    var body: some View {
        HorizontalChipsView(
            chips: chips,
            selectedId: $selectedId,
            horizontalInset: Constants.horizontalChipsViewInset
        )
        .onChange(of: selectedId) { newValue in
            let newCategoryId: Int? = if newValue == Constants.allCategoryId {
                nil
            } else if let newValue {
                Int(newValue)
            } else {
                nil
            }

            // Avoid triggering update if value is the same
            guard selectedCategoryId != newCategoryId else { return }
            selectedCategoryId = newCategoryId
        }
        .onChange(of: selectedCategoryId) { newValue in
            let expectedSelectedId = newValue.map { String($0) } ?? Constants.allCategoryId

            // Avoid triggering update if value is the same
            guard selectedId != expectedSelectedId else { return }
            selectedId = expectedSelectedId
        }
    }
}

extension NewsCategoryChipsView {
    enum Constants {
        static let allCategoryId = Localization.commonAll
        static let horizontalChipsViewInset: CGFloat = 16
    }
}
