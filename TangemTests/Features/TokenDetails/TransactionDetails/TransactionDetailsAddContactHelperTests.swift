//
//  TransactionDetailsAddContactHelperTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
import TangemFoundation
@testable import Tangem
@testable import TangemExpress

@Suite("TransactionDetailsAddContactHelper")
struct TransactionDetailsAddContactHelperTests {
    private let blockchain: BSDKBlockchain = .ethereum(testnet: false)
    private let otherBlockchain: BSDKBlockchain = .bitcoin(testnet: false)
    private let counterparty = "0xCounterparty"

    // MARK: - Operation kind

    @Test(arguments: plainTransferTypes)
    func offersTheCounterpartyOfAPlainTransfer(type: TransactionViewModel.TransactionType) {
        let helper = makeHelper(
            contacts: [],
            isAddressBookSynced: true,
            transactionType: type,
            interactionAddress: .user(counterparty)
        )

        #expect(helper.addressToSave(for: makeRecord(expressBranch: nil)) == counterparty)
    }

    @Test(arguments: nonPlainTransferTypes)
    func ignoresOperationsWhoseCounterpartyIsNotAPerson(type: TransactionViewModel.TransactionType) {
        let helper = makeHelper(
            contacts: [],
            isAddressBookSynced: true,
            transactionType: type,
            interactionAddress: .user(counterparty)
        )

        #expect(helper.addressToSave(for: makeRecord(expressBranch: nil)) == nil)
    }

    @Test(arguments: ExpressBranch.allCases)
    func ignoresExpressEnrichedRecords(branch: ExpressBranch) {
        let helper = makeHelper(
            contacts: [],
            isAddressBookSynced: true,
            transactionType: .transfer,
            interactionAddress: .user(counterparty)
        )

        #expect(helper.addressToSave(for: makeRecord(expressBranch: branch)) == nil)
    }

    // MARK: - Counterparty address

    @Test
    func offersTheFirstAddressOfAMultiCounterpartyTransaction() {
        let helper = makeHelper(
            contacts: [],
            isAddressBookSynced: true,
            transactionType: .transfer,
            interactionAddress: .multiple(["0xFirst", "0xSecond"])
        )

        #expect(helper.addressToSave(for: makeRecord(expressBranch: nil)) == "0xFirst")
    }

    @Test(arguments: machineAndUnresolvableInteractionAddresses)
    func ignoresMachineAndUnresolvableCounterparties(interactionAddress: TransactionViewModel.InteractionAddressType) {
        let helper = makeHelper(
            contacts: [],
            isAddressBookSynced: true,
            transactionType: .transfer,
            interactionAddress: interactionAddress
        )

        #expect(helper.addressToSave(for: makeRecord(expressBranch: nil)) == nil)
    }

    // MARK: - Address book state

    /// Until the book syncs its contacts are a possibly stale cache, and the editor would reject the save.
    @Test
    func hidesTheActionUntilTheAddressBookIsSynced() {
        let helper = makeHelper(
            contacts: [],
            isAddressBookSynced: false,
            transactionType: .transfer,
            interactionAddress: .user(counterparty)
        )

        #expect(helper.addressToSave(for: makeRecord(expressBranch: nil)) == nil)
    }

    @Test
    func hidesTheActionOnceTheAddressIsSavedOnTheSameNetwork() throws {
        let helper = try makeHelper(
            contacts: [makeContact(named: "Alice", address: counterparty, on: blockchain)],
            isAddressBookSynced: true,
            transactionType: .transfer,
            interactionAddress: .user(counterparty)
        )

        #expect(helper.addressToSave(for: makeRecord(expressBranch: nil)) == nil)
    }

    @Test
    func hidesTheActionRegardlessOfTheSavedAddressCase() throws {
        let helper = try makeHelper(
            contacts: [makeContact(named: "Alice", address: counterparty.uppercased(), on: blockchain)],
            isAddressBookSynced: true,
            transactionType: .transfer,
            interactionAddress: .user(counterparty)
        )

        #expect(helper.addressToSave(for: makeRecord(expressBranch: nil)) == nil)
    }

