//
//  CommonTokenFeeProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemMacro

let FeeLogger = AppLogger.tag("TokenFeeProvider")

final class CommonTokenFeeProvider {
    let feeTokenItem: TokenItem
    let tokenFeeLoader: any TokenFeeLoader
    let customFeeProvider: (any CustomFeeProvider)?
    let feeTokenItemBalanceProvider: TokenBalanceProvider
    let supportingOptions: TokenFeeProviderSupportingOptions

    private let balanceConverter = BalanceConverter()
    private let balanceFormatter = BalanceFormatter()

    private var tokenFeeProviderInputData: TokenFeeProviderInputData?

    private let stateSubject: CurrentValueSubject<TokenFeeProviderState, Never> = .init(.idle)
    private let selectedFeeOptionSubject: CurrentValueSubject<FeeOption, Never> = .init(.market)

    private var updatingFeeTask: Task<Void, Never>?

    private var customFeeProviderInitialSetupCancellable: AnyCancellable?
    private var feeTokenItemBalanceStateCancellable: AnyCancellable?

    init(
        feeTokenItem: TokenItem,
        tokenFeeLoader: any TokenFeeLoader,
        customFeeProvider: (any CustomFeeProvider)?,
        feeTokenItemBalanceProvider: TokenBalanceProvider,
        supportingOptions: TokenFeeProviderSupportingOptions,
    ) {
        self.feeTokenItem = feeTokenItem
        self.tokenFeeLoader = tokenFeeLoader
        self.customFeeProvider = customFeeProvider
        self.feeTokenItemBalanceProvider = feeTokenItemBalanceProvider
        self.supportingOptions = supportingOptions

        bind()
    }
}

// MARK: - TokenFeeProvider

extension CommonTokenFeeProvider: TokenFeeProvider {
    var balanceFeeTokenState: TokenBalanceType { feeTokenItemBalanceProvider.balanceType }
    var balanceTypePublisher: AnyPublisher<TokenBalanceType, Never> { feeTokenItemBalanceProvider.balanceTypePublisher }
    var formattedFeeTokenBalance: FormattedTokenBalanceType {
        let currencyId = feeTokenItem.currencyId
        let currencySymbol = feeTokenItem.currencySymbol

        let builder = FormattedTokenBalanceTypeBuilder(format: { [balanceConverter, balanceFormatter] cryptoValue in
            if let cryptoValue,
               let currencyId,
               let fiatValue = balanceConverter.convertToFiat(cryptoValue, currencyId: currencyId) {
                return balanceFormatter.formatFiatBalance(fiatValue)
            }

            return balanceFormatter.formatCryptoBalance(cryptoValue, currencyCode: currencySymbol)
        })

        return builder.mapToFormattedTokenBalanceType(type: feeTokenItemBalanceProvider.balanceType)
    }

    var hasMultipleFeeOptions: Bool {
        if case .available(let fees) = state {
            return fees.count > 1
        }
        return false
    }

    var state: TokenFeeProviderState {
        guard let customFee = customFeeProvider?.customFee else {
            return stateSubject.value
        }

        guard case .available(var fees) = stateSubject.value else {
            return stateSubject.value
        }

        fees[.custom] = customFee
        let filtered = filterBySupportingOptions(fees: fees)

        return .available(filtered)
    }

    var statePublisher: AnyPublisher<TokenFeeProviderState, Never> {
        guard let customFeePublisher = customFeeProvider?.customFeePublisher else {
            return stateSubject.eraseToAnyPublisher()
        }

        return Publishers
            .CombineLatest(stateSubject, customFeePublisher)
            .withWeakCaptureOf(self)
            .map { provider, args in
                let (state, customFee) = args
                guard case .available(var fees) = state else {
                    return state
                }

                fees[.custom] = customFee
                let filtered = provider.filterBySupportingOptions(fees: fees)

                return .available(filtered)
            }
            .eraseToAnyPublisher()
    }

    var selectedTokenFee: TokenFee {
        mapToLoadableTokenFee(
            state: state,
            selectedFeeOption: selectedFeeOptionSubject.value
        )
    }

