//
//  DefaultSelectableRowViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct DefaultSelectableRowViewModel<ID: Hashable>: Hashable, Identifiable {
    let id: ID
    let title: String
    let subtitle: String?
    let iconURL: URL?

    init(id: ID, title: String, subtitle: String?, iconURL: URL? = nil) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.iconURL = iconURL
    }
}
