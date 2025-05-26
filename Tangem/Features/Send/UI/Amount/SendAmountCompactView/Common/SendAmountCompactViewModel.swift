//
//  SendAmountCompactViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class SendAmountCompactViewModel: ObservableObject, Identifiable {
    @Published var viewSize: CGSize = .zero

    let conventViewModel: ContentViewModel

    init(conventViewModel: ContentViewModel) {
        self.conventViewModel = conventViewModel

        switch conventViewModel {
        case .default:
            // Use the estimated size as initial value
            viewSize = .init(width: 361, height: 143)
        case .nft:
            // Static content size, therefore we can set `viewSize` to zero
            viewSize = .zero
        }
    }
}

// MARK: - Auxiliary types

extension SendAmountCompactViewModel {
    enum ContentViewModel {
        case `default`(viewModel: SendAmountCompactContentViewModel)
        case nft(viewModel: NFTSendAmountCompactContentViewModel)
    }
}