    var selectedTokenFeePublisher: AnyPublisher<TokenFee, Never> {
        Publishers
            .CombineLatest(statePublisher, selectedFeeOptionSubject)
            .withWeakCaptureOf(self)
            .map { $0.mapToLoadableTokenFee(state: $1.0, selectedFeeOption: $1.1) }
            .eraseToAnyPublisher()
    }

    func select(feeOption: FeeOption) {
        let supportedByState: Bool = {
            if case .available(let fees) = stateSubject.value {
                return fees.keys.contains(feeOption)
            }
            return feeOption == .market
        }()

        let supportedByRestrictions = switch supportingOptions {
        case .all: true
        case .exactly(let options): options.contains(feeOption)
        }

        if supportedByState || supportedByRestrictions {
            selectedFeeOptionSubject.send(feeOption)
        }
    }

    func setup(input: TokenFeeProviderInputData) {
        tokenFeeProviderInputData = input
        updateSupportingState(input: input)
    }

    func updateFees() -> Task<Void, Never> {
        updatingFeeTask?.cancel()

        let task = Task { await updateFees() }
        updatingFeeTask = task

        return task
    }

    private func updateFees() async {
        guard let input = tokenFeeProviderInputData else {
            FeeLogger.error(self, error: "TokenFeeProvider Didn't setup with any input data")
            updateState(state: .unavailable(.inputDataNotSet))
            return
        }

        do {
            let task = runWithDelayedLoading { [weak self] in
                self?.updateState(state: .loading)
            } operation: { [weak self] in
                try await self?.loadFees(input: input) ?? []
            }

            let loadedFees = try await task.value
            try Task.checkCancellation()

            let fees = mapToFeesDictionary(fees: loadedFees)
            let supportingFees = filterBySupportingOptions(fees: fees)

            updateState(state: .available(supportingFees))

        } catch TokenFeeLoaderError.tokenFeeLoaderNotFound {
            updateState(state: .unavailable(.notSupported))
        } catch TokenFeeLoaderError.gaslessExecutionReverted(let gaslessMinAmount) {
            // Convert gaslessMinAmount from smallest token units to decimal value to match the balance scale
            let threshold = gaslessMinAmount / feeTokenItem.decimalValue

            if let balance = feeTokenItemBalanceProvider.balanceType.value, balance < threshold {
                updateState(state: .unavailable(.notEnoughFeeBalance))
            } else {
                updateState(state: .error(TokenFeeLoaderError.executionReverted))
            }
        } catch TokenFeeLoaderError.notEnoughFeeBalance {
            updateState(state: .unavailable(.notEnoughFeeBalance))
        } catch is CancellationError {
            updateState(state: .idle)
        } catch {
            updateState(state: .error(error))
        }
    }

    private func loadFees(input: TokenFeeProviderInputData) async throws -> [BSDKFee] {
        switch input {
        case .common(let amount, let destination):
            return try await updateFees(amount: amount, destination: destination)

        case .cex(let amount):
            return try await updateFees(amount: amount)

        case .dex(.ethereumEstimate(let estimatedGasLimit, let otherNativeFee)):
            return try await updateFees(estimatedGasLimit: estimatedGasLimit, otherNativeFee: otherNativeFee)

        case .dex(.ethereum(let amount, let destination, let txData, let otherNativeFee)):
            return try await updateFees(amount: amount, destination: destination, txData: txData, otherNativeFee: otherNativeFee)

        case .approveWithSwap(let amount, let destination, let txData, let otherNativeFee, let approveInput):
            return try await updateApproveWithSwapFees(
                amount: amount,
                destination: destination,
                txData: txData,
                otherNativeFee: otherNativeFee,
                approveInput: approveInput
            )

        case .dex(.solana(let data)):
            return try await updateFees(compiledTransaction: data)

        case .dex(.bitcoinPsbt(let psbtBase64)):
            guard FeatureProvider.isAvailable(.bitcoinDexSwap) else {
                throw TokenFeeLoaderError.tokenFeeLoaderNotFound
            }

            return try await updateFees(psbtBase64: psbtBase64)

        case .approve(let txData, let toContractAddress, let feeMultiplier):
            let zeroAmount = BSDKAmount(with: feeTokenItem.blockchain, type: .coin, value: 0)
            let allFees = try await updateFees(amount: zeroAmount, destination: toContractAddress, txData: txData, otherNativeFee: nil)

            // Approve flow never shows a speed selector — only market fee is needed.
            // [safe: 1] = market for EIP-1559 (3 fees), fallback to [safe: 0] for single-fee (gasless).
            guard let marketFee = allFees[safe: 1] ?? allFees[safe: 0] else {
                throw TokenFeeProviderError.feeNotFound
            }

            guard feeMultiplier != .single else { return [marketFee] }

            var scaledAmount = marketFee.amount
            scaledAmount.value *= feeMultiplier.rawValue
            return [BSDKFee(scaledAmount, parameters: marketFee.parameters)]
        }
    }
}

