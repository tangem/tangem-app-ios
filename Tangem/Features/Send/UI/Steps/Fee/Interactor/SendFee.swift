//
//  SendFee.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemFoundation

/// Generic fee type on the `TangemApp` layer
struct TokenFee: Hashable {
    let option: FeeOption
    let tokenItem: TokenItem
    let value: BSDKFee

    var asSendFee: SendFee {
        .init(option: option, tokenItem: tokenItem, value: .success(value))
    }
}

typealias LoadableFees = [SendFee]

extension [SendFee] {
    var hasMultipleFeeOptions: Bool { unique(by: \.option).count > 1 }

    func wrapToLoadingResult() -> LoadingResult<[TokenFee], any Error> {
        if contains(where: { $0.value.isLoading }) {
            return .loading
        }

        if let error = first(where: { $0.value.isFailure })?.value.error {
            return .failure(error)
        }

        let fees = compactMap { sendFee in
            if let fee = sendFee.value.value {
                return TokenFee(option: sendFee.option, tokenItem: sendFee.tokenItem, value: fee)
            }

            return nil
        }

        assert(count == fees.count, "Some SendFee doesn't have fee value")
        return .success(fees)
    }
}

// protocol LoadableFees {
//    var feeTokenItem: TokenItem { get }
//    var options: [FeeOption] { get }
//    var fees: [SendFee] { get }
//
//    var isLoading: Bool { get }
//    var isError: Bool { get }
// }
//
// extension LoadableFees {
//    var hasMultipleFeeOptions: Bool { options.unique().count > 1 }
// }

// struct SingleOptionLoadableFees: LoadableFees {
//    let feeTokenItem: TokenItem
//    let options: [FeeOption] = [.market]
//    var fees: [SendFee] { [marketFee] }
//
//    var isLoading: Bool { state.isLoading }
//    var isError: Bool { state.isFailure }
//
//    var marketFee: SendFee {
//        switch state {
//        case .loading:
//            SendFee(option: .market, tokenItem: feeTokenItem, value: .loading)
//        case .failure(let error):
//            SendFee(option: .market, tokenItem: feeTokenItem, value: .failure(error))
//        case .success(let loadedFee):
//            SendFee(option: .market, tokenItem: feeTokenItem, value: .success(loadedFee))
//        }
//    }
//
//    private(set) var state: LoadingResult<BSDKFee, any Error>
//
//    init(feeTokenItem: TokenItem, state: LoadingResult<BSDKFee, any Error>) {
//        self.feeTokenItem = feeTokenItem
//        self.state = state
//    }
//
//    mutating func update(state: LoadingResult<BSDKFee, any Error>) {
//        self.state = state
//    }
// }
//

struct SendFee: Hashable {
    let option: FeeOption
    let tokenItem: TokenItem
    let value: LoadingResult<BSDKFee, any Error>

    func hash(into hasher: inout Hasher) {
        hasher.combine(option)
        hasher.combine(tokenItem)

        switch value {
        case .loading:
            hasher.combine("loading")
        case .success(let value):
            hasher.combine(value)
        case .failure(let error):
            hasher.combine(error.localizedDescription)
        }
    }

    static func == (lhs: SendFee, rhs: SendFee) -> Bool {
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
