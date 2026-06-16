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
    func userDidAddAddress(entries: [AddressBookEntryDraft])
}

protocol AddressBookAddAddressInteractor {
    var addressValid: AnyPublisher<Bool, Never> { get }
    var addressError: AnyPublisher<String?, Never> { get }
    var additionalFieldType: AnyPublisher<SendDestinationAdditionalFieldType?, Never> { get }
    var addressAdditionalFieldError: AnyPublisher<String?, Never> { get }
    var resolvedNetworks: AnyPublisher<Set<BSDKBlockchain>, Never> { get }

    func update(address: String, source: Analytics.DestinationAddressSource) async
    func update(additionalField: String)

    func userDidRequestSave()
}

final class CommonAddressBookAddAddressInteractor {
    private let userWalletInfo: UserWalletInfo
    private weak var output: AddressBookAddAddressOutput?

    private let addressResolver = AddressBlockchainResolver()

    private let _address = CurrentValueSubject<String, Never>("")
    private let _additionalField = CurrentValueSubject<SendDestinationAdditionalField, Never>(.notSupported)

    private let _addressValid = CurrentValueSubject<Bool, Never>(false)
    private let _addressError = CurrentValueSubject<Error?, Never>(nil)
    private let _additionalFieldType = CurrentValueSubject<SendDestinationAdditionalFieldType?, Never>(.none)
    private let _addressAdditionalFieldError = CurrentValueSubject<Error?, Never>(nil)
    private let _resolvedNetworks = CurrentValueSubject<Set<BSDKBlockchain>, Never>([])

    init(userWalletInfo: UserWalletInfo, output: AddressBookAddAddressOutput) {
        self.userWalletInfo = userWalletInfo
        self.output = output
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

    func update(address: String, source: Analytics.DestinationAddressSource) async {
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
        guard let blockchain = _resolvedNetworks.value.singleElement,
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

    func userDidRequestSave() {
        // One AddressEntry per resolved network — the same address can be saved across several chains
        // (e.g. an EVM address on Ethereum + Polygon). Until the network selector lands ([REDACTED_INFO]),
        // every resolved network is treated as selected.
        let memo = _additionalField.value.extraId

        let entries = _resolvedNetworks.value
            .sorted { $0.networkId < $1.networkId }
            .map { blockchain in
                AddressBookEntryDraft(
                    address: _address.value,
                    networkId: AddressBookNetworkID(blockchain.networkId),
                    memo: memo
                )
            }

        output?.userDidAddAddress(entries: entries)
    }
}

// MARK: - Private

private extension CommonAddressBookAddAddressInteractor {
    func apply(address: String, networks: Set<BSDKBlockchain>, valid: Bool, error: Error?) {
        _address.send(address)
        _resolvedNetworks.send(networks)
        _addressValid.send(valid)
        _addressError.send(error)

        let additionalFieldType = networks.singleElement.flatMap {
            SendDestinationAdditionalFieldType.type(for: $0)
        }

        _additionalFieldType.send(additionalFieldType)

        if additionalFieldType == nil {
            _addressAdditionalFieldError.send(nil)
        }
    }
}

// MARK: - Error

enum AddressBookAddAddressError: LocalizedError {
    case invalidAddress

    var errorDescription: String? {
        switch self {
        case .invalidAddress: Localization.addressBookInvalidAddressError
        }
    }
}
