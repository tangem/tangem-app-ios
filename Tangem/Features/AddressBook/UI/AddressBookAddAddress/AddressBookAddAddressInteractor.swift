//
//  AddressBookAddAddressInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemLocalization
import BlockchainSdk

protocol AddressBookAddAddressOutput: AnyObject {
    var contactHasUnsavedChanges: Bool { get }
    func userDidAddAddress(entries: [AddressBookEntryDraft], replacing: [AddressBookAddressEntryID])
}

protocol AddressBookAddAddressInteractor {
    var addressValid: AnyPublisher<Bool, Never> { get }
    var addressError: AnyPublisher<String?, Never> { get }
    var additionalFieldType: AnyPublisher<SendDestinationAdditionalFieldType?, Never> { get }
    var addressAdditionalFieldError: AnyPublisher<String?, Never> { get }
    var resolvedNetworks: AnyPublisher<Set<BSDKBlockchain>, Never> { get }
    var selectedNetworks: AnyPublisher<Set<BSDKBlockchain>, Never> { get }
    var isAddAddressEnabledPublisher: AnyPublisher<Bool, Never> { get }
    var hasUnsavedChanges: Bool { get }

    func update(address: String, source: Analytics.DestinationAddressSource)
    func update(additionalField: String)
    func update(selectedNetworks: Set<BSDKBlockchain>)

    func userDidRequestSave()

    func logScreenOpened()
}

enum AddressBookAddAddressOptions {
    case add
    case edit(address: String, memo: String?, networks: Set<BSDKBlockchain>, replacing: [AddressBookAddressEntryID])
}

final class CommonAddressBookAddAddressInteractor {
    private let contactId: AddressBookContactID?
    private let analyticsLogger: any AddressBookAnalyticsLogger

    private let userWalletInfo: UserWalletInfo
    private weak var output: AddressBookAddAddressOutput?
    private let replacing: [AddressBookAddressEntryID]
    private let reservedContacts: [AddressBookContact]

    private let addressResolver = AddressBlockchainResolver()

    private let _address = CurrentValueSubject<String, Never>("")
    private let _additionalField = CurrentValueSubject<SendDestinationAdditionalField, Never>(.notSupported)

    private let _addressValid = CurrentValueSubject<Bool, Never>(false)
    private let _addressError = CurrentValueSubject<Error?, Never>(nil)
    private let _additionalFieldType = CurrentValueSubject<SendDestinationAdditionalFieldType?, Never>(.none)
    private let _addressAdditionalFieldError = CurrentValueSubject<Error?, Never>(nil)
    private let _resolvedNetworks = CurrentValueSubject<Set<BSDKBlockchain>, Never>([])
    private let _selectedNetworks = CurrentValueSubject<Set<BSDKBlockchain>, Never>([])
    private var bag = Set<AnyCancellable>()

    init(
        userWalletInfo: UserWalletInfo,
        contactId: AddressBookContactID?,
        output: AddressBookAddAddressOutput,
        options: AddressBookAddAddressOptions,
        reservedContacts: [AddressBookContact],
        analyticsLogger: any AddressBookAnalyticsLogger
    ) {
        self.userWalletInfo = userWalletInfo
        self.contactId = contactId
        self.output = output
        self.reservedContacts = reservedContacts
        self.analyticsLogger = analyticsLogger

        switch options {
        case .add:
            replacing = []
        case .edit(let address, let memo, let networks, let replacing):
            self.replacing = replacing
            update(address: address, source: .textField)

            let validSelected = networks.intersection(_resolvedNetworks.value)
            if validSelected.isNotEmpty {
                update(selectedNetworks: validSelected)
            }

            if let memo {
                update(additionalField: memo)
            }
        }

        bindAnalytics()
    }
}

// MARK: - AddressBookAddAddressInteractor

extension CommonAddressBookAddAddressInteractor: AddressBookAddAddressInteractor {
    var addressValid: AnyPublisher<Bool, Never> {
        _addressValid.eraseToAnyPublisher()
    }

    var addressError: AnyPublisher<String?, Never> {
        _addressError.map { $0?.localizedDescription }.eraseToAnyPublisher()
    }

    var additionalFieldType: AnyPublisher<SendDestinationAdditionalFieldType?, Never> {
        _additionalFieldType.eraseToAnyPublisher()
    }

    var addressAdditionalFieldError: AnyPublisher<String?, Never> {
        _addressAdditionalFieldError.map { $0?.localizedDescription }.eraseToAnyPublisher()
    }

    var resolvedNetworks: AnyPublisher<Set<BSDKBlockchain>, Never> {
        _resolvedNetworks.eraseToAnyPublisher()
    }

    var selectedNetworks: AnyPublisher<Set<BSDKBlockchain>, Never> {
        _selectedNetworks.eraseToAnyPublisher()
    }

