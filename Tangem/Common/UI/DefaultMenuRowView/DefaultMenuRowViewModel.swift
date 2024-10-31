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

struct DefaultMenuRowViewModel<Action: DefaultMenuRowViewModelAction>: Hashable, Identifiable {
    var id: Int { hashValue }

    let title: String
    let actions: [Action]
}
