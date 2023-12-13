//
//  AddCustomTokenViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import struct TangemSdk.DerivationPath
import enum TangemSdk.TangemSdkError

final class AddCustomTokenViewModel: ObservableObject {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.tangemApiService) var tangemApiService: TangemApiService

    @Published var selectedWalletName = ""

    @Published var selectedBlockchainNetworkId: String?
    @Published var selectedBlockchainName: String = ""

    @Published var name = ""
    @Published var symbol = ""
    @Published var contractAddress = ""
    @Published var decimals = ""

    @Published var error: AlertBinder?

    @Published var addButtonDisabled = false
    @Published var isLoading = false

    @Published var contractAddressError: Error?

    var selectedBlockchainSupportsTokens: Bool {
        let blockchain = try? enteredBlockchain()
        return blockchain?.canHandleTokens ?? false
    }

    var showDerivationPaths: Bool {
        settings.hdWalletsSupported && selectedBlockchainNetworkId != nil
    }

    @Published var notificationInput: NotificationViewInput?

    private(set) var selectedDerivationOption: AddCustomTokenDerivationOption?
    private(set) var canSelectWallet: Bool = false
    private var selectedUserWalletId: Data?
    private var derivationPathByBlockchainName: [String: DerivationPath] = [:]
    private var didLogScreenAnalytics = false
    private var foundStandardToken: CoinModel?
    #warning("DONT USE LEGACY SETTINGS")
    private var settings: LegacyManageTokensSettings
    private var bag: Set<AnyCancellable> = []

    private unowned let coordinator: AddCustomTokenRoutable

    private var userTokensManager: UserTokensManager? {
        userWalletRepository
            .models
            .first {
                $0.userWalletId.value == selectedUserWalletId
            }?
            .userTokensManager
    }

    private var supportedBlockchains: [Blockchain] {
        Array(settings.supportedBlockchains)
            .filter {
                $0.curve.supportsDerivation
            }
            .sorted(by: \.displayName)
    }

    private var availableWallets: [UserWallet] {
        userWalletRepository.models
            .filter {
                $0.isMultiWallet
            }
            .map {
                $0.userWallet
            }
    }

    init(
        settings: LegacyManageTokensSettings,
        coordinator: AddCustomTokenRoutable
    ) {
        self.settings = settings
        self.coordinator = coordinator
        canSelectWallet = availableWallets.count > 1

        let selectedUserWallet = userWalletRepository.selectedModel?.userWallet
        selectedWalletName = selectedUserWallet?.name ?? ""
        selectedUserWalletId = selectedUserWallet?.userWalletId

        bind()
    }

    func onAppear() {
        if !didLogScreenAnalytics {
            Analytics.log(.customTokenScreenOpened)
            didLogScreenAnalytics = true
        }
    }

    func createToken() {
        guard let userTokensManager else { return }

        UIApplication.shared.endEditing()

        let tokenItem: TokenItem
        let derivationPath: DerivationPath?
        do {
            tokenItem = try enteredTokenItem()
            derivationPath = enteredDerivationPath()

            try checkLocalStorage()
            try validateExistingCurves(for: tokenItem)

            if case .token(_, let blockchain) = tokenItem,
               case .solana = blockchain,
               !settings.longHashesSupported {
                throw TokenCreationErrors.tokensNotSupported
            }
        } catch {
            self.error = error.alertBinder
            return
        }

        userTokensManager.update(itemsToRemove: [], itemsToAdd: [tokenItem], derivationPath: derivationPath)
        logSuccess(tokenItem: tokenItem, derivationPath: derivationPath)

        closeModule()
    }

    func didTapWalletSelector() {
        coordinator.openWalletSelector(
            userWallets: availableWallets,
            currentUserWalletId: selectedUserWalletId
        )
    }

    func setSelectedWallet(userWalletId: Data) {
        guard
            let userWalletModel = userWalletRepository.models.first(where: { $0.userWalletId.value == userWalletId })
        else {
            return
        }

        let userWallet = userWalletModel.userWallet

        selectedUserWalletId = userWalletId
        selectedWalletName = userWallet.name
        settings = makeSettings(userWalletModel: userWalletModel)

        updateDefaultDerivationOption()
        validate()
    }

    func didTapNetworkSelector() {
        coordinator.openNetworkSelector(
            selectedBlockchainNetworkId: selectedBlockchainNetworkId,
            blockchains: supportedBlockchains
        )
    }

    func setSelectedNetwork(networkId: String) {
        guard
            let blockchain = settings.supportedBlockchains.first(where: { $0.networkId == networkId })
        else {
            return
        }

        selectedBlockchainNetworkId = blockchain.networkId
        selectedBlockchainName = blockchain.displayName

        updateDefaultDerivationOption()
        validate()
    }

    func didTapDerivationSelector() {
        guard
            let selectedDerivationOption,
            let selectedBlockchain = try? enteredBlockchain(),
            let derivationStyle = settings.derivationStyle,
            let defaultDerivationPath = selectedBlockchain.derivationPath(for: derivationStyle)
        else {
            return
        }

        let blockchainDerivationOptions: [AddCustomTokenDerivationOption] = supportedBlockchains.compactMap {
            guard let derivationPath = $0.derivationPath(for: derivationStyle) else { return nil }
            return AddCustomTokenDerivationOption.blockchain(name: $0.displayName, derivationPath: derivationPath)
        }

        coordinator.openDerivationSelector(
            selectedDerivationOption: selectedDerivationOption,
            defaultDerivationPath: defaultDerivationPath,
            blockchainDerivationOptions: blockchainDerivationOptions
        )
    }

    func setSelectedDerivationOption(derivationOption: AddCustomTokenDerivationOption) {
        selectedDerivationOption = derivationOption

        validate()
    }

    private func bind() {
        $contractAddress.removeDuplicates()
            .dropFirst()
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .flatMap { [unowned self] contractAddress -> AnyPublisher<[CoinModel], Never> in
                let result: AnyPublisher<[CoinModel], Never>
                let contractAddressError: Error?

                do {
                    if contractAddress.isEmpty {
                        result = .just(output: [])
                        contractAddressError = nil
                    } else {
                        let enteredContractAddress = try enteredContractAddress(in: enteredBlockchain())

                        result = findToken(contractAddress: enteredContractAddress)
                        contractAddressError = nil

                        isLoading = true
                    }
                } catch {
                    result = .just(output: [])
                    contractAddressError = error
                }

                self.contractAddressError = contractAddressError
                return result
            }
            .receive(on: RunLoop.main)
            .sink { [weak self] currencyModels in
                self?.didFinishTokenSearch(currencyModels)
            }
            .store(in: &bag)

        Publishers.CombineLatest3(
            $name.removeDuplicates(),
            $symbol.removeDuplicates(),
            $decimals.removeDuplicates()
        )
        .debounce(for: 0.1, scheduler: RunLoop.main)
        .sink { [weak self] _ in
            self?.validate()
        }
        .store(in: &bag)
    }

    private func makeSettings(userWalletModel: UserWalletModel) -> LegacyManageTokensSettings {
        let shouldShowLegacyDerivationAlert = userWalletModel.config.warningEvents.contains(where: { $0 == .legacyDerivation })
        var supportedBlockchains = userWalletModel.config.supportedBlockchains
        supportedBlockchains.remove(.ducatus)

        let settings = LegacyManageTokensSettings(
            supportedBlockchains: supportedBlockchains,
            hdWalletsSupported: userWalletModel.config.hasFeature(.hdWallets),
            longHashesSupported: userWalletModel.config.hasFeature(.longHashes),
            derivationStyle: userWalletModel.config.derivationStyle,
            shouldShowLegacyDerivationAlert: shouldShowLegacyDerivationAlert,
            existingCurves: (userWalletModel as? CardViewModel)?.card.walletCurves ?? []
        )
        return settings
    }

    private func enteredTokenItem() throws -> TokenItem {
        let blockchain = try enteredBlockchain()

        let missingTokenInformation = contractAddress.isEmpty && name.isEmpty && symbol.isEmpty && decimals.isEmpty
        if !blockchain.canHandleTokens || missingTokenInformation {
            return .blockchain(blockchain)
        } else {
            let enteredContractAddress = try enteredContractAddress(in: blockchain)

            guard !name.isEmpty, !symbol.isEmpty, !decimals.isEmpty else {
                throw TokenCreationErrors.emptyFields
            }

            let maxDecimalNumber = 30
            guard
                let decimals = Int(decimals),
                0 <= decimals, decimals <= maxDecimalNumber
            else {
                throw TokenCreationErrors.invalidDecimals(precision: maxDecimalNumber)
            }

            let foundStandardTokenItem = foundStandardToken?.items.first(where: { $0.blockchain == blockchain })

            let token = Token(
                name: name,
                symbol: symbol.uppercased(),
                contractAddress: enteredContractAddress,
                decimalCount: decimals,
                id: foundStandardTokenItem?.id
            )

            return .token(token, blockchain)
        }
    }

    private func validateEnteredContractAddress() throws {
        guard
            selectedBlockchainSupportsTokens,
            !contractAddress.isEmpty
        else {
            return
        }

        guard foundStandardToken != nil else {
            throw TokenSearchError.failedToFindToken
        }

        do {
            let blockchain = try enteredBlockchain()
            _ = try enteredContractAddress(in: blockchain)
        } catch {
            throw TokenSearchError.failedToFindToken
        }
    }

    private func validateExistingCurves(for tokenItem: TokenItem) throws {
        guard settings.existingCurves.contains(tokenItem.blockchain.curve) else {
            throw TokenCreationErrors.unsupportedCurve(tokenItem.blockchain)
        }

        return
    }

    private func enteredBlockchain() throws -> Blockchain {
        guard
            let selectedBlockchainNetworkId,
            let blockchain = settings.supportedBlockchains.first(where: { $0.networkId == selectedBlockchainNetworkId })
        else {
            throw TokenCreationErrors.blockchainNotSelected
        }

        return blockchain
    }

    private func enteredContractAddress(in blockchain: Blockchain) throws -> String {
        if case .binance = blockchain, !contractAddress.trimmed().isEmpty {
            return contractAddress // skip validation for binance
        }

        let addressService = AddressServiceFactory(blockchain: blockchain).makeAddressService()

        guard addressService.validate(contractAddress) else {
            throw TokenCreationErrors.invalidContractAddress
        }

        return contractAddress
    }

    private func enteredDerivationPath() -> DerivationPath? {
        if settings.hdWalletsSupported {
            return selectedDerivationOption?.derivationPath
        } else {
            return nil
        }
    }

    private func checkLocalStorage() throws {
        guard
            let tokenItem = try? enteredTokenItem(),
            let userTokensManager
        else {
            return
        }

        let derivationPath = enteredDerivationPath()

        if userTokensManager.contains(tokenItem, derivationPath: derivationPath) {
            throw TokenSearchError.alreadyAdded
        }
    }

    private func findToken(contractAddress: String) -> AnyPublisher<[CoinModel], Never> {
        if let currentCurrencyModel = foundStandardToken,
           let token = currentCurrencyModel.items.first?.token,
           token.contractAddress.caseInsensitiveCompare(contractAddress) == .orderedSame {
            return .just(output: [currentCurrencyModel])
        }

        let requestModel = CoinsList.Request(
            supportedBlockchains: Set(supportedBlockchains),
            contractAddress: contractAddress
        )

        return tangemApiService
            .loadCoins(requestModel: requestModel)
            .replaceError(with: [])
            .eraseToAnyPublisher()
    }

    private func didFinishTokenSearch(_ currencyModels: [CoinModel]) {
        isLoading = false

        let previouslyFoundStandardToken = foundStandardToken

        let currencyModelBlockchains = currencyModels.reduce(Set<Blockchain>()) { partialResult, currencyModel in
            partialResult.union(currencyModel.items.map { $0.blockchain })
        }

        if let newBlockchain = currencyModelBlockchains.first {
            setSelectedNetwork(networkId: newBlockchain.networkId)
        }

        foundStandardToken = currencyModels.first

        if let token = foundStandardToken?.items.first?.token {
            decimals = "\(token.decimalCount)"
            symbol = token.symbol
            name = token.name

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                UIApplication.shared.endEditing()
            }
        } else if previouslyFoundStandardToken != nil || !selectedBlockchainSupportsTokens {
            decimals = ""
            symbol = ""
            name = ""
        }

        validate()
    }

    private func validate() {
        addButtonDisabled = false
        notificationInput = nil

        do {
            let _ = try enteredTokenItem()
            try checkLocalStorage()
            try validateEnteredContractAddress()
        } catch {
            let dynamicValidationError = error as? DynamicValidationError
            addButtonDisabled = dynamicValidationError?.preventsFromAdding ?? false

            if let notificationEventProviding = error as? NotificationEventProviding,
               let notificationEvent = notificationEventProviding.notificationEvent {
                notificationInput = NotificationViewInput(
                    style: .plain,
                    settings: NotificationView.Settings(
                        event: notificationEvent,
                        dismissAction: nil
                    )
                )
            }
        }
    }

    private func logSuccess(tokenItem: TokenItem, derivationPath: DerivationPath?) {
        var params: [Analytics.ParameterKey: String] = [
            .token: tokenItem.currencySymbol,
        ]

        if let derivationStyle = settings.derivationStyle,
           let usedDerivationPath = derivationPath ?? tokenItem.blockchain.derivationPath(for: derivationStyle) {
            params[.derivationPath] = usedDerivationPath.rawPath
        }

        if case .token(let token, let blockchain) = tokenItem {
            params[.networkId] = blockchain.networkId
            params[.contractAddress] = token.contractAddress
        }

        Analytics.log(event: .customTokenWasAdded, params: params)
    }

    private func updateDefaultDerivationOption() {
        switch selectedDerivationOption {
        case .default, .none:
            if let blockchain = settings.supportedBlockchains.first(where: { $0.networkId == selectedBlockchainNetworkId }),
               let derivationStyle = settings.derivationStyle,
               let derivationPath = blockchain.derivationPath(for: derivationStyle) {
                selectedDerivationOption = .default(derivationPath: derivationPath)
            }
        case .custom, .blockchain:
            return
        }
    }
}

