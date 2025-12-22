//
//  SendTokenHeaderProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemLocalization

struct SendTokenHeaderProvider: SendGenericTokenHeaderProvider {
    @Injected(\.userWalletRepository) private var userWalletRepository: any UserWalletRepository
    @Injected(\.cryptoAccountsGlobalStateProvider) private var cryptoAccountsGlobalStateProvider: CryptoAccountsGlobalStateProvider

    private let userWalletInfo: UserWalletInfo
    private let account: (any BaseAccountModel)?
    private let flowActionType: SendFlowActionType

    init(
        userWalletInfo: UserWalletInfo,
        account: (any BaseAccountModel)?,
        flowActionType: SendFlowActionType
    ) {
        self.userWalletInfo = userWalletInfo
        self.account = account
        self.flowActionType = flowActionType
    }

    func makeSendTokenHeader() -> SendTokenHeader {
        let hasMultipleAccounts = cryptoAccountsGlobalStateProvider.globalCryptoAccountsState() == .multiple

        if hasMultipleAccounts, let account {
            let icon = AccountModelUtils.UI.iconViewData(accountModel: account)
            return .account(name: account.name, icon: icon)
        }

        switch flowActionType {
        case .send where userWalletRepository.hasOnlyOneWallet:
            return .action(name: Localization.sendFromTitle)
        default:
            return .wallet(name: userWalletInfo.name)
        }
    }
}
