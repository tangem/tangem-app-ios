////
////  AddCustomTokenViewModel.swift
////  Tangem Tap
////
////  Created by [REDACTED_AUTHOR]
////  Copyright © 2021 Tangem AG. All rights reserved.
////
//
//import Foundation
//import Combine
//import BlockchainSdk
//
//class AddCustomTokenViewModel: ViewModel {
//    
//    weak var assembly: Assembly!
//    weak var navigation: NavigationCoordinator!
//    
//    private enum TokenCreationErrors: LocalizedError {
//        case notAllDataFulfilled, decimalsIsNan
//        
//        var errorDescription: String? {
//            switch self {
//            case .notAllDataFulfilled: return "custom_token_creation_error_empty_fields".localized
//            case .decimalsIsNan: return "custom_token_creation_error_wrong_decimals".localized
//            }
//        }
//    }
//    
//    [REDACTED_USERNAME] var name = ""
//    [REDACTED_USERNAME] var symbolName = ""
//    [REDACTED_USERNAME] var contractAddress = ""
//    [REDACTED_USERNAME] var decimals = ""
//    
//    [REDACTED_USERNAME] var isSavingToken: Bool = false
//    [REDACTED_USERNAME] var tokenSaved: Bool = false
//    
//    [REDACTED_USERNAME] var error: AlertBinder?
//    
//    private let walletModel: WalletModel
//    private var bag: Set<AnyCancellable> = []
//    
//    init(walletModel: WalletModel) {
//        self.walletModel = walletModel
//    }
//    
//    func createToken() {
//        UIApplication.shared.endEditing()
//        guard !name.isEmpty, !symbolName.isEmpty, !contractAddress.isEmpty, !decimals.isEmpty else {
//            error = TokenCreationErrors.notAllDataFulfilled.alertBinder
//            return
//        }
//        
//        guard let decim = UInt(decimals) else {
//            error = TokenCreationErrors.decimalsIsNan.alertBinder
//            return
//        }
//        
//        isSavingToken = true
//        let token = Token(name: name, symbol: symbolName.uppercased(), contractAddress: contractAddress, decimalCount: Int(decim))
//        walletModel.addToken(token)?
//            .sink(receiveCompletion: { [weak self] result in
//                if case let .failure(error) = result {
//                    print("Failed to receive token balance. Error:", error)
//                }
//                self?.isSavingToken = false
//                self?.tokenSaved = true
//            }, receiveValue: { [weak self] amount in
//                self?.isSavingToken = false
//                self?.tokenSaved = true
//            })
//            .store(in: &bag)
//    }
//    
//    func onDisappear() {
//        name = ""
//        symbolName = ""
//        contractAddress = ""
//        decimals = ""
//        tokenSaved = false
//        isSavingToken = false
//    }
//}
