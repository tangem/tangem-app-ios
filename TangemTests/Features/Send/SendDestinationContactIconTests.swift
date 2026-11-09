//
//  SendDestinationContactIconTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
import BlockchainSdk
import TangemFoundation
@testable import Tangem

@Suite("Send destination contact icon")
@MainActor
struct SendDestinationContactIconTests {
    private static let address = "0xCEa45eb16B3aa9DaA98237EFdcbC1C0263fAE07f"

    private let walletId = UserWalletId(value: Data(repeating: 0xA1, count: 32))
    private let walletPublicKey = Data(repeating: 0xB2, count: 33)
    private let polygon: BSDKBlockchain = .polygon(testnet: false)
    private let ethereum: BSDKBlockchain = .ethereum(testnet: false)

    @Test
    func compactCardShowsTheContactSavedOnTheSendingNetwork() async throws {
        let alena = try makeContact(name: "Alena", blockchain: polygon, createdAt: Date(timeIntervalSince1970: 0))
        let ivan = try makeContact(name: "Ivan", blockchain: ethereum, createdAt: Date(timeIntervalSince1970: 100))

        let icon = await withUserWallets([AddressBookUserWalletModelStub(id: walletId, contacts: [alena, ivan])]) {
            let input = SendDestinationInputStub(
                destination: SendDestination(value: .plain(Self.address), source: .addressBook),
                tokenItem: .blockchain(.init(polygon, derivationPath: nil))
            )
            let viewModel = SendDestinationCompactViewModel(input: input)

            await waitUntil { viewModel.addressIconType != nil }
            return viewModel.addressIconType
        }

        #expect(icon == .contact(AddressBookContactNameIconViewData(contact: alena)))
    }

    @Test
    func addressFieldShowsTheContactSavedOnTheSendingNetwork() async throws {
        let alena = try makeContact(name: "Alena", blockchain: polygon, createdAt: Date(timeIntervalSince1970: 0))
        let ivan = try makeContact(name: "Ivan", blockchain: ethereum, createdAt: Date(timeIntervalSince1970: 100))

        let icon = await withUserWallets([AddressBookUserWalletModelStub(id: walletId, contacts: [alena, ivan])]) {
            let viewModel = SendDestinationAddressViewModel(
                textViewModel: .init(),
                address: .init(string: "", source: .textField),
                iconProvider: CommonSendDestinationAddressAddressIconProvider(
                    tokenItemPublisher: Just(TokenItem.blockchain(.init(polygon, derivationPath: nil)))
                )
            )
            viewModel.update(address: .init(string: Self.address, source: .addressBook))

            await waitUntil { viewModel.addressIconType != nil }
            return viewModel.addressIconType
        }

        #expect(icon == .contact(AddressBookContactNameIconViewData(contact: alena)))
    }

    @Test
    func recentAddressShowsTheContactSavedOnTheSendingNetwork() async throws {
        let alena = try makeContact(name: "Alena", blockchain: polygon, createdAt: Date(timeIntervalSince1970: 0))
        let ivan = try makeContact(name: "Ivan", blockchain: ethereum, createdAt: Date(timeIntervalSince1970: 100))
        let record = SendDestinationSuggestedTransactionRecord(
            id: "recent",
            address: Self.address,
            additionalField: nil,
            isOutgoing: true,
            date: Date(timeIntervalSince1970: 0),
            amountFormatted: "",
            dateFormatted: ""
        )

        let icon = await withUserWallets([AddressBookUserWalletModelStub(id: walletId, contacts: [alena, ivan])]) {
            SendDestinationSuggestedViewModel(
                wallets: [],
                recentTransactions: [record],
                networkId: AddressBookNetworkID(polygon.networkId),
                tapAction: { _ in }
            )
            .suggestedRecentTransaction
            .first?
            .addressIconType
        }

        #expect(icon == .contact(AddressBookContactNameIconViewData(contact: alena)))
    }
}

// MARK: - Helpers