// MARK: - Navigation

extension AddCustomTokenViewModel {
    func closeModule() {
        coordinator.dismiss()
    }
}

private protocol DynamicValidationError {
    var preventsFromAdding: Bool { get }
}

private protocol NotificationEventProviding {
    var notificationEvent: (any NotificationEvent)? { get }
}

private extension AddCustomTokenViewModel {
    enum TokenCreationErrors: DynamicValidationError, LocalizedError {
        case blockchainNotSelected
        case unsupportedCurve(Blockchain)
        case emptyFields
        case tokensNotSupported
        case invalidDecimals(precision: Int)
        case invalidContractAddress
        case invalidDerivationPath

        var errorDescription: String? {
            switch self {
            case .blockchainNotSelected:
                return Localization.customTokenCreationErrorNetworkNotSelected
            case .unsupportedCurve(let blockchain):
                return Localization.alertManageTokensUnsupportedCurveMessage(blockchain.displayName)
            case .emptyFields:
                return Localization.customTokenCreationErrorEmptyFields
            case .tokensNotSupported:
                return Localization.alertManageTokensUnsupportedMessage
            case .invalidDecimals(let precision):
                return Localization.customTokenCreationErrorWrongDecimals(precision)
            case .invalidContractAddress:
                return Localization.customTokenCreationErrorInvalidContractAddress
            case .invalidDerivationPath:
                return Localization.customTokenCreationErrorInvalidDerivationPath
            }
        }

        var preventsFromAdding: Bool {
            true
        }
    }

    enum TokenSearchError: DynamicValidationError, LocalizedError, NotificationEventProviding {
        case alreadyAdded
        case failedToFindToken

        var preventsFromAdding: Bool {
            false
        }

        var errorDescription: String? {
            switch self {
            case .failedToFindToken:
                return Localization.customTokenValidationErrorNotFound
            case .alreadyAdded:
                return Localization.customTokenValidationErrorAlreadyAdded
            }
        }

        var notificationEvent: (any NotificationEvent)? {
            switch self {
            case .failedToFindToken:
                return AddCustomTokenNotificationEvent.scamWarning
            case .alreadyAdded:
                return nil
            }
        }
    }

    enum DerivationPathError: DynamicValidationError, LocalizedError {
        case invalidDerivationPath

        var preventsFromAdding: Bool {
            switch self {
            case .invalidDerivationPath:
                return true
            }
        }

        var errorDescription: String? {
            switch self {
            case .invalidDerivationPath:
                return Localization.customTokenInvalidDerivationPath
            }
        }
    }
}
