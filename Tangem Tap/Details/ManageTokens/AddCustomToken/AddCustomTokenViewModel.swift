//
//  AddCustomTokenViewModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

class AddCustomTokenViewModel: ViewModel {
    
    weak var assembly: Assembly!
    weak var navigation: NavigationCoordinator!
    
    private enum TokenCreationErrors: LocalizedError {
        case notAllDataFulfilled, decimalsIsNan
        
        var errorDescription: String? {
            switch self {
            case .notAllDataFulfilled: return "custom_token_creation_error_empty_fields".localized
            case .decimalsIsNan: return "custom_token_creation_error_wrong_decimals".localized
            }
        }
    }
    
    @Published var name = ""
    @Published var symbolName = ""
    @Published var contractAddress = ""
    @Published var decimals = ""
    
    @Published var isSavingToken: Bool = false
    @Published var tokenSaved: Bool = false
    
    @Published var error: AlertBinder?
    
    private let walletModel: WalletModel
    private var bag: Set<AnyCancellable> = []
    
    init(walletModel: WalletModel) {
        self.walletModel = walletModel
    }
    
    func createToken() {
        UIApplication.shared.endEditing()
        guard !name.isEmpty, !symbolName.isEmpty, !contractAddress.isEmpty, !decimals.isEmpty else {
            error = TokenCreationErrors.notAllDataFulfilled.alertBinder
            return
        }
        
        guard let decim = UInt(decimals) else {
            error = TokenCreationErrors.decimalsIsNan.alertBinder
            return
        }
        
        isSavingToken = true
        let token = Token(name: name, symbol: symbolName.uppercased(), contractAddress: contractAddress, decimalCount: Int(decim))
        walletModel.addToken(token)?
            .sink(receiveCompletion: { [weak self] result in
                self?.isSavingToken = false
                if case let .failure(error) = result {
                    self?.error = error.alertBinder
                }
            }, receiveValue: { [weak self] amount in
                self?.isSavingToken = false
                self?.tokenSaved = true
            })
            .store(in: &bag)
    }
    
    func onDisappear() {
        name = ""
        symbolName = ""
        contractAddress = ""
        decimals = ""
        tokenSaved = false
        isSavingToken = false
    }
}
