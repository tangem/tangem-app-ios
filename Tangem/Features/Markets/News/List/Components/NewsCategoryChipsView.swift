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

struct NewsCategoryChipsView: View {
    let categories: [NewsDTO.Categories.Item]
    @Binding var selectedCategoryId: Int?

    private var chips: [Chip] {
        var result: [Chip] = [Chip(id: Constants.allCategoryId, title: Localization.commonAll)]
        result.append(contentsOf: categories.map { Chip(id: String($0.id), title: $0.name) })
        return result
    }

    private var selectedIdBinding: Binding<String?> {
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

    var body: some View {
        HorizontalChipsView(
            chips: chips,
            selectedId: selectedIdBinding,
            horizontalInset: Constants.horizontalChipsViewInset
        )
    }
}

extension NewsCategoryChipsView {
    enum Constants {
        static let allCategoryId = Localization.commonAll
        static let horizontalChipsViewInset: CGFloat = 16
    }
}
