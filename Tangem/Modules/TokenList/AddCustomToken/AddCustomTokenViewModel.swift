//
//  AddCustomTokenViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import struct TangemSdk.DerivationPath
import enum TangemSdk.TangemSdkError

class AddCustomTokenViewModel: ObservableObject {
    @Injected(\.cardsRepository) private var cardsRepository: CardsRepository
    @Injected(\.tangemApiService) var tangemApiService: TangemApiService

    weak var cardModel: CardViewModel!

    @Published var name = ""
    @Published var symbol = ""
    @Published var contractAddress = ""
    @Published var decimals = ""

    @Published var blockchainsPicker: PickerModel = .empty
    @Published var derivationsPicker: PickerModel = .empty

    @Published var error: AlertBinder?

    @Published var warningContainer = WarningsContainer()
    @Published var addButtonDisabled = false
    @Published var isLoading = false

    var canEnterTokenDetails: Bool {
        selectedBlockchainSupportsTokens
    }

    var showDerivationPaths: Bool {
        cardHasDifferentDerivationPaths && blockchainHasDifferentDerivationPaths
    }

    @Published private var cardHasDifferentDerivationPaths: Bool = true
    @Published private var blockchainHasDifferentDerivationPaths: Bool = true

    private var selectedBlockchainSupportsTokens: Bool {
        let blockchain = try? enteredBlockchain()
        return blockchain?.canHandleTokens ?? true
    }

    private var bag: Set<AnyCancellable> = []
    private var blockchainByName: [String: Blockchain] = [:]
    private var derivationPathByBlockchainName: [String: DerivationPath] = [:]
    private var foundStandardToken: CoinModel?
    private unowned let coordinator: AddCustomTokenRoutable

    init(cardModel: CardViewModel, coordinator: AddCustomTokenRoutable) {
        self.coordinator = coordinator
        self.cardModel = cardModel

        $contractAddress.removeDuplicates()
            .dropFirst()
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .flatMap { [unowned self] contractAddress -> AnyPublisher<[CoinModel], Never> in
                self.isLoading = true

                guard !contractAddress.isEmpty else {
                    return Just([])
                        .eraseToAnyPublisher()
                }

                return self.findToken(contractAddress: contractAddress)
            }
            .receive(on: RunLoop.main)
            .sink { [unowned self] currencyModels in
                self.didFinishTokenSearch(currencyModels)
            }
            .store(in: &bag)

        Publishers.CombineLatest(
            $blockchainsPicker.map { $0.selection }.removeDuplicates(),
            $derivationsPicker.map { $0.selection }.removeDuplicates()
        )
        .debounce(for: 0.1, scheduler: RunLoop.main)
        .sink { [unowned self] (newBlockchainName, _) in
            self.didChangeBlockchain(newBlockchainName)
        }
        .store(in: &bag)
    }

