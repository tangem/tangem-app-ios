//
//  DefaultMenuRowViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

protocol DefaultMenuRowViewModelAction: Identifiable, Hashable {
    var title: String { get }
}

struct DefaultMenuRowViewModel<Action: DefaultMenuRowViewModelAction> {
    let title: String
    let actions: [Action]

    init(title: String, actions: [Action]) {
        self.title = title
        self.actions = actions
    }
}

extension DefaultMenuRowViewModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(actions)
    }

    static func == (lhs: DefaultMenuRowViewModel, rhs: DefaultMenuRowViewModel) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

extension DefaultMenuRowViewModel: Identifiable {
    var id: Int { hashValue }
}
