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

class AddCustomTokenViewModel: ViewModel, ObservableObject {
    private enum TokenCreationErrors: LocalizedError {
        case blockchainNotSelected
        case emptyFields
        case invalidDecimals
        case invalidContractAddress
        case invalidDerivationPath
        
        var errorDescription: String? {
            switch self {
            case .blockchainNotSelected:
                return "custom_token_creation_error_network_not_selected".localized
            case .emptyFields:
                return "custom_token_creation_error_empty_fields".localized
            case .invalidDecimals:
                return "custom_token_creation_error_wrong_decimals".localized
            case .invalidContractAddress:
                return "custom_token_creation_error_invalid_contract_address".localized
            case .invalidDerivationPath:
                return "custom_token_creation_error_invalid_derivation_path".localized
            }
        }
    }
    
    private enum TokenSearchError: LocalizedError {
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
    
    weak var assembly: Assembly!
    weak var navigation: NavigationCoordinator!
    weak var cardModel: CardViewModel!
    weak var tokenListService: TokenListService!
    
    @Published var name = ""
    @Published var symbol = ""
    @Published var contractAddress = ""
    @Published var decimals = ""
    
    @Published var blockchains: [(String, String)] = []
    @Published var blockchainName: String = ""
    @Published var blockchainEnabled: Bool = true
    
    @Published var derivationPath = ""
    @Published var derivationPaths: [(String, String)] = []
    
    @Published var error: AlertBinder?
    
    @Published var warningContainer = WarningsContainer()
    @Published var addButtonDisabled = false
    @Published var isLoading = false
    
    @Published private(set) var foundStandardToken: TokenItem?
    
    private var bag: Set<AnyCancellable> = []
    private var blockchainByName: [String: Blockchain] = [:]
    private var blockchainsWithTokens: Set<Blockchain>?
    