    /// A per-wallet book keys contacts on `(address, networkId)`, so the same address elsewhere doesn't count.
    @Test
    func keepsTheActionWhenTheAddressIsSavedOnAnotherNetworkOnly() throws {
        let helper = try makeHelper(
            contacts: [makeContact(named: "Alice", address: counterparty, on: otherBlockchain)],
            isAddressBookSynced: true,
            transactionType: .transfer,
            interactionAddress: .user(counterparty)
        )

        #expect(helper.addressToSave(for: makeRecord(expressBranch: nil)) == counterparty)
    }

    @Test
    func keepsTheActionWhenOnlyOtherAddressesAreSaved() throws {
        let helper = try makeHelper(
            contacts: [makeContact(named: "Alice", address: "0xSomeoneElse", on: blockchain)],
            isAddressBookSynced: true,
            transactionType: .transfer,
            interactionAddress: .user(counterparty)
        )

        #expect(helper.addressToSave(for: makeRecord(expressBranch: nil)) == counterparty)
    }

    // MARK: - Test arguments

    private static var plainTransferTypes: [TransactionViewModel.TransactionType] {
        // Did you get a compilation error here? If so, add your new transaction type either to
        // `plainTransferTypes` or to `nonPlainTransferTypes`, depending on whether the add-contact
        // action should be offered for it
        switch TransactionViewModel.TransactionType.transfer {
        case .transfer: break
        case .gaslessTransfer: break
        case .tangemPay(.transfer): break
        case .tangemPay(.fee): break
        case .tangemPay(.spend): break
        case .swap: break
        case .onramp: break
        case .approve: break
        case .stake: break
        case .unstake: break
        case .vote: break
        case .withdraw: break
        case .claimRewards: break
        case .restake: break
        case .yieldDeploy: break
        case .yieldEnter: break
        case .yieldEnterCoin: break
        case .yieldInit: break
        case .yieldReactivate: break
        case .yieldSend: break
        case .yieldTopup: break
        case .yieldWithdraw: break
        case .yieldWithdrawCoin: break
        case .gaslessTransactionFee: break
        case .operation: break
        case .unknownOperation: break
        }

        return [
            .transfer,
            .gaslessTransfer,
            .tangemPay(.transfer(name: "Tangem Pay")),
        ]
    }

    private static var nonPlainTransferTypes: [TransactionViewModel.TransactionType] {
        [
            .swap,
            .onramp,
            .approve,
            .stake,
            .unstake,
            .vote,
            .withdraw,
            .claimRewards,
            .restake,
            .yieldDeploy,
            .yieldEnter,
            .yieldEnterCoin,
            .yieldInit,
            .yieldReactivate,
            .yieldSend,
            .yieldTopup,
            .yieldWithdraw,
            .yieldWithdrawCoin,
            .gaslessTransactionFee,
            .operation(name: "Mint"),
            .unknownOperation,
            .tangemPay(.fee(name: "Service fee")),
            .tangemPay(.spend(name: "Coffee", icon: nil, isDeclined: false, isNegativeAmount: true)),
        ]
    }

    private static var machineAndUnresolvableInteractionAddresses: [TransactionViewModel.InteractionAddressType] {
        // Did you get a compilation error here? If so, add your new interaction address type to
        // `machineAndUnresolvableInteractionAddresses` if it carries no usable counterparty address,
        // otherwise cover it by the tests above the way `.user` and `.multiple` are covered
        switch TransactionViewModel.InteractionAddressType.user("") {
        case .contract: break
        case .staking: break
        case .custom: break
        case .multiple: break
        case .user: break
        }

        return [
            .contract("0xContract"),
            .staking(validator: "0xValidator"),
            .custom(message: "Tangem Pay"),
            .multiple([]),
        ]
    }

    // MARK: - Fixtures

    private func makeHelper(
        contacts: [AddressBookContact],
        isAddressBookSynced: Bool,
        transactionType: TransactionViewModel.TransactionType,
        interactionAddress: TransactionViewModel.InteractionAddressType
    ) -> TransactionDetailsAddContactHelper {
        TransactionDetailsAddContactHelper(
            networkId: AddressBookNetworkID(blockchain.networkId),
            contacts: contacts,
            isAddressBookSynced: isAddressBookSynced,
            transactionType: transactionType,
            interactionAddress: interactionAddress
        )
    }

