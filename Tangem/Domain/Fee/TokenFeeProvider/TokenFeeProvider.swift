//
//  TokenFeeProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

/// Has state
/// created with SendingTokenItem
protocol TokenFeeProvider {
    var feeTokenItem: TokenItem { get }
    var fees: [TokenFee] { get }
    var feesPublisher: AnyPublisher<[TokenFee], Never> { get }

    func updateFees()
}


protocol StatableTokenFeeProvider: AnyObject {
    var supportingFeeOption: [FeeOption] { get }
    var feeTokenItem: TokenItem { get }

    var loadingFees: LoadingResult<[BSDKFee], any Error> { get }
    var loadingFeesPublisher: AnyPublisher<LoadingResult<[BSDKFee], any Error>, Never> { get }
}

extension StatableTokenFeeProvider {
    func mapToFees(loadingFees fees: LoadingResult<[BSDKFee], any Error>) -> [TokenFee] {
        switch fees {
        case .loading:
            TokenFeeConverter.mapToLoadingSendFees(options: supportingFeeOption, feeTokenItem: feeTokenItem)
        case .failure(let error):
            TokenFeeConverter.mapToFailureSendFees(options: supportingFeeOption, feeTokenItem: feeTokenItem, error: error)
        case .success(let loadedFees):
            TokenFeeConverter
                .mapToSendFees(fees: loadedFees, feeTokenItem: feeTokenItem)
                .filter { supportingFeeOption.contains($0.option) }
        }
    }
}

/// Wrappers
/// 1. ExpressFeeProvider (add autoselect to as ExpressFee to use it in transaction)
/// 2. TokenFeeProvider (add autoupdate fee and push to output - SendModel)
/// 3. SendWithSwapFeeProvider (Has switcher to select between two providers)
/// 4. StakingFeeProvider (Basically don't support update. Can be simple provider. Without external changes)
/// 5. Sell, NFT (Can be use only only TokenFeeProvider if possible)
extension TokenFeeProvider where Self: StatableTokenFeeProvider {
    var fees: [TokenFee] {
        mapToFees(loadingFees: loadingFees)
    }

    var feesPublisher: AnyPublisher<[TokenFee], Never> {
        loadingFeesPublisher
            .withWeakCaptureOf(self)
            .map { $0.mapToFees(loadingFees: $1) }
            .eraseToAnyPublisher()
    }
}

protocol UpdatableSimpleTokenFeeProvider: TokenFeeProvider {
    var tokenItems: [TokenItem] { get }
    var tokenItemsPublisher: AnyPublisher<[TokenItem], Never> { get }

    func userDidSelectTokenItem(_ tokenItem: TokenItem)
}

// WalletModel ->
// [TokenFeeProviders] -> FeeSelectorInteractor (as fees and update if was selected)
// [TokenFeeProviders].forEach { $.setup(types: ) }

// it will be use in SendModel.
struct SendFeeManager: TokenFeeProvider {
    let sendFeeSelectorInteractor: FeeSelectorInteractor
    let expressFeeSelectorInteractor: FeeSelectorInteractor

    var activeFeeSelectorInteractor: FeeSelectorInteractor { sendFeeSelectorInteractor }

    var feeTokenItem: TokenItem { activeFeeSelectorInteractor.selectedFee!.tokenItem }
    var fees: [TokenFee] { activeFeeSelectorInteractor.fees }
    var feesPublisher: AnyPublisher<[TokenFee], Never> { activeFeeSelectorInteractor.feesPublisher }
    func updateFees() {
        activeFeeSelectorInteractor.userDidSelect(feeTokenItem: <#T##TokenItem#>)
    }
}

class TokenFeeProviderModable {
    let feeLoader: any TokenFeeLoader

    init(feeLoader: any TokenFeeLoader) {
        self.feeLoader = feeLoader
    }

    var selectedMode: TokenFeeProviderModeType?
    var fees: [BSDKFee] = []

    func updateFees() {
        switch selectedMode {
        case .getFee(let amount, let destination):
            Task { self.fees = try await feeLoader.getFee(amount: amount, destination: destination) }
        default:
            break
        }
    }

    // From send. in SendModel for every update amount / destination. Update all providers mode
    // 
    func setup(mode: TokenFeeProviderModeType) {
        
    }
}

enum TokenFeeProviderModeType {
    case estimatedFee(amount: Decimal)
    case getFee(amount: Decimal, destination: String)

    // Express
    case expressEstimatedFee(estimatedGasLimit: Int)
    case expressGetFee(amount: BSDKAmount, destination: String, txData: Data)
    case expressGetGaslessFee(amount: BSDKAmount, destination: String, txData: Data, feeToken: BSDKToken)
}
