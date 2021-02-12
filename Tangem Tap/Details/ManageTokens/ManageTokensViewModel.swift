//
//  ManageTokensViewModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class ManageTokensViewModel: ViewModel {
    weak var assembly: Assembly!
    weak var navigation: NavigationCoordinator!
    
    var walletModel: WalletModel
    
    var addTokensModel: AddNewTokensViewModel {
        assembly.makeAddTokensViewModel(for: walletModel)
    }
    
    init(walletModel: WalletModel) {
        self.walletModel = walletModel
    }
    
    func removeToken(_ model: TokenBalanceViewModel) {
        walletModel.removeToken(model.token)
        objectWillChange.send()
    }
    
}
