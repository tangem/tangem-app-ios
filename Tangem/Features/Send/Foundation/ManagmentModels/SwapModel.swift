//
//  SwapModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemExpress
import TangemFoundation

protocol SwapModelRoutable: AnyObject {
    func openNetworkCurrency()
    func openApproveSheet()
    func openHighPriceImpactWarningSheetViewModel(viewModel: HighPriceImpactWarningSheetViewModel)
}

final class SwapModel {
    // MARK: - Data

    private let _sourceToken: CurrentValueSubject<LoadingResult<SendSourceToken, any Error>, Never>
    private let _receiveToken: CurrentValueSubject<LoadingResult<SendSourceToken, any Error>, Never>
    private let _amount: CurrentValueSubject<SendAmount?, Never>

    private let _availableProviders = CurrentValueSubject<LoadingResult<[ExpressAvailableProvider], any Error>?, Never>(.none)
    private let _selectedProvider = CurrentValueSubject<LoadingResult<ExpressAvailableProvider, any Error>?, Never>(.none)

    private let _transactionTime = PassthroughSubject<Date?, Never>()
    private let _transactionURL = PassthroughSubject<URL?, Never>()
    private let _isSending = CurrentValueSubject<Bool, Never>(false)

    // MARK: - Dependencies

    weak var router: SendModelRoutable?
    weak var alertPresenter: SendViewAlertPresenter?

    // MARK: - Private injections

    private let expressManager: ExpressManager
    private let expressPairsRepository: ExpressPairsRepository
    private let expressPendingTransactionRepository: ExpressPendingTransactionRepository
    private let expressDestinationService: ExpressDestinationService
    private let expressAPIProvider: ExpressAPIProvider

    private var updateTask: Task<Void, Never>?

    init(
        sourceToken: SendSourceToken?,
        receiveToken: SendSourceToken?,
        expressManager: ExpressManager,
        expressPairsRepository: ExpressPairsRepository,
        expressPendingTransactionRepository: ExpressPendingTransactionRepository,
        expressDestinationService: ExpressDestinationService,
        expressAPIProvider: ExpressAPIProvider
    ) {
        self.expressManager = expressManager
        self.expressPairsRepository = expressPairsRepository
        self.expressPendingTransactionRepository = expressPendingTransactionRepository
        self.expressDestinationService = expressDestinationService
        self.expressAPIProvider = expressAPIProvider

        _sourceToken = .init(sourceToken.map { .success($0) } ?? .loading)
        _receiveToken = .init(receiveToken.map { .success($0) } ?? .loading)
        _amount = .init(.none)

        Task { await initialLoading() }
    }
}

// MARK: - Changes -> ExpressManager

extension SwapModel {
    
}

// MARK: - Changes -> ExpressManager

extension SwapModel {
    func update(source wallet: SendSourceToken) {
        ExpressLogger.info("Will update source to \(wallet)")

        _sourceToken.send(.success(wallet))
        swappingPairDidChange()
    }

    func update(receive wallet: SendSourceToken) {
        ExpressLogger.info("Will update receive to \(wallet as Any)")

        _receiveToken.send(.success(wallet))
        swappingPairDidChange()
    }

    func swappingPairDidChange() {
        updateTask { owner in
            guard let source = owner._sourceToken.value.value, let destination = owner._receiveToken.value.value else {
                ExpressLogger.info("Source / Receive not found")
                let provider = try await owner.expressManager.update(pair: .none)
                return provider
            }

            let pair = ExpressManagerSwappingPair(source: source, destination: destination)
            let provider = try await owner.expressManager.update(pair: pair)
            return provider
        }
    }

    func updateTask(block: @escaping (_ model: SwapModel) async throws -> ExpressAvailableProvider?) {
        updateTask?.cancel()
        updateTask = runTask(in: self, code: { input in
            do {
                switch try await block(input) {
                case .none:
                    input._availableProviders.send(.none)
                    input._selectedProvider.send(.none)

                case .some(let selectedProvider):
                    input._selectedProvider.send(.success(selectedProvider))
                }
            } catch {
                input._selectedProvider.send(.failure(error))
            }
        })
    }
}

// MARK: - Initial (pair) loading

extension SwapModel {
    func initialLoading() async {
        do {
            switch (_sourceToken.value, _receiveToken.value) {
            case (.success, .success):
                // All already set
                swappingPairDidChange()

            case (.success(let source), _):
                try await expressPairsRepository.updatePairs(
                    for: source.tokenItem.expressCurrency,
                    userWalletInfo: source.userWalletInfo
                )

                _receiveToken.send(.loading)
                // let destination = try await expressDestinationService.getDestination(source: source)
                // update(receive: destination)

            case (_, .success(let destination)):
                try await expressPairsRepository.updatePairs(
                    for: destination.tokenItem.expressCurrency,
                    userWalletInfo: destination.userWalletInfo
                )

                _sourceToken.send(.loading)
                // let source = try await expressDestinationService.getSource(destination: destination)
                // update(source: source)

            default:
                assertionFailure("Wrong case. Check implementation")
                _sourceToken.send(.failure(ExpressInteractorError.sourceNotFound))
                _receiveToken.send(.failure(ExpressInteractorError.destinationNotFound))
            }
        } catch ExpressDestinationServiceError.sourceNotFound(let destination) {
            Analytics.log(.swapNoticeNoAvailableTokensToSwap)
            ExpressLogger.info("Source not found")
            _sourceToken.send(.failure(ExpressDestinationServiceError.sourceNotFound(destination: destination)))
            // return .noSourceTokens(destination: destination.tokenItem)
        } catch ExpressDestinationServiceError.destinationNotFound(let source) {
            Analytics.log(.swapNoticeNoAvailableTokensToSwap)
            ExpressLogger.info("Destination not found")
            _receiveToken.send(.failure(ExpressDestinationServiceError.destinationNotFound(source: source)))
            // return .noDestinationTokens(source: source.tokenItem)
        } catch {
            ExpressLogger.info("Update pairs failed with error: \(error)")

            if _receiveToken.value.isLoading {
                _receiveToken.send(.failure(error))
            }

            if _sourceToken.value.isLoading {
                _sourceToken.send(.failure(error))
            }
        }
    }

}

extension SwapModel {
    enum SwappingPairState {
        case loading
    }

    typealias Source = LoadingResult<SendSourceToken, Error>
    typealias Destination = LoadingResult<SendSourceToken, Error>

    struct SwappingPair {
        var sender: Source
        var destination: Destination?
    }
}
