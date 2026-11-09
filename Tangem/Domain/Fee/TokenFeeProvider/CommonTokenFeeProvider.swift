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
import enum BlockchainSdk.ETHError

let FeeLogger = AppLogger.tag("TokenFeeProvider")

final class CommonTokenFeeProvider {
    let feeTokenItem: TokenItem
    let tokenFeeLoader: any TokenFeeLoader
    let customFeeProvider: (any CustomFeeProvider)?
    let feeTokenItemBalanceProvider: TokenBalanceProvider
    let supportingOptions: TokenFeeProviderSupportingOptions
    let minimumRequiredBalance: Decimal?

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
        minimumRequiredBalance: Decimal? = nil,
    ) {
        self.feeTokenItem = feeTokenItem
        self.tokenFeeLoader = tokenFeeLoader
        self.customFeeProvider = customFeeProvider
        self.feeTokenItemBalanceProvider = feeTokenItemBalanceProvider
        self.supportingOptions = supportingOptions
        self.minimumRequiredBalance = minimumRequiredBalance

        bind()
    }
}

// MARK: - TokenFeeProvider

extension CommonTokenFeeProvider: TokenFeeProvider {
    var balanceFeeTokenState: TokenBalanceType { feeTokenItemBalanceProvider.balanceType }
    var balanceTypePublisher: AnyPublisher<TokenBalanceType, Never> { feeTokenItemBalanceProvider.balanceTypePublisher }
    var usageAvailability: FeeTokenUsageAvailability {
        mapToUsageAvailability(balance: balanceFeeTokenState)
    }

    var usageAvailabilityPublisher: AnyPublisher<FeeTokenUsageAvailability, Never> {
        balanceTypePublisher
            .withWeakCaptureOf(self)
            .map { provider, balance in provider.mapToUsageAvailability(balance: balance) }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

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
        let fees = try await tokenFeeLoader.loadFees(input, feeBlockchain: feeTokenItem.blockchain)
        try Task.checkCancellation()

        guard case .approve(_, _, _, _, let feeMultiplier) = input else {
            return fees
        }

        // Approve flow never shows a speed selector — only market fee is needed.
        // [safe: 1] = market for EIP-1559 (3 fees), fallback to [safe: 0] for single-fee (gasless).
        guard let marketFee = fees[safe: 1] ?? fees[safe: 0] else {
            throw TokenFeeProviderError.feeNotFound
        }

        guard feeMultiplier != .single else { return [marketFee] }

        var scaledAmount = marketFee.amount
        scaledAmount.value *= feeMultiplier.rawValue
        return [BSDKFee(scaledAmount, parameters: marketFee.parameters)]
    }
}

// MARK: - Private

private extension CommonTokenFeeProvider {
    func mapToUsageAvailability(balance: TokenBalanceType) -> FeeTokenUsageAvailability {
        guard let minimumRequiredBalance,
              let balance = balance.loaded,
              balance < minimumRequiredBalance else {
            return .available
        }

        return .minimumBalanceRequired(amount: minimumRequiredBalance, tokenItem: feeTokenItem)
    }

    func bind() {
        customFeeProviderInitialSetupCancellable = customFeeProvider?.subscribeToInitialSetup(
            tokenFeeProvider: self
        )

        feeTokenItemBalanceStateCancellable = feeTokenItemBalanceProvider
            .balanceTypePublisher
            .withWeakCaptureOf(self)
            .map { feeProvider, balanceType in feeProvider.hasFeeCurrency(balance: balanceType.value ?? 0) }
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
        updateBridgeFeeSupportingState(input: input)

        switch input {
        case .none:
            updateState(state: .unavailable(.inputDataNotSet))
        case .approve(_, _, _, _, let feeMultiplier)
            where tokenFeeLoader.tripleApproveFeeRequiresFeature
            && feeMultiplier == .triple
            && !FeatureProvider.isAvailable(.usdtRevokeGaslessFee):
            updateState(state: .unavailable(.notSupported))
        case let input? where tokenFeeLoader.supports(input):
            break
        default:
            updateState(state: .unavailable(.notSupported))
        }
    }

    /// A bridge provider charges its own fee in the blockchain's coin and expects it as the transaction
    /// value, which a gasless transaction can't carry: the relayer forwards no coin value.
    ///
    /// The same provider quotes with and without a bridge fee from one quote to the next, so the verdict
    /// is withdrawn as well — while this provider stays unselected, nothing else would clear it.
    /// The withdrawal restores the balance verdict rather than a plain `.idle`: for an unchanged
    /// zero balance the balance publisher never re-emits, so nothing else would bring it back
    func updateBridgeFeeSupportingState(input: TokenFeeProviderInputData?) {
        guard tokenFeeLoader.rejectsBridgeCoinFee else {
            return
        }

        switch (bridgeFee(in: input) > 0, stateSubject.value) {
        case (true, _):
            updateState(state: .unavailable(.notSupported))
        case (false, .unavailable(.notSupported)):
            let balance = feeTokenItemBalanceProvider.balanceType.value ?? 0
            updateState(state: hasFeeCurrency(balance: balance) ? .idle : .unavailable(.noTokenBalance))
        case (false, _):
            break
        }
    }

    func hasFeeCurrency(balance: Decimal) -> Bool {
        feeTokenItem.blockchain.allowsZeroFeePaid ? balance >= 0 : balance > 0
    }

    /// The fee a bridge provider charges in the blockchain's coin, carried by every input that can describe a swap
    func bridgeFee(in input: TokenFeeProviderInputData?) -> Decimal {
        switch input {
        case .dex(.ethereum(_, _, _, let otherNativeFee)),
             .dex(.ethereumEstimate(_, let otherNativeFee)),
             .approveWithSwap(_, _, _, let otherNativeFee, _):
            otherNativeFee ?? 0
        case .dex(.tron(let request, _, _)):
            request.otherNativeFee ?? 0
        default:
            0
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
            let feeCurrencyBalance = feeTokenItemBalanceProvider.balanceType.value ?? 0

            switch state {
            case .idle, .loading:
                return .loading
            case .unavailable(.notSupported):
                return .failure(TokenFeeProviderError.unsupportedByProvider)
            case .unavailable(.noTokenBalance) where feeTokenItem.isBlockchain:
                return .failure(TokenFeeProviderError.notEnoughBalanceForFee(feeCurrencyBalance: feeCurrencyBalance))
            case .unavailable(.notEnoughFeeBalance), .unavailable(.noTokenBalance):
                return .failure(TokenFeeProviderError.notEnoughGaslessFeeBalance(feeCurrencyBalance: feeCurrencyBalance))
            case .unavailable:
                return .failure(TokenFeeProviderError.providerUnavailable)
            // An EVM node rejects the gas estimate this way when the account cannot cover the fee
            case .error(ETHError.gasRequiredExceedsAllowance) where feeTokenItem.isBlockchain:
                return .failure(TokenFeeProviderError.notEnoughBalanceForFee(feeCurrencyBalance: feeCurrencyBalance))
            case .error(ETHError.gasRequiredExceedsAllowance):
                return .failure(TokenFeeProviderError.notEnoughGaslessFeeBalance(feeCurrencyBalance: feeCurrencyBalance))
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
