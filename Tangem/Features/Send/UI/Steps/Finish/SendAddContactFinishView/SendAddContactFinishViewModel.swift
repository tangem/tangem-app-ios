//
//  SendAddContactFinishViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemFoundation

class SendAddContactFinishViewModel: ObservableObject {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private let analyticsLogger: any AddressBookAnalyticsLogger

    @Published private(set) var isVisible: Bool = false

    private let sourceToken: SendSourceToken
    private weak var destinationInput: SendDestinationInput?
    private weak var receiveTokenInput: SendReceiveTokenInput?
    private weak var coordinator: SendRoutable?

    private lazy var addressBookWallet: AddressBookWallet? = makeAddressBookWallet()

    init(
        sourceToken: SendSourceToken,
        destinationInput: SendDestinationInput,
        receiveTokenInput: SendReceiveTokenInput?,
        coordinator: SendRoutable,
        analyticsLogger: any AddressBookAnalyticsLogger
    ) {
        self.sourceToken = sourceToken
        self.destinationInput = destinationInput
        self.receiveTokenInput = receiveTokenInput
        self.coordinator = coordinator
        self.analyticsLogger = analyticsLogger

        bind(destinationInput: destinationInput)
    }

    func userDidTapAddContact() {
        analyticsLogger.logAddContactTapped(walletId: sourceToken.userWalletInfo.id.stringValue, source: .sendSuccess)

        guard
            let destination = destinationInput?.destination,
            let addressBookWallet
        else {
            return
        }

        let entry = AddressBookEntryDraft(
            address: destination.value.transactionAddress,
            blockchain: destinationBlockchain,
            memo: memo
        )

        coordinator?.openAddContact(addressBookWallet: addressBookWallet, prefilledEntries: [entry])
    }
}

// MARK: - Private

private extension SendAddContactFinishViewModel {
    var destinationBlockchain: BSDKBlockchain {
        receiveTokenInput?.receiveToken.value?.tokenItem.blockchain ?? sourceToken.tokenItem.blockchain
    }

    var memo: String? {
        switch destinationInput?.destinationAdditionalField {
        case .filled(_, let value, _): value
        default: nil
        }
    }

    func bind(destinationInput: SendDestinationInput) {
        let contactsPublishers = userWalletRepository.models
            .filter { !$0.isUserWalletLocked }
            .map(\.addressBookManager.contactsPublisher)

        guard contactsPublishers.isNotEmpty else {
            return
        }

        let allContactsPublisher = contactsPublishers.combineLatest().map { $0.flattened() }

        Publishers
            .CombineLatest(destinationInput.destinationPublisher, allContactsPublisher)
            .withWeakCaptureOf(self)
            .map { viewModel, args in
                let (destination, contacts) = args

                guard let destination else {
                    return false
                }

                return !viewModel.isSaved(address: destination.value.transactionAddress, contacts: contacts)
            }
            .receiveOnMain()
            .assign(to: &$isVisible)
    }

    func isSaved(address: String, contacts: [AddressBookContact]) -> Bool {
        contacts.contains { contact in
            contact.entries.caseInsensitiveContains(address: address)
        }
    }

    func makeAddressBookWallet() -> AddressBookWallet? {
        let model = userWalletRepository.models
            .first { !$0.isUserWalletLocked && $0.userWalletInfo.id == sourceToken.userWalletInfo.id }

        guard let model else {
            return nil
        }

        let manager = model.addressBookManager
        return AddressBookWallet(
            wallet: model.userWalletInfo,
            addressBookManager: manager,
            addressBookPublisher: manager.contactsPublisher,
            syncStatePublisher: manager.syncStatePublisher
        )
    }
}
