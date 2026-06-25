//
//  AddressBookAddAddressViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemLocalization

final class AddressBookAddAddressViewModel: ObservableObject, Identifiable {
    @Published private(set) var destinationAddressViewModel: SendDestinationAddressViewModel
    @Published private(set) var additionalFieldViewModel: SendDestinationAdditionalFieldViewModel?

    @Published private(set) var addressNetworksType: AddressNetworksType = .idle
    @Published private(set) var isAddAddressEnabled: Bool = false

    private let interactor: AddressBookAddAddressInteractor
    private weak var coordinator: AddressBookAddAddressRoutable?

    private var prefilledMemo: String?

    private var bag: Set<AnyCancellable> = []

    init(
        interactor: AddressBookAddAddressInteractor,
        coordinator: AddressBookAddAddressRoutable,
        options: AddressBookAddAddressOptions
    ) {
        self.interactor = interactor
        self.coordinator = coordinator

        destinationAddressViewModel = SendDestinationAddressViewModel(
            textViewModel: .init(),
            address: .init(string: "", source: .textField)
        )

        destinationAddressViewModel.router = self

        if case .edit(let address, let memo, _) = options {
            prefilledMemo = memo
            destinationAddressViewModel.update(address: .init(string: address, source: .textField))
        }

        bind()
    }

    func userDidRequestDismiss() {
        coordinator?.dismissAddAddress()
    }

    func userDidRequestNetworksChange() {
        // [REDACTED_TODO_COMMENT]
    }

    func userDidRequestAddAddress() {
        interactor.userDidRequestSave()
        coordinator?.dismissAddAddress()
    }
}

// MARK: - Private

private extension AddressBookAddAddressViewModel {
    func bind() {
        destinationAddressViewModel
            .addressPublisher()
            .dropFirst()
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { $0.addressDidChanged(destination: $1) }
            .store(in: &bag)

        interactor.addressError
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { $0.destinationAddressViewModel.update(error: $1) }
            .store(in: &bag)

        interactor.additionalFieldType
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .map { $0.mapToAdditionalFieldViewModel(type: $1) }
            .assign(to: &$additionalFieldViewModel)

        interactor.addressAdditionalFieldError
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { $0.additionalFieldViewModel?.update(error: $1) }
            .store(in: &bag)

        interactor.resolvedNetworks
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .map { $0.mapToAddressNetworksType(networks: $1) }
            .assign(to: &$addressNetworksType)

        interactor.isAddAddressEnabledPublisher
            .removeDuplicates()
            .receiveOnMain()
            .assign(to: &$isAddAddressEnabled)
    }

    func mapToAddressNetworksType(networks: Set<BSDKBlockchain>) -> AddressNetworksType {
        guard !networks.isEmpty else {
            return .idle
        }

        return .resolved(networks: networks)
    }

    func mapToAdditionalFieldViewModel(type: SendDestinationAdditionalFieldType?) -> SendDestinationAdditionalFieldViewModel? {
        guard let type else {
            return nil
        }

        let viewModel = SendDestinationAdditionalFieldViewModel(title: type.name, text: prefilledMemo ?? "")
        prefilledMemo = nil

        viewModel.textPublisher()
            .dropFirst()
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { $0.interactor.update(additionalField: $1) }
            .store(in: &bag)

        return viewModel
    }

    func addressDidChanged(destination: SendDestinationAddressViewModel.Address) {
        interactor.update(address: destination.string, source: destination.source)
    }
}

// MARK: - SendDestinationAddressViewRoutable

extension AddressBookAddAddressViewModel: SendDestinationAddressViewRoutable {
    func didTapScanQRButton() {
        coordinator?.openQRScanner { [weak self] code in
            self?.applyScannedAddress(code)
        }
    }
}

// MARK: - QR scan result

extension AddressBookAddAddressViewModel {
    func applyScannedAddress(_ string: String) {
        // A scanned QR may be a payment URI (e.g. `bitcoin:bc1q…?amount=…`, `ethereum:0x…@1`);
        // extract the bare address so it resolves to a network.
        let address = MainQRBlockchainURIParser().parse(string)?.destinationAddress ?? string
        destinationAddressViewModel.update(address: .init(string: address, source: .qrCode))
    }
}

// MARK: - Types

extension AddressBookAddAddressViewModel {
    enum AddressNetworksType: Identifiable {
        case idle
        case resolved(networks: Set<BSDKBlockchain>)

        var id: String {
            switch self {
            case .idle: "idle"
            case .resolved(let resolved): resolved.hashValue.description
            }
        }

        var isEditable: Bool {
            switch self {
            case .idle: false
            case .resolved(let networks): networks.count > 1
            }
        }
    }
}