    func createToken() {
        UIApplication.shared.endEditing()

        let tokenItem: TokenItem
        let blockchain: Blockchain
        let derivationPath: DerivationPath?
        do {
            tokenItem = try enteredTokenItem()
            blockchain = try enteredBlockchain()
            derivationPath = try enteredDerivationPath()

            if case let .token(_, blockchain) = tokenItem,
               case .solana = blockchain,
               !cardModel.longHashesSupported
            {
                throw TokenCreationErrors.tokensNotSupported
            }
        } catch {
            self.error = error.alertBinder
            return
        }

        let blockchainNetwork = cardModel.getBlockchainNetwork(for: blockchain, derivationPath: derivationPath)
        let entry = StorageEntry(blockchainNetwork: blockchainNetwork, token: tokenItem.token)

        cardModel.add(entries: [entry]) { [weak self] result in
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
        updateBlockchains(getBlockchains(withTokenSupport: true))
        updateDerivationPaths()
    }

    func onDisappear() {
        blockchainsPicker = .empty
        derivationsPicker = .empty
        name = ""
        symbol = ""
        contractAddress = ""
        decimals = ""
    }

    private func updateBlockchains(_ blockchains: Set<Blockchain>, newSelectedBlockchain: Blockchain? = nil) {
        let defaultItem = ("custom_token_network_input_not_selected".localized, "")

        let newBlockchains = [defaultItem] + blockchains.sorted {
            $0.displayName < $1.displayName
        }.map {
            ($0.displayName, $0.codingKey)
        }
        self.blockchainByName = Dictionary(uniqueKeysWithValues: blockchains.map {
            ($0.codingKey, $0)
        })
        self.derivationPathByBlockchainName = Dictionary(uniqueKeysWithValues: blockchains.compactMap {
            guard let derivationPath = $0.derivationPath() else { return nil }
            return ($0.codingKey, derivationPath)
        })

        var newBlockchainName = self.blockchainsPicker.selection
        if let newSelectedBlockchain = newSelectedBlockchain {
            newBlockchainName = newSelectedBlockchain.codingKey
        } else if blockchains.count == 1, let firstBlockchain = blockchains.first {
            newBlockchainName = firstBlockchain.codingKey
        } else if blockchainByName[blockchainsPicker.selection] == nil {
            newBlockchainName = ""
        }

        self.blockchainsPicker = .init(items: newBlockchains, selection: newBlockchainName, isEnabled: blockchains.count > 1)
    }

    private func getBlockchains(withTokenSupport: Bool) -> Set<Blockchain> {
        let blockchains = cardModel.supportedBlockchains

        if withTokenSupport {
            let blockchainsWithTokens = blockchains.filter { $0.canHandleTokens }
            let evmBlockchains = blockchains.filter { $0.isEvm }
            let blockchainsToDisplay = blockchainsWithTokens.union(evmBlockchains)
            return blockchains.filter { blockchainsToDisplay.contains($0) }
        } else {
            return blockchains
        }
    }

    private func updateDerivationPaths() {
        let defaultItem = ("custom_token_derivation_path_default".localized, "")

        let evmBlockchains = getBlockchains(withTokenSupport: false).filter { $0.isEvm }
        let evmDerivationPaths: [(String, String)]
        if !cardModel.hdWalletsSupported {
            evmDerivationPaths = []
        } else {
            evmDerivationPaths = evmBlockchains
                .compactMap {
                    guard let derivationPath = cardModel.getBlockchainNetwork(for: $0, derivationPath: nil).derivationPath else {
                        return nil
                    }

                    let derivationPathFormatted = derivationPath.rawPath
                    let blockchainName = $0.codingKey
                    let description = "\($0.displayName) (\(derivationPathFormatted))"
                    return (description, blockchainName)
                }
                .sorted {
                    $0.0 < $1.0
                }
        }

        let uniqueDerivations = Set(evmDerivationPaths.map(\.1))
        self.cardHasDifferentDerivationPaths = uniqueDerivations.count > 1
        let newDerivationSelection = self.derivationsPicker.selection
        self.derivationsPicker = .init(items: [defaultItem] + evmDerivationPaths, selection: newDerivationSelection)
    }

    private func enteredTokenItem() throws -> TokenItem {
        let blockchain = try enteredBlockchain()

        if contractAddress.isEmpty && name.isEmpty && symbol.isEmpty && decimals.isEmpty {
            return .blockchain(blockchain)
        } else {
            let enteredContractAddress = try self.enteredContractAddress(in: blockchain)

            guard !name.isEmpty, !symbol.isEmpty, !decimals.isEmpty else {
                throw TokenCreationErrors.emptyFields
            }

            let maxDecimalNumber = 30
            guard
                let decimals = Int(decimals),
                0 <= decimals && decimals <= maxDecimalNumber
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

    private func enteredBlockchain() throws -> Blockchain {
        guard let blockchain = blockchainByName[blockchainsPicker.selection] else {
            throw TokenCreationErrors.blockchainNotSelected
        }

        return blockchain
    }

    private func enteredContractAddress(in blockchain: Blockchain) throws -> String {
        if case .binance = blockchain, !contractAddress.trimmed().isEmpty {
            return contractAddress // skip validation for binance
        }

        guard blockchain.validate(address: contractAddress) else {
            throw TokenCreationErrors.invalidContractAddress
        }

        return contractAddress
    }

    private func enteredDerivationPath() throws -> DerivationPath? {
        if let blockchain = try? enteredBlockchain(),
           !blockchain.isEvm
        {
            return nil
        }

        let blockchainName = derivationsPicker.selection
        return derivationPathByBlockchainName[blockchainName]
    }

    private func checkLocalStorage() throws {
        guard let blockchain = try? enteredBlockchain() else {
            return
        }

        let cardTokenItems = cardModel.userWalletModel?.userTokenListManager.getEntriesFromRepository() ?? []

        let checkingContractAddress = !contractAddress.isEmpty
        let derivationPath = try? enteredDerivationPath()

        let blockchainNetwork = cardModel.getBlockchainNetwork(for: blockchain, derivationPath: derivationPath)

        if let networkItem = cardTokenItems.first(where: { $0.blockchainNetwork == blockchainNetwork }) {
            if !checkingContractAddress {
                throw TokenSearchError.alreadyAdded
            }

            if networkItem.tokens.contains(where: { $0.contractAddress == contractAddress }) {
                throw TokenSearchError.alreadyAdded
            }
        }
    }

    private func findToken(contractAddress: String) -> AnyPublisher<[CoinModel], Never> {
        if let currentCurrencyModel = foundStandardToken,
           let token = currentCurrencyModel.items.first?.token,
           token.contractAddress.caseInsensitiveCompare(contractAddress) == .orderedSame
        {
            return Just([currentCurrencyModel])
                .eraseToAnyPublisher()
        }

        let networkIds = getBlockchains(withTokenSupport: true).map { $0.networkId }
        let requestModel = CoinsListRequestModel(
            contractAddress: contractAddress,
            networkIds: networkIds
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

        let blockchains = getBlockchains(withTokenSupport: true)
        updateBlockchains(blockchains, newSelectedBlockchain: currencyModelBlockchains.first)

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

    private func didChangeBlockchain(_ newBlockchainName: String) {
        let newBlockchain = blockchainByName[newBlockchainName]

        let blockchainHasDerivationPaths: Bool
        if let newBlockchain = newBlockchain {
            blockchainHasDerivationPaths = newBlockchain.isEvm
        } else {
            blockchainHasDerivationPaths = true
        }

        blockchainHasDifferentDerivationPaths = blockchainHasDerivationPaths

        validate()
    }

    private func validate() {
        addButtonDisabled = false
        warningContainer.removeAll()

        do {
            try checkLocalStorage()
            try validateEnteredContractAddress()
        } catch {
            let tokenSearchError = error as? TokenSearchError
            addButtonDisabled = tokenSearchError?.preventsFromAdding ?? false

            if let tokenSearchError = tokenSearchError {
                warningContainer.add(tokenSearchError.appWarning)
            }
        }
    }

    private func logSuccess(tokenItem: TokenItem, derivationPath: DerivationPath?) {
        var params: [Analytics.ParameterKey: String] = [
            .token: tokenItem.currencySymbol,
        ]

        if let derivationStyle = cardModel.derivationStyle,
           let usedDerivationPath = derivationPath ?? tokenItem.blockchain.derivationPath(for: derivationStyle)
        {
            params[.derivationPath] = usedDerivationPath.rawPath
        }

        if case let .token(token, blockchain) = tokenItem {
            params[.networkId] = blockchain.networkId
            params[.contractAddress] = token.contractAddress
        }

        Analytics.log(.customTokenWasAdded, params: params)
    }
}

// MARK: - Navigation
extension AddCustomTokenViewModel {
    func closeModule() {
        coordinator.closeModule()
    }
}

private extension AddCustomTokenViewModel {
    enum TokenCreationErrors: LocalizedError {
        case blockchainNotSelected
        case emptyFields
        case tokensNotSupported
        case invalidDecimals(precision: Int)
        case invalidContractAddress
        case invalidDerivationPath

        var errorDescription: String? {
            switch self {
            case .blockchainNotSelected:
                return "custom_token_creation_error_network_not_selected".localized
            case .emptyFields:
                return "custom_token_creation_error_empty_fields".localized
            case .tokensNotSupported:
                return "alert_manage_tokens_unsupported_message".localized
            case .invalidDecimals(let precision):
                return "custom_token_creation_error_wrong_decimals".localized(precision)
            case .invalidContractAddress:
                return "custom_token_creation_error_invalid_contract_address".localized
            case .invalidDerivationPath:
                return "custom_token_creation_error_invalid_derivation_path".localized
            }
        }
    }

    enum TokenSearchError: LocalizedError {
        case alreadyAdded
        case failedToFindToken

        var preventsFromAdding: Bool {
            switch self {
            case .alreadyAdded:
                return true
            case .failedToFindToken:
                return false
            }
        }

        var errorDescription: String? {
            switch self {
            case .failedToFindToken:
                return "custom_token_validation_error_not_found".localized
            case .alreadyAdded:
                return "custom_token_validation_error_already_added".localized
            }
        }

        var appWarning: AppWarning {
            return AppWarning(title: "common_warning".localized, message: errorDescription ?? "", priority: .warning)
        }
    }
}

struct PickerModel: Identifiable {
    let id = UUID()
    let items: [(String, String)]
    var selection: String
    var isEnabled: Bool = true

    static var empty: PickerModel {
        .init(items: [], selection: "")
    }
}