    private func makeRecord(expressBranch: ExpressBranch?) -> TransactionRecord {
        let record = TransactionRecord(
            hash: "hash",
            index: 0,
            source: .single(.init(address: "0xSource", amount: 1)),
            destination: .single(.init(address: .user(counterparty), amount: 1)),
            fee: ExpressMergeTestDataFactory.ethereumToken.zeroFee,
            status: .confirmed,
            isOutgoing: true,
            type: .transfer,
            date: ExpressMergeTestDataFactory.baseDate,
            tokenTransfers: [],
            nonce: nil
        )

        switch expressBranch {
        case .swap:
            return record.withExpressExtraInfo(.exchange(makeExchangeInfo()))
        case .onramp:
            return record.withExpressExtraInfo(.onramp(makeOnrampInfo()))
        case nil:
            return record
        }
    }

    private func makeExchangeInfo() -> ExchangeTransactionInfo {
        let fromCurrency = ExpressMergeTestDataFactory.matchingCurrency(for: ExpressMergeTestDataFactory.ethereumToken)
        let toCurrency = ExpressMergeTestDataFactory.matchingCurrency(for: ExpressMergeTestDataFactory.bitcoinToken)

        return ExchangeTransactionInfo(
            transaction: ExpressMergeTestDataFactory.exchangeTransaction(
                txId: "tx",
                status: .sending,
                fromAddress: "0xFrom",
                payInAddress: "0xIn",
                payInHash: nil,
                payOutAddress: counterparty,
                payOutHash: nil,
                fromCurrency: fromCurrency,
                fromAmount: 1,
                fromActualAmount: nil,
                toCurrency: toCurrency,
                toAmount: 1,
                toActualAmount: nil,
                refund: nil,
                createdAt: ExpressMergeTestDataFactory.baseDate,
                updatedAt: ExpressMergeTestDataFactory.baseDate
            ),
            provider: nil,
            cryptoCurrencies: [
                fromCurrency: ExpressMergeTestDataFactory.ethereumToken,
                toCurrency: ExpressMergeTestDataFactory.bitcoinToken,
            ]
        )
    }

    private func makeOnrampInfo() -> OnrampTransactionInfo {
        OnrampTransactionInfo(
            transaction: ExpressMergeTestDataFactory.onrampTransaction(
                txId: "tx",
                status: .finished,
                payOutAddress: counterparty,
                payOutHash: nil,
                toCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: ExpressMergeTestDataFactory.ethereumToken),
                toAmount: 1,
                toActualAmount: 1,
                createdAt: ExpressMergeTestDataFactory.baseDate,
                updatedAt: ExpressMergeTestDataFactory.baseDate
            ),
            provider: nil,
            fiatCurrency: nil,
            cryptoCurrencies: [:]
        )
    }

    private func makeContact(named name: String, address: String, on blockchain: BSDKBlockchain) throws -> AddressBookContact {
        let contactId = AddressBookContactID()
        let contactName = try AddressBookContactNameValidator().validate(name)

        let decoded = AddressBookDecodedAddressEntry(
            id: AddressBookAddressEntryID(),
            address: address,
            networkId: AddressBookNetworkID(blockchain.networkId),
            memo: nil,
            signature: Data([0x01])
        )

        let built = AddressBookVerifiedAddressEntryBuilder(supportedBlockchains: [blockchain]).make(
            verifying: decoded,
            contactId: contactId,
            contactName: contactName,
            walletPublicKey: Data(repeating: 0xB2, count: 33),
            verifier: AddressBookSignatureVerifyingStub()
        )

        let verified = try #require(built)
        let entries = try #require(AddressBookContactVerifiedEntries([verified]))

        return AddressBookContact(
            id: contactId,
            walletId: UserWalletId(value: Data([0x01])),
            name: contactName,
            appearance: AddressBookContactAppearance(rawColor: "MexicanPink"),
            entries: entries
        )
    }
}

// MARK: - Stubs

private extension TransactionDetailsAddContactHelperTests {
    struct AddressBookSignatureVerifyingStub: AddressBookSignatureVerifying {
        func isSignatureValid(_ signature: Data, of digest: Data, walletPublicKey: Data) -> Bool {
            true
        }
    }
}
