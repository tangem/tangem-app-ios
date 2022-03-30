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
    enum TokenType: Hashable {
        case blockchain
        case token
    }
    
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
    
    weak var assembly: Assembly!
    weak var navigation: NavigationCoordinator!
    weak var cardModel: CardViewModel?
    
    @Published var type: TokenType = .blockchain
    @Published var name = ""
    @Published var symbol = ""
    @Published var contractAddress = ""
    @Published var decimals = ""
    @Published var derivationPath = ""
    
    @Published var blockchains: [(String, String)] = []
    @Published var blockchainName: String = ""

    @Published var error: AlertBinder?
    
    var warning: String?
    
    private var bag: Set<AnyCancellable> = []
    private var blockchainByName: [String: Blockchain] = [:]
    private var blockchainsWithTokens: Set<Blockchain>?
    private var cachedTokens: [Blockchain: [Token]] = [:]
    private var foundStandardToken: Token?
    
    init() {
        $type
            .sink {
                self.updateBlockchains(type: $0)
            }
            .store(in: &bag)
        
        Publishers.CombineLatest3($type, $blockchainName, $contractAddress)
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .setFailureType(to: Error.self)
            .flatMap { (type, blockchainName, contractAddress) in
                self.validateToken(type: type, blockchainName: blockchainName, contractAddress: contractAddress)
                    .catch { [unowned self] error -> AnyPublisher<Token?, Error> in
                        switch error {
                        case CustomTokenError.failedToFindToken:
                            
                            
                            #warning("l10n")
                            
                            
                            self.warning = "Note that tokens can be created by anyone. Be aware of adding scam tokens, they can cost nothing."
                        case CustomTokenError.alreadyAdded:
                            

                            #warning("l10n")


                            self.warning = "This token/network has already been added to your list"
                        default:
                            break
                        }
                        return Just(nil).setFailureType(to: Error.self).eraseToAnyPublisher()
                    }
            }
            .sink { completion in
                print(completion)
            } receiveValue: { [unowned self] token in
                print(token)
                self.foundStandardToken = token
            }
            .store(in: &bag)
    }
    
    func createToken() {
        guard let cardModel = cardModel else {
            return
        }
        
        UIApplication.shared.endEditing()
        
        
        switch enteredTokenItem() {
        case .failure(let error):
            self.error = error.alertBinder
        case .success(let tokenItem):
            cardModel.manageTokenItems(add: [tokenItem], remove: []) { result in
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
    }
    
    func onAppear() {
        updateBlockchains(type: type)
    }
    
    func onDisappear() {
        blockchainName = ""
        name = ""
        symbol = ""
        contractAddress = ""
        decimals = ""
    }
    
    private func updateBlockchains(type: TokenType) {
        let blockchains = getBlockchains(withTokenSupport: type == .token)
        
        self.blockchains = blockchains.map {
            ($0.displayName, $0.codingKey)
        }
        self.blockchainByName = Dictionary(uniqueKeysWithValues: blockchains.map {
            ($0.codingKey, $0)
        })
        
        if blockchainByName[blockchainName] == nil {
            self.blockchainName = ""
        }
    }
    
    private func getBlockchains(withTokenSupport: Bool) -> [Blockchain] {
        guard let cardInfo = cardModel?.cardInfo else {
            return []
        }
        
        let supportedTokenItems = SupportedTokenItems()
        let blockchains = supportedTokenItems
            .blockchains(for: cardInfo.card.walletCurves, isTestnet: cardInfo.isTestnet)
            .sorted {
                $0.displayName < $1.displayName
            }
        
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
    
    private func enteredTokenItem() -> Result<TokenItem, Error> {
        guard let blockchain = blockchainByName[blockchainName] else {
            return .failure(TokenCreationErrors.blockchainNotSelected)
        }
        
        let derivationPath: DerivationPath?
        if !self.derivationPath.isEmpty {
            derivationPath = try? DerivationPath(rawPath: self.derivationPath)
            
            if derivationPath == nil {
                return .failure(TokenCreationErrors.invalidDerivationPath)
            }
        } else {
            derivationPath = nil
        }
        
        if type == .token {
            guard blockchain.validate(address: contractAddress) else {
                return .failure(TokenCreationErrors.invalidContractAddress)
            }
        
            guard !name.isEmpty, !symbol.isEmpty, !decimals.isEmpty else {
                return .failure(TokenCreationErrors.emptyFields)
            }
            
            guard let decimals = Int(decimals) else {
                return .failure(TokenCreationErrors.invalidDecimals)
            }

            let token = Token(
                name: name,
                symbol: symbol.uppercased(),
                contractAddress: contractAddress,
                decimalCount: decimals,
                blockchain: blockchain
            )
            
            return .success(.init(token, derivationPath: derivationPath))
        } else {
            return .success(.init(blockchain, derivationPath: derivationPath))
        }
    }
    
    private func validateToken(type: TokenType, blockchainName: String, contractAddress: String) -> AnyPublisher<Token?, Error> {
        guard
            type == .token,
            let blockchain = blockchainByName[blockchainName]
        else {
            return Just(nil)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        if case let .success(enteredTokenItem) = self.enteredTokenItem(),
           let cardTokenItems = cardModel?.tokenItemsRepository.getItems(for: cardModel?.cardInfo.card.cardId ?? ""),
           cardTokenItems.contains(enteredTokenItem)
        {
            return .anyFail(error: CustomTokenError.alreadyAdded)
        }
        
        return findToken(contractAddress: contractAddress, blockchain: blockchain)
    }
    
    private func findToken(contractAddress: String, blockchain: Blockchain) -> AnyPublisher<Token?, Error> {
        let tokens: [Token]
        if let cache = cachedTokens[blockchain] {
            tokens = cache
        } else {
            let supportedTokenItems = SupportedTokenItems()
            tokens = supportedTokenItems.tokens(for: blockchain)
            cachedTokens[blockchain] = tokens
        }
        
        if let token = tokens.first(where: { $0.contractAddress == contractAddress }) {
            return Just(token).setFailureType(to: Error.self).eraseToAnyPublisher()
        } else {
            return .anyFail(error: CustomTokenError.failedToFindToken)
        }
    }
    
    private enum CustomTokenError: Error {
        case alreadyAdded
        case failedToFindToken
    }
}