    init() {
        Publishers.CombineLatest3($blockchainName, $contractAddress, $derivationPath)
            .dropFirst()
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .setFailureType(to: Error.self)
            .flatMap { (blockchainName, contractAddress, derivationPath) -> AnyPublisher<[CurrencyModel], Error> in
                self.isLoading = true
                
                guard !contractAddress.isEmpty else {
                    return Just([])
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
                
                return self.findToken(contractAddress: contractAddress)
            }
            .sink { _ in
                
            } receiveValue: { [unowned self] currencyModels in
                self.didFinishTokenSearch(currencyModels)
            }
            .store(in: &bag)
    }
    
    func createToken() {
        UIApplication.shared.endEditing()
        
        let tokenItem: TokenItem
        let blockchain: Blockchain
        let derivationPath: DerivationPath?
        do {
            if let foundStandardToken = self.foundStandardToken {
                tokenItem = foundStandardToken
            } else {
                tokenItem = try enteredTokenItem()
            }
            blockchain = try enteredBlockchain()
            derivationPath = try enteredDerivationPath()
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
        
        cardModel.add(items: [(amountType, blockchainNetwork)]) { result in
            switch result {
            case .success:
                self.navigation.mainToCustomToken = false
                self.navigation.mainToAddTokens = false
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
        blockchainName = ""
        name = ""
        symbol = ""
        contractAddress = ""
        decimals = ""
        derivationPath = ""
    }
    
    private func updateBlockchains(_ blockchains: Set<Blockchain>) {
        let defaultItem = ("custom_token_network_input_not_selected".localized, "")
        self.blockchains = [defaultItem] + blockchains.sorted {
            $0.displayName < $1.displayName
        }.map {
            ($0.displayName, $0.codingKey)
        }
        self.blockchainByName = Dictionary(uniqueKeysWithValues: blockchains.map {
            ($0.codingKey, $0)
        })
        self.blockchainEnabled = blockchains.count > 1
        
        
        let newBlockchainName: String?
        if blockchains.count == 1, let firstBlockchain = blockchains.first {
            newBlockchainName = firstBlockchain.codingKey
        } else if blockchainByName[blockchainName] == nil {
            newBlockchainName = ""
        } else {
            newBlockchainName = nil
        }
        
        if let newBlockchainName = newBlockchainName, newBlockchainName != self.blockchainName {
            self.blockchainName = newBlockchainName
        }
    }
    
    private func getBlockchains(withTokenSupport: Bool) -> Set<Blockchain> {
        let cardInfo = cardModel.cardInfo
        
        let supportedTokenItems = SupportedTokenItems()
        let blockchains = supportedTokenItems.blockchains(for: cardInfo.card.walletCurves, isTestnet: cardInfo.isTestnet)
        
        if withTokenSupport {
            if self.blockchainsWithTokens == nil {
                self.blockchainsWithTokens = supportedTokenItems.blockchainsWithTokens(isTestnet: cardInfo.isTestnet)
            }
            
            return blockchains
                .filter {
                    self.blockchainsWithTokens?.contains($0) ?? false
                }
        } else {
            return blockchains
        }
    }
    
    private func updateDerivationPaths() {
        let derivationStyle = cardModel.cardInfo.card.derivationStyle
        
        let defaultItem = ("custom_token_derivation_path_default".localized, "")
        self.derivationPaths = [defaultItem] + getBlockchains(withTokenSupport: true)
            .map {
                let derivationPath = $0.derivationPath(for: derivationStyle)?.rawPath ?? ""
                let description = "\($0.displayName) (\(derivationPath))"
                return (description, derivationPath)
            }
            .sorted {
                $0.0 < $1.0
            }
    }
    
    private func enteredTokenItem() throws -> TokenItem {
        let blockchain = try enteredBlockchain()
        
        if contractAddress.isEmpty && name.isEmpty && symbol.isEmpty && decimals.isEmpty {
            return .blockchain(blockchain)
        } else {
            guard blockchain.validate(address: contractAddress) else {
                throw TokenCreationErrors.invalidContractAddress
            }
            
            guard !name.isEmpty, !symbol.isEmpty, !decimals.isEmpty else {
                throw TokenCreationErrors.emptyFields
            }
            
            guard let decimals = Int(decimals) else {
                throw TokenCreationErrors.invalidDecimals
            }
            
            let token = Token(
                name: name,
                symbol: symbol.uppercased(),
                contractAddress: contractAddress,
                decimalCount: decimals
            )
            
            return .token(token, blockchain)
        }
    }
    
    private func enteredBlockchain() throws -> Blockchain {
        guard let blockchain = blockchainByName[blockchainName] else {
            throw TokenCreationErrors.blockchainNotSelected
        }
        
        return blockchain
    }
    
    private func enteredDerivationPath() throws -> DerivationPath? {
        if !self.derivationPath.isEmpty {
            let derivationPath = try? DerivationPath(rawPath: self.derivationPath)
            
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
        
        guard let blockchain = blockchainByName[blockchainName] else {
            return
        }
        
        let cardTokenItems = cardModel.tokenItemsRepository.getItems(for: cardId)
        let checkingContractAddress = !contractAddress.isEmpty
        let derivationPath = (try? DerivationPath(rawPath: derivationPath)) ?? blockchain.derivationPath(for: derivationStyle)
        
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
    
    private func findToken(contractAddress: String) -> AnyPublisher<[CurrencyModel], Error> {
        return tokenListService
            .checkContractAddress(contractAddress: contractAddress, networkId: nil)
            .eraseError()
            .eraseToAnyPublisher()
    }
    
    private func didFinishTokenSearch(_ currencyModels: [CurrencyModel]) {
        warningContainer.removeAll()
        addButtonDisabled = false
        isLoading = false
        
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
        
        let firstTokenItem = currencyModels.first?.items.first
        
        if currencyModels.count == 1 {
            foundStandardToken = firstTokenItem
        } else {
            foundStandardToken = nil
        }
        
        if let token = firstTokenItem?.token {
            decimals = "\(token.decimalCount)"
            symbol = token.symbol
            name = token.name
        } else {
            decimals = ""
            symbol = ""
            name = ""
        }
        
        do {
            if currencyModels.isEmpty && !contractAddress.isEmpty {
                throw TokenSearchError.failedToFindToken
            }
            
            try checkLocalStorage()
        } catch {
            let tokenSearchError = error as? TokenSearchError
            addButtonDisabled = tokenSearchError?.preventsFromAdding ?? false
            warningContainer.removeAll()
            
            if let tokenSearchError = tokenSearchError {
                warningContainer.add(tokenSearchError.appWarning)
            }
        }
    }
}