    var isAddAddressEnabledPublisher: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest3(_address, _selectedNetworks, _addressError)
            .map { address, networks, error in !address.isEmpty && !networks.isEmpty && error == nil }
            .eraseToAnyPublisher()
    }

    var hasUnsavedChanges: Bool {
        output?.contactHasUnsavedChanges ?? false
    }

    func update(address: String, source: Analytics.DestinationAddressSource) {
        guard !address.isEmpty else {
            apply(address: address, networks: [], valid: false, error: nil)
            return
        }

        let networks = addressResolver.resolve(
            address: address,
            blockchains: Array(userWalletInfo.config.supportedBlockchains)
        )

        guard !networks.isEmpty else {
            apply(address: address, networks: [], valid: false, error: AddressBookAddAddressError.invalidAddress)
            return
        }

        apply(address: address, networks: networks, valid: true, error: nil)
    }

    func update(additionalField value: String) {
        guard let blockchain = _selectedNetworks.value.singleElement,
              let fieldType = _additionalFieldType.value else {
            _additionalField.send(.notSupported)
            _addressAdditionalFieldError.send(nil)
            return
        }

        guard !value.isEmpty else {
            _additionalField.send(.empty(type: fieldType))
            _addressAdditionalFieldError.send(nil)
            return
        }

        do {
            let params = try TransactionParamsBuilder(blockchain: blockchain).transactionParameters(value: value)
            _additionalField.send(.filled(type: fieldType, value: value, params: params))
            _addressAdditionalFieldError.send(nil)

        } catch TransactionParamsBuilderError.extraIdNotSupported {
            _additionalField.send(.notSupported)
            _addressAdditionalFieldError.send(nil)

        } catch {
            _additionalField.send(.notSupported)
            _addressAdditionalFieldError.send(error)
        }
    }

    func update(selectedNetworks: Set<BSDKBlockchain>) {
        _selectedNetworks.send(selectedNetworks.intersection(_resolvedNetworks.value))
        _addressError.send(duplicateAddressError(address: _address.value, networks: _selectedNetworks.value))
        applyAdditionalFieldType()
        update(additionalField: _additionalField.value.extraId ?? "")
    }

    func userDidRequestSave() {
        let memo = _additionalField.value.extraId

        let entries = _selectedNetworks.value
            .sorted { $0.networkId < $1.networkId }
            .map { blockchain in
                AddressBookEntryDraft(
                    address: _address.value,
                    blockchain: blockchain,
                    memo: memo
                )
            }

        output?.userDidAddAddress(entries: entries, replacing: replacing)
    }

    func logScreenOpened() {
        analyticsLogger.logAddressScreenOpened(walletId: userWalletInfo.id.stringValue)
    }
}

// MARK: - Private

private extension CommonAddressBookAddAddressInteractor {
    func bindAnalytics() {
        _addressError
            .map { $0 != nil }
            .removeDuplicates()
            .filter { $0 }
            .sink { [weak self] _ in
                guard let self else { return }
                analyticsLogger.logAddressInvalid(walletId: userWalletInfo.id.stringValue, contactId: contactId?.stringValue)
            }
            .store(in: &bag)
    }

    func apply(address: String, networks: Set<BSDKBlockchain>, valid: Bool, error: Error?) {
        _address.send(address)
        _resolvedNetworks.send(networks)
        _selectedNetworks.send(networks.count == 1 ? networks : [])
        _addressValid.send(valid)
        _addressError.send(error ?? duplicateAddressError(address: address, networks: _selectedNetworks.value))

        applyAdditionalFieldType()
        update(additionalField: _additionalField.value.extraId ?? "")
    }

    func applyAdditionalFieldType() {
        let additionalFieldType = _selectedNetworks.value.singleElement.flatMap {
            SendDestinationAdditionalFieldType.type(for: $0)
        }

        _additionalFieldType.send(additionalFieldType)

        if additionalFieldType == nil {
            _addressAdditionalFieldError.send(nil)
        }
    }

    func duplicateAddressError(address: String, networks: Set<BSDKBlockchain>) -> Error? {
        guard !address.isEmpty, !networks.isEmpty else {
            return nil
        }

        let networkIds = Set(networks.map(\.networkId))

        guard let conflict = reservedContacts.first(where: { contact in
            contact.entries.raw.contains { networkIds.contains($0.networkId.rawValue) && $0.address == address }
        }) else {
            return nil
        }

        return AddressBookAddAddressError.addressAlreadySaved(contactName: conflict.name.value)
    }
}

// MARK: - Error

enum AddressBookAddAddressError: LocalizedError {
    case invalidAddress
    case addressAlreadySaved(contactName: String)

    var errorDescription: String? {
        switch self {
        case .invalidAddress:
            Localization.addressBookInvalidAddressError
        case .addressAlreadySaved(let contactName):
            Localization.addressBookAddressTakenError(contactName)
        }
    }
}