private extension SendDestinationContactIconTests {
    func withUserWallets<T>(_ models: [UserWalletModel], operation: () async -> T) async -> T {
        await InjectedDependenciesIsolation.shared.run {
            let previous = InjectedValues[\.userWalletRepository]
            let repository = FakeUserWalletRepository(models: models)
            repository.selectedModel = models.first
            InjectedValues[\.userWalletRepository] = repository
            defer { InjectedValues[\.userWalletRepository] = previous }
            return await operation()
        }
    }

    func waitUntil(timeout: Duration = .seconds(2), _ condition: @MainActor () -> Bool) async {
        let deadline = ContinuousClock.now + timeout
        while !condition() {
            if ContinuousClock.now >= deadline {
                Issue.record("waitUntil timed out")
                return
            }
            try? await Task.sleep(for: .milliseconds(10))
        }
    }

    func makeContact(name value: String, blockchain: BSDKBlockchain, createdAt: Date) throws -> AddressBookContact {
        let contactId = AddressBookContactID()
        let contactName = try AddressBookContactNameValidator().validate(value)
        let decoded = AddressBookDecodedAddressEntry(
            id: AddressBookAddressEntryID(),
            address: Self.address,
            networkId: AddressBookNetworkID(blockchain.networkId),
            memo: nil,
            signature: Data([0x01])
        )

        let entry = try #require(
            AddressBookVerifiedAddressEntryBuilder(supportedBlockchains: [blockchain]).make(
                verifying: decoded,
                contactId: contactId,
                contactName: contactName,
                walletPublicKey: walletPublicKey,
                verifier: AcceptingAddressBookSignatureVerifier()
            )
        )

        return AddressBookContact(
            id: contactId,
            walletId: walletId,
            name: contactName,
            appearance: AddressBookContactAppearance(rawColor: "MexicanPink"),
            createdAt: createdAt,
            entries: try #require(AddressBookContactVerifiedEntries([entry]))
        )
    }
}

// MARK: - Stubs

private final class SendDestinationInputStub: SendDestinationInput {
    private let destinationSubject: CurrentValueSubject<SendDestination?, Never>
    private let additionalFieldSubject = CurrentValueSubject<SendDestinationAdditionalField, Never>(.notSupported)
    private let tokenItem: TokenItem

    init(destination: SendDestination?, tokenItem: TokenItem) {
        destinationSubject = CurrentValueSubject(destination)
        self.tokenItem = tokenItem
    }

    var destination: SendDestination? { destinationSubject.value }
    var destinationAdditionalField: SendDestinationAdditionalField { additionalFieldSubject.value }
    var destinationPublisher: AnyPublisher<SendDestination?, Never> { destinationSubject.eraseToAnyPublisher() }
    var additionalFieldPublisher: AnyPublisher<SendDestinationAdditionalField, Never> { additionalFieldSubject.eraseToAnyPublisher() }
    var destinationTokenItemPublisher: AnyPublisher<TokenItem, Never> { .just(output: tokenItem) }
}

private final class AddressBookUserWalletModelStub: UserWalletModelMock {
    private let id: UserWalletId
    private let manager: AddressBookManager

    init(id: UserWalletId, contacts: [AddressBookContact]) {
        self.id = id
        manager = AddressBookManagerStub(contacts: contacts)
    }

    override var userWalletId: UserWalletId { id }
    override var addressBookManager: AddressBookManager { manager }
}

private final class AddressBookManagerStub: AddressBookManager {
    let contacts: [AddressBookContact]

    init(contacts: [AddressBookContact]) {
        self.contacts = contacts
    }

    var contactsPublisher: AnyPublisher<[AddressBookContact], Never> { .just(output: contacts) }
    var syncStatePublisher: AnyPublisher<AddressBookSyncState, Never> { .just(output: .synced) }

    func load(silent: Bool) async {}
    func createContact(name: AddressBookContactName, appearance: AddressBookContactAppearance, entries: AddressBookContactDraftEntries) async throws -> AddressBookContactID { AddressBookContactID() }
    func reSignContact(id: AddressBookContactID, name: AddressBookContactName, appearance: AddressBookContactAppearance, entries: AddressBookContactDraftEntries) async throws {}
    func updateContact(id: AddressBookContactID, name: AddressBookContactName, appearance: AddressBookContactAppearance, entries: AddressBookContactDraftEntries) async throws {}
    func deleteContact(id: AddressBookContactID) async throws {}
}
