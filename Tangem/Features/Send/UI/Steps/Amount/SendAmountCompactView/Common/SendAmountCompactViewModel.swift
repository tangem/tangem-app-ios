//
//  SendAmountCompactViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class SendAmountCompactViewModel: ObservableObject, Identifiable {
    @Published var viewSize: CGSize = .init(width: 361, height: 143)

    let conventViewModel: SendAmountCompactContentViewModel

    init(conventViewModel: SendAmountCompactContentViewModel) {
        self.conventViewModel = conventViewModel
    }
}