// MARK: - Private

private extension CommonTokenFeeProvider {
    func bind() {
        customFeeProviderInitialSetupCancellable = customFeeProvider?.subscribeToInitialSetup(
            tokenFeeProvider: self
        )

        let allowsZeroFeePaid = feeTokenItem.blockchain.allowsZeroFeePaid

        feeTokenItemBalanceStateCancellable = feeTokenItemBalanceProvider
            .balanceTypePublisher
            .map { $0.value ?? 0 }
            .map { allowsZeroFeePaid ? $0 >= 0 : $0 > 0 }
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { feeProvider, hasFeeCurrency in
                if hasFeeCurrency {
                    if case .unavailable(.noTokenBalance) = feeProvider.stateSubject.value {
                        feeProvider.updateState(state: .idle)
                    }
                } else {
                    feeProvider.updateState(state: .unavailable(.noTokenBalance))
                }
            }
    }

    func updateSupportingState(input: TokenFeeProviderInputData?) {
        switch input {
        case .none:
            updateState(state: .unavailable(.inputDataNotSet))
        case .common, .cex:
            // Always available. Do nothing
            break
        case .dex(.ethereumEstimate) where tokenFeeLoader is EthereumTokenFeeLoader,
             .dex(.ethereum) where tokenFeeLoader is EthereumTokenFeeLoader:
            // Is available. Do nothing
            break
        case .dex(.solana) where tokenFeeLoader is SolanaTokenFeeLoader:
            // Is available. Do nothing
            break
        case .dex(.bitcoinPsbt) where tokenFeeLoader is BitcoinTokenFeeLoader && FeatureProvider.isAvailable(.bitcoinDexSwap):
            // Is available. Do nothing
            break
        case .dex:
            // DEX but tokenFeeLoader is not (EthereumTokenFeeLoader or SolanaTokenFeeLoader)
            updateState(state: .unavailable(.notSupported))
        case .approve(_, _, let feeMultiplier) where tokenFeeLoader is CommonGaslessTokenFeeLoader && feeMultiplier == .triple && !FeatureProvider.isAvailable(.usdtRevokeGaslessFee):
            updateState(state: .unavailable(.notSupported))
        case .approve where tokenFeeLoader is EthereumTokenFeeLoader:
            // ERC-20 approve — available for Ethereum loaders (includes gasless)
            break
        case .approve:
            // Approve but tokenFeeLoader is not EthereumTokenFeeLoader
            updateState(state: .unavailable(.notSupported))
        case .approveWithSwap where tokenFeeLoader is EthereumTokenFeeLoader:
            // One-tap approve+swap is EVM-only (allowance + state override)
            break
        case .approveWithSwap:
            updateState(state: .unavailable(.notSupported))
        }
    }

    func updateState(state: TokenFeeProviderState) {
        switch state {
        case .idle, .available, .loading:
            FeeLogger.info(self, "Will update state to \(state)")
        case .unavailable:
            FeeLogger.warning(self, "Will update state to \(state)")
        case .error(let error):
            FeeLogger.error(self, "Will update state", error: error)
        }

        stateSubject.send(state)
    }

    func filterBySupportingOptions(fees: [FeeOption: BSDKFee]) -> [FeeOption: BSDKFee] {
        switch supportingOptions {
        case .all:
            return fees
        case .exactly(let options):
            return fees.filter { options.contains($0.key) }
        }
    }
}

// MARK: - FeeSelectorCustomFeeDataProviding

extension CommonTokenFeeProvider: FeeSelectorCustomFeeDataProviding {}

// MARK: - Mapping

