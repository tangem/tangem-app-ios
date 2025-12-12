//
//  DefaultPickerRowViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum PickerStyleType: Hashable {
    case segmented
    case menu
}

struct DefaultPickerRowViewModel: Hashable, Identifiable {
    var id: Int { hashValue }

    let title: String
    let options: [String]
    let displayTitles: [String]?
    let selection: BindingValue<String>
    let pickerStyle: PickerStyleType

    /// Titles to display in picker. Falls back to options if not provided.
    var displayOptions: [String] {
        displayTitles ?? options
    }

    init(
        title: String,
        options: [String],
        displayTitles: [String]? = nil,
        selection: BindingValue<String>,
        pickerStyle: PickerStyleType = .segmented
    ) {
        self.title = title
        self.options = options
        self.displayTitles = displayTitles
        self.selection = selection
        self.pickerStyle = pickerStyle
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(options)
        hasher.combine(displayTitles)
        hasher.combine(pickerStyle)
    }

    static func == (lhs: DefaultPickerRowViewModel, rhs: DefaultPickerRowViewModel) -> Bool {
        return lhs.title == rhs.title && lhs.options == rhs.options
            && lhs.displayTitles == rhs.displayTitles && lhs.pickerStyle == rhs.pickerStyle
    }
}
