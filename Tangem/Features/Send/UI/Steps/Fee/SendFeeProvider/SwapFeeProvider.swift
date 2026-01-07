//
//  SwapFeeProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

// final class SwapFeeProvider {
//    private let swapManager: SwapManager
//
//    init(swapManager: SwapManager) {
//        self.swapManager = swapManager
//    }
// }
//
//// MARK: - SendFeeProvider
//
// extension SwapFeeProvider: SendFeeProvider {
//    var fees: [TokenFee] {
//        swapManager.swappingPair.sender.value?.tokenFeeProvider.fees ?? []
//    }
//
//    var feesPublisher: AnyPublisher<[TokenFee], Never> {
//        swapManager.swappingPairPublisher
//            .compactMap { $0.sender.value }
//            .flatMapLatest { $0.tokenFeeProvider.feesPublisher }
//            .eraseToAnyPublisher()
//    }
//
//    func updateFees() {
//        swapManager.updateFees()
//    }
// }
