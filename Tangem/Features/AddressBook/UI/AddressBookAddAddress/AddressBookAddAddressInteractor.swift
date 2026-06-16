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

protocol AddressBookAddAddressInteractor {
    var addressValid: AnyPublisher<Bool, Never> { get }
    var addressError: AnyPublisher<String?, Never> { get }
    var additionalFieldType: AnyPublisher<SendDestinationAdditionalFieldType?, Never> { get }
    var addressAdditionalFieldError: AnyPublisher<String?, Never> { get }
    var resolvedNetworks: AnyPublisher<Set<BSDKBlockchain>, Never> { get }

    func update(address: String, source: Analytics.DestinationAddressSource) async
    func update(additionalField: String)
}

final class CommonAddressBookAddAddressInteractor {
    private let userWalletInfo: UserWalletInfo
    private let addressResolver = AddressBlockchainResolver()

    private let _addressValid = CurrentValueSubject<Bool, Never>(false)
    private let _addressError = CurrentValueSubject<Error?, Never>(nil)
    private let _additionalFieldType = CurrentValueSubject<SendDestinationAdditionalFieldType?, Never>(.none)
    private let _addressAdditionalFieldError = CurrentValueSubject<Error?, Never>(nil)
    private let _resolvedNetworks = CurrentValueSubject<Set<BSDKBlockchain>, Never>([])

    init(userWalletInfo: UserWalletInfo) {
        self.userWalletInfo = userWalletInfo
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
        guard !address.trimmed().isEmpty else {
            apply(networks: [], valid: false, error: nil)
            return
        }

        let networks = addressResolver.resolve(
            address: address,
            blockchains: Array(userWalletInfo.config.supportedBlockchains)
        )

        guard !networks.isEmpty else {
            apply(networks: [], valid: false, error: AddressBookAddAddressError.invalidAddress)
            return
        }

        apply(networks: networks, valid: true, error: nil)
    }

    func update(additionalField value: String) {
        guard let blockchain = _resolvedNetworks.value.singleElement, _additionalFieldType.value != nil else {
            _addressAdditionalFieldError.send(nil)
            return
        }

        guard !value.isEmpty else {
            _addressAdditionalFieldError.send(nil)
            return
        }

        do {
            _ = try TransactionParamsBuilder(blockchain: blockchain).transactionParameters(value: value)
            _addressAdditionalFieldError.send(nil)
        } catch TransactionParamsBuilderError.extraIdNotSupported {
            _addressAdditionalFieldError.send(nil)
        } catch {
            _addressAdditionalFieldError.send(error)
        }
    }
}

// MARK: - Private

private extension CommonAddressBookAddAddressInteractor {
    func apply(networks: Set<BSDKBlockchain>, valid: Bool, error: Error?) {
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
