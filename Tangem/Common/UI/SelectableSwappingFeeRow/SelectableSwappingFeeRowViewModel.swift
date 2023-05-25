//
//  SelectableSwappingFeeRowViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct SelectableSwappingFeeRowViewModel: Hashable, Identifiable {
    var id: Int { hashValue }

    let title: String
    let subtitle: String
    let isSelected: BindingValue<Bool>
}
