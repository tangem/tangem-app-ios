//
//  WCFeeInteractorType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemFoundation

struct WCFee: Hashable {
    let option: FeeOption
    let value: LoadingResult<Fee, any Error>

    func hash(into hasher: inout Hasher) {
        hasher.combine(option)

        switch value {
        case .loading:
            hasher.combine("loading")
        case .success(let value):
            hasher.combine(value)
        case .failure(let error):
            hasher.combine(error.localizedDescription)
        }
    }

    static func == (lhs: WCFee, rhs: WCFee) -> Bool {
        guard lhs.option == rhs.option else { return false }

        switch (lhs.value, rhs.value) {
        case (.loading, .loading):
            return true
        case (.success(let lhsValue), .success(let rhsValue)):
            return lhsValue == rhsValue
        case (.failure(let lhsError), .failure(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

extension WCFee: CustomStringConvertible {
    var description: String {
        return "WCFee(option: \(option), value: \(value))"
    }
}

protocol WCFeeInteractorType {
    var selectedFee: WCFee { get }
    var fees: [WCFee] { get }
    var selectedFeePublisher: AnyPublisher<WCFee, Never> { get }
    var customFeeService: WCCustomEvmFeeService { get }

    func retryFeeLoading()
}

protocol WCFeeInteractorOutput: AnyObject {
    func feeDidChanged(fee: WCFee)
    func returnToTransactionDetails()
}
