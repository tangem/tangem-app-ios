//
//  YieldService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

// public protocol YieldService {
//    var yieldMarketsPublisher: AnyPublisher<[YieldMarketInfo]?, Never> { get }
//    func getYieldMarkets()
// }
//
// public struct CommonYieldService: YieldService {
//    [REDACTED_USERNAME](\.tangemApiService) private var tangemApiService: TangemApiService
//    private let yieldMarketsSubject = CurrentValueSubject<[YieldMarketInfo]?, Never>(nil)
//
//    public var yieldMarketsPublisher: AnyPublisher<[YieldMarketInfo]?, Never> {
//        yieldMarketsSubject.eraseToAnyPublisher()
//    }
//
//    public func getYieldMarkets() {
//        #warning("Implement getYieldMarkets")
//        fatalError("Unimplemented")
//    }
// }
