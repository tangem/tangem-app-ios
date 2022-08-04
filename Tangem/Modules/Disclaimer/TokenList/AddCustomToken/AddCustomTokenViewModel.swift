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
    @Injected(\.tokenItemsRepository) private var tokenItemsRepository: TokenItemsRepository

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
        foundStandardToken == nil && selectedBlockchainSupportsTokens
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
    private var foundStandardToken: CoinModel?
    private unowned let coordinator: AddCustomTokenRoutable

    init(cardModel: CardViewModel, coordinator: AddCustomTokenRoutable) {
        self.coordinator = coordinator
        self.cardModel = cardModel

        Publishers.CombineLatest3(
            $blockchainsPicker.map { $0.selection }.removeDuplicates(),
            $contractAddress.removeDuplicates(),
            $derivationsPicker.map { $0.selection }.removeDuplicates()
        )
        .dropFirst()
        .debounce(for: 0.5, scheduler: RunLoop.main)
        .flatMap { [unowned self] (blockchainName, contractAddress, derivationPath) -> AnyPublisher<[CoinModel], Never> in
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

        $blockchainsPicker.map { $0.selection }
            .sink { [unowned self] newBlockchainName in
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
            if let foundStandardTokenItem = self.foundStandardToken?.items.first {
                tokenItem = foundStandardTokenItem
            } else {
                tokenItem = try enteredTokenItem()
            }
            blockchain = try enteredBlockchain()
            derivationPath = try enteredDerivationPath()

            if case let .token(_, blockchain) = tokenItem,
               case .solana = blockchain,
               !cardModel.config.features.contains(.longHashesSupported)
            {
                throw TokenCreationErrors.tokensNotSupported
            }
        } catch {
            self.error = error.alertBinder
            return
        }

        let amountType: Amount.AmountType
        if let token = tokenItem.token {
            amountType = .token(value: token)
        } else {
            amountType = .coin
        }

        let derivationStyle = cardModel.cardInfo.card.derivationStyle
        let blockchainNetwork = BlockchainNetwork(blockchain, derivationPath: derivationPath ?? blockchain.derivationPath(for: derivationStyle))

        cardModel.add(items: [(amountType, blockchainNetwork)]) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                self.closeModule()
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

    private func updateBlockchains(_ blockchains: Set<Blockchain>) {
        let defaultItem = ("custom_token_network_input_not_selected".localized, "")

        let newBlockchains = [defaultItem] + blockchains.sorted {
            $0.displayName < $1.displayName
        }.map {
            ($0.displayName, $0.codingKey)
        }
        self.blockchainByName = Dictionary(uniqueKeysWithValues: blockchains.map {
            ($0.codingKey, $0)
        })

        var newBlockchainName = self.blockchainsPicker.selection
        if blockchains.count == 1, let firstBlockchain = blockchains.first {
            newBlockchainName = firstBlockchain.codingKey
        } else if blockchainByName[blockchainsPicker.selection] == nil {
            newBlockchainName = ""
        }

        self.blockchainsPicker = .init(items: newBlockchains, selection: newBlockchainName, isEnabled: blockchains.count > 1)
    }

    private func getBlockchains(withTokenSupport: Bool) -> Set<Blockchain> {
        let blockchains = cardModel.config.supportedBlockchains

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
        let derivationStyle = cardModel.cardInfo.card.derivationStyle

        let defaultItem = ("custom_token_derivation_path_default".localized, "")

        let evmBlockchains = getBlockchains(withTokenSupport: false).filter { $0.isEvm }
        let evmDerivationPaths: [(String, String)]
        if !cardModel.cardInfo.card.settings.isHDWalletAllowed {
            evmDerivationPaths = []
        } else {
            evmDerivationPaths = evmBlockchains
                .compactMap {
                    guard let derivationPath = $0.derivationPath(for: derivationStyle) else {
                        return nil
                    }
                    let derivationPathFormatted = derivationPath.rawPath
                    let description = "\($0.displayName) (\(derivationPathFormatted))"
                    return (description, derivationPathFormatted)
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

            let token = Token(
                name: name,
                symbol: symbol.uppercased(),
                contractAddress: enteredContractAddress,
                decimalCount: decimals
            )

            return .token(token, blockchain)
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

        let rawPath = derivationsPicker.selection
        if !rawPath.isEmpty {
            let derivationPath = try? DerivationPath(rawPath: rawPath)

            if derivationPath == nil {
                throw TokenCreationErrors.invalidDerivationPath
            }

            return derivationPath
        } else {
            return nil
        }
    }

    private func checkLocalStorage() throws {
        let derivationStyle = cardModel.cardInfo.card.derivationStyle
        let cardId = cardModel.cardInfo.card.cardId

        guard let blockchain = try? enteredBlockchain() else {
            return
        }

        let cardTokenItems = tokenItemsRepository.getItems(for: cardId)
        let checkingContractAddress = !contractAddress.isEmpty
        let derivationPath = try? enteredDerivationPath() ?? blockchain.derivationPath(for: derivationStyle)

        let blockchainNetwork = BlockchainNetwork(blockchain, derivationPath: derivationPath)

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
        warningContainer.removeAll()
        addButtonDisabled = false
        isLoading = false

        let previouslyFoundStandardToken = foundStandardToken

        let currencyModelBlockchains = currencyModels.reduce(Set<Blockchain>()) { partialResult, currencyModel in
            partialResult.union(currencyModel.items.map { $0.blockchain })
        }

        let blockchains: Set<Blockchain>
        if !currencyModelBlockchains.isEmpty {
            blockchains = currencyModelBlockchains
        } else {
            blockchains = getBlockchains(withTokenSupport: true)
        }
        updateBlockchains(blockchains)

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

        do {
            try checkLocalStorage()

            if currencyModels.isEmpty,
               let blockchain = try? enteredBlockchain(),
               let _ = try? enteredContractAddress(in: blockchain)
            {
                throw TokenSearchError.failedToFindToken
            }
        } catch {
            let tokenSearchError = error as? TokenSearchError
            addButtonDisabled = tokenSearchError?.preventsFromAdding ?? false
            warningContainer.removeAll()

            if let tokenSearchError = tokenSearchError {
                warningContainer.add(tokenSearchError.appWarning)
            }
        }
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
