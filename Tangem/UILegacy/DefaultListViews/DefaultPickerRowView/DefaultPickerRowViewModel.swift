//
//  DefaultPickerRowViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct DefaultPickerRowViewModel: Hashable, Identifiable {
    var id: Int { hashValue }

    let title: String
    let options: [String]
    let displayTitles: [String]?
    let selection: BindingValue<String>

    /// Titles to display in picker. Falls back to options if not provided.
    var displayOptions: [String] {
        displayTitles ?? options
    }

    init(title: String, options: [String], displayTitles: [String]? = nil, selection: BindingValue<String>) {
        self.title = title
        self.options = options
        self.displayTitles = displayTitles
        self.selection = selection
    }
}