private extension CommonTokenFeeProvider {
    func mapToFeesDictionary(fees: [BSDKFee]) -> [FeeOption: BSDKFee] {
        switch fees.count {
        case 1:
            return [.market: fees[0]]
        case 2:
            return [.market: fees[0], .fast: fees[1]]
        case 3:
            return [.slow: fees[0], .market: fees[1], .fast: fees[2]]
        default:
            assertionFailure("Wrong count of fees")
            return [:]
        }
    }

    func mapToLoadableTokenFee(state: TokenFeeProviderState, selectedFeeOption: FeeOption) -> TokenFee {
        let loadableTokenFeeState: LoadingResult<BSDKFee, any Error> = {
            switch state {
            case .idle, .loading:
                return .loading
            case .unavailable(.notSupported):
                return .failure(TokenFeeProviderError.unsupportedByProvider)
            case .unavailable:
                return .failure(TokenFeeProviderError.providerUnavailable)
            case .error(let error):
                return .failure(error)
            case .available(let fees):
                if let selectedFeeBySelectedOption = fees[selectedFeeOption] {
                    return .success(selectedFeeBySelectedOption)
                }

                return .failure(TokenFeeProviderError.feeNotFound)
            }
        }()

        return TokenFee(option: selectedFeeOption, tokenItem: feeTokenItem, value: loadableTokenFeeState)
    }
}

// MARK: - Updating

private extension CommonTokenFeeProvider {
    // MARK: - Common

    func updateFees(amount: Decimal, destination: String) async throws -> [BSDKFee] {
        let fees = try await tokenFeeLoader.getFee(amount: amount, destination: destination)
        try Task.checkCancellation()
        return fees
    }

    func updateFees(amount: Decimal) async throws -> [BSDKFee] {
        let fees = try await tokenFeeLoader.estimatedFee(amount: amount)
        try Task.checkCancellation()
        return fees
    }

    // MARK: - Ethereum

    private func updateFees(estimatedGasLimit: Int, otherNativeFee: Decimal?) async throws -> [BSDKFee] {
        let fee = try await tokenFeeLoader.asEthereumTokenFeeLoader().estimatedFee(
            estimatedGasLimit: estimatedGasLimit,
            otherNativeFee: otherNativeFee
        )
        try Task.checkCancellation()
        return [fee]
    }

    private func updateFees(amount: BSDKAmount, destination: String, txData: Data, otherNativeFee: Decimal?) async throws -> [BSDKFee] {
        let fees = try await tokenFeeLoader.asEthereumTokenFeeLoader().getFee(
            request: EthereumFeeRequestData(amount: amount, destination: destination, txData: txData, otherNativeFee: otherNativeFee)
        )
        try Task.checkCancellation()
        return fees
    }

    private func updateApproveWithSwapFees(amount: BSDKAmount, destination: String, txData: Data, otherNativeFee: Decimal?, approveInput: ApproveWithSwapInput) async throws -> [BSDKFee] {
        let fees = try await tokenFeeLoader.asEthereumTokenFeeLoader().getApproveWithSwapFee(
            request: EthereumFeeRequestData(amount: amount, destination: destination, txData: txData, otherNativeFee: otherNativeFee),
            approveInput: approveInput
        )
        try Task.checkCancellation()
        return fees
    }

    // MARK: - Solana

    func updateFees(compiledTransaction data: Data) async throws -> [BSDKFee] {
        let fees = try await tokenFeeLoader.asSolanaTokenFeeLoader().getFee(compiledTransaction: data)
        try Task.checkCancellation()
        return fees
    }

    // MARK: - Bitcoin

    func updateFees(psbtBase64: String) async throws -> [BSDKFee] {
        let fees = try await tokenFeeLoader.asBitcoinTokenFeeLoader().getFee(psbtBase64: psbtBase64)
        try Task.checkCancellation()
        return fees
    }
}

// MARK: - CustomStringConvertible

extension CommonTokenFeeProvider: CustomStringConvertible {
    var description: String {
        objectDescription(self, userInfo: [
            "feeTokenItem": feeTokenItem.name,
            "feeTokenItemBlockchain": feeTokenItem.blockchain.displayName,
            "input": tokenFeeProviderInputData?.rawCaseValue ?? "",
            "state": state.description,
        ])
    }
}
