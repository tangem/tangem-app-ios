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
    // MARK: - ViewState

    // MARK: - Dependencies

    private unowned let coordinator: AddCustomTokenRoutable

    @Injected(\.tangemApiService) var tangemApiService: TangemApiService

    @Published var name = ""
    @Published var symbol = ""
    @Published var contractAddress = ""
    @Published var decimals = ""
    @Published var customDerivationPath = ""

    @Published var selectedBlockchainNetworkId: String?
    @Published var selectedBlockchainName: String = ""

    @Published var derivationsPicker: LegacyPickerModel = .empty

    @Published var error: AlertBinder?

    @Published var addButtonDisabled = false
    @Published var isLoading = false

    @Published var contractAddressError: Error?

    var canEnterTokenDetails: Bool {
        selectedBlockchainSupportsTokens
    }

    var showDerivationPaths: Bool {
        cardHasDifferentDerivationPaths
    }

    var showCustomDerivationPath: Bool {
        derivationsPicker.selection == customDerivationItemID
    }

    @Published private var cardHasDifferentDerivationPaths: Bool = true

    private var selectedBlockchainSupportsTokens: Bool {
        let blockchain = try? enteredBlockchain()
        return blockchain?.canHandleTokens ?? false
    }

    private var bag: Set<AnyCancellable> = []
    private var derivationPathByBlockchainName: [String: DerivationPath] = [:]
    private var foundStandardToken: CoinModel?
    private let userTokensManager: UserTokensManager

    private let defaultDerivationItemID = "default-derivation"
    private let customDerivationItemID = "custom-derivation"
    private let existingTokenItem: TokenItem?
    private let settings: LegacyManageTokensSettings

    private var supportedBlockchains: Set<Blockchain> {
        settings.supportedBlockchains
            .filter {
                $0.curve.supportsDerivation
            }
    }

    init(
        existingTokenItem: TokenItem?,
        existingTokenDerivationPath: DerivationPath?,
        settings: LegacyManageTokensSettings,
        userTokensManager: UserTokensManager,
        coordinator: AddCustomTokenRoutable
    ) {
        self.existingTokenItem = existingTokenItem
        self.settings = settings
        self.userTokensManager = userTokensManager
        self.coordinator = coordinator

        if let existingTokenItem {
            updateFields(from: existingTokenItem)
        }

        if let existingTokenDerivationPath {
        }

        bind()
    }

    func createToken() {
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

        userTokensManager.add(tokenItem, derivationPath: derivationPath) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                self.closeModule()

                self.logSuccess(tokenItem: tokenItem, derivationPath: derivationPath)
            case .failure(let error):
                if case TangemSdkError.userCancelled = error {
                    return
                }

                self.error = error.alertBinder
            }
        }
    }

    func onAppear() {
        Analytics.log(.customTokenScreenOpened)
        updateBlockchains(supportedBlockchains)
        updateDerivationPaths()
    }

    func onDisappear() {
        derivationsPicker = .empty
        name = ""
        symbol = ""
        contractAddress = ""
        decimals = ""
    }

    func openNetworkSelector() {
        let blockchains = Array(settings.supportedBlockchains).sorted(by: \.displayName)
        coordinator.openNetworkSelector(
            selectedBlockchainNetworkId: self.selectedBlockchainNetworkId,
            blockchains: blockchains
        )
    }

    func setSelectedNetwork(networkId: String) {
        guard let blockchain = settings.supportedBlockchains.first(where: { $0.networkId == networkId }) else {
            return
        }

        selectedBlockchainNetworkId = blockchain.networkId
        selectedBlockchainName = blockchain.displayName
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
                        let enteredContractAddress = try self.enteredContractAddress(in: self.enteredBlockchain())

                        result = self.findToken(contractAddress: enteredContractAddress)
                        contractAddressError = nil

                        self.isLoading = true
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
            $selectedBlockchainNetworkId.removeAllDuplicates(),
            $derivationsPicker.map { $0.selection }.removeDuplicates(),
            $customDerivationPath.removeDuplicates()
        )
        .debounce(for: 0.1, scheduler: RunLoop.main)
        .sink { [weak self] _ in
            self?.validate()
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

    private func updateFields(from tokenItem: TokenItem) {
        switch tokenItem {
        case .blockchain(let blockchain):
            setSelectedNetwork(networkId: blockchain.networkId)
        case .token(let token, let blockchain):
            setSelectedNetwork(networkId: blockchain.networkId)
            contractAddress = token.contractAddress
            name = token.name
            symbol = token.symbol
            decimals = "\(token.decimalCount)"
        }
    }

    private func updateBlockchains(_ blockchains: Set<Blockchain>, newSelectedBlockchain: Blockchain? = nil) {
        #warning("[REDACTED_TODO_COMMENT]")
        self.derivationPathByBlockchainName = Dictionary(uniqueKeysWithValues: blockchains.compactMap {
            guard let derivationStyle = settings.derivationStyle,
                  let derivationPath = $0.derivationPath(for: derivationStyle) else { return nil }
            return ($0.codingKey, derivationPath)
        })
    }

    private func updateDerivationPaths() {
        let defaultItem = (Localization.customTokenDerivationPathDefault, defaultDerivationItemID)

        let customItem = (Localization.customTokenCustomDerivation, customDerivationItemID)

        let derivations: [(String, String)]
        if !settings.hdWalletsSupported {
            derivations = []
        } else {
            derivations = supportedBlockchains
                .compactMap {
                    guard let derivationStyle = settings.derivationStyle,
                          let derivationPath = $0.derivationPath(for: derivationStyle) else { return nil }

                    let derivationPathFormatted = derivationPath.rawPath
                    let blockchainName = $0.codingKey
                    let description = "\($0.displayName) (\(derivationPathFormatted))"
                    return (description, blockchainName)
                }
                .sorted {
                    $0.0 < $1.0
                }
        }

        let uniqueDerivations = Set(derivations.map(\.1))
        self.cardHasDifferentDerivationPaths = uniqueDerivations.count > 1
        let newDerivationSelection = self.derivationsPicker.selection
        self.derivationsPicker = .init(items: [defaultItem, customItem] + derivations, selection: newDerivationSelection)
    }

    private func enteredTokenItem() throws -> TokenItem {
        let blockchain = try enteredBlockchain()

        let missingTokenInformation = contractAddress.isEmpty && name.isEmpty && symbol.isEmpty && decimals.isEmpty
        if !blockchain.canHandleTokens || missingTokenInformation {
            return .blockchain(blockchain)
        } else {
            let enteredContractAddress = try self.enteredContractAddress(in: blockchain)

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
        guard !contractAddress.isEmpty else {
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

    private func validateDerivationPath() throws {
        guard customDerivationItemID == derivationsPicker.selection else {
            return
        }

        let derivationPath = try? DerivationPath(rawPath: customDerivationPath)
        if derivationPath == nil {
            throw DerivationPathError.invalidDerivationPath
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
        let derivationItemID = derivationsPicker.selection

        switch derivationItemID {
        case defaultDerivationItemID:
            return nil
        case customDerivationItemID:
            return try? DerivationPath(rawPath: customDerivationPath)
        default:
            // ID is a blockchain name
            return derivationPathByBlockchainName[derivationItemID]
        }
    }

    private func checkLocalStorage() throws {
        guard let tokenItem = try? enteredTokenItem() else {
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
            supportedBlockchains: supportedBlockchains,
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

        self.foundStandardToken = currencyModels.first

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

        do {
            let _ = try enteredTokenItem()
            try validateDerivationPath()
            try checkLocalStorage()
            try validateEnteredContractAddress()
        } catch {
            let dynamicValidationError = error as? DynamicValidationError
            addButtonDisabled = dynamicValidationError?.preventsFromAdding ?? false
        }
    }

    private func logSuccess(tokenItem: TokenItem, derivationPath: DerivationPath?) {
        var params: [Analytics.ParameterKey: String] = [
            .token: tokenItem.currencySymbol,
        ]

        if let derivationStyle = settings.derivationStyle,
           let usedDerivationPath = derivationPath ?? tokenItem.blockchain.derivationPath(for: derivationStyle)
        {
            params[.derivationPath] = usedDerivationPath.rawPath
        }

        if case .token(let token, let blockchain) = tokenItem {
            params[.networkId] = blockchain.networkId
            params[.contractAddress] = token.contractAddress
        }

        Analytics.log(event: .customTokenWasAdded, params: params)
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

    enum TokenSearchError: DynamicValidationError, LocalizedError {
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
