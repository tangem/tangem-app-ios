//
//  DefaultWarningRowViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct DefaultWarningRowViewModel {
    let icon: Image
    let title: String
    let subtitle: String

    let action: () -> ()
}

extension DefaultWarningRowViewModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(subtitle)
    }

    static func == (lhs: DefaultWarningRowViewModel, rhs: DefaultWarningRowViewModel) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

extension DefaultWarningRowViewModel: Identifiable {
    var id: Int { hashValue }
}
