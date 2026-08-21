//
//  TransactionDetailsAddContactHelper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct TransactionDetailsAddContactHelper {
    private let networkId: AddressBookNetworkID
    private let contacts: [AddressBookContact]
    private let isAddressBookSynced: Bool
    private let transactionType: TransactionViewModel.TransactionType
    private let interactionAddress: TransactionViewModel.InteractionAddressType

    private var counterpartyAddress: String? {
        switch interactionAddress {
        case .user(let address):
            return address
        case .multiple(let addresses):
            return addresses.first
        case .contract,
             .staking,
             .custom:
            return nil
        }
    }

    private var isPlainTransfer: Bool {
        switch transactionType {
        case .transfer,
             .gaslessTransfer,
             .tangemPay(.transfer):
            return true

        case .swap,
             .onramp,
             .tangemPay(.fee),
             .tangemPay(.spend),
             .yieldDeploy,
             .yieldEnter,
             .yieldEnterCoin,
             .yieldInit,
             .yieldReactivate,
             .yieldSend,
             .yieldTopup,
             .yieldWithdraw,
             .yieldWithdrawCoin,
             .stake,
             .unstake,
             .vote,
             .withdraw,
             .claimRewards,
             .restake,
             .approve,
             .gaslessTransactionFee,
             .operation,
             .unknownOperation:
            return false
        }
    }

    init(
        networkId: AddressBookNetworkID,
        contacts: [AddressBookContact],
        isAddressBookSynced: Bool,
        transactionType: TransactionViewModel.TransactionType,
        interactionAddress: TransactionViewModel.InteractionAddressType
    ) {
        self.networkId = networkId
        self.contacts = contacts
        self.isAddressBookSynced = isAddressBookSynced
        self.transactionType = transactionType
        self.interactionAddress = interactionAddress
    }

    func addressToSave(for record: TransactionRecord) -> String? {
        // Ignoring swap, onramp transactions and various contract calls
        // Also, the address book must be synced to avoid saving a duplicate contact
        guard
            isAddressBookSynced,
            record.expressExtraInfo == nil,
            isPlainTransfer,
            let counterpartyAddress,
            !isSaved(counterpartyAddress)
        else {
            return nil
        }

        return counterpartyAddress
    }

    private func isSaved(_ address: String) -> Bool {
        contacts.contains { $0.entries.caseInsensitiveContains(address: address, networkId: networkId) }
    }
}
