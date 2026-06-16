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

    private let interactor: AddressBookAddAddressInteractor
    private weak var coordinator: AddressBookAddAddressRoutable?

    private var updatingTask: Task<Void, Never>?
    private var bag: Set<AnyCancellable> = []

    init(
        interactor: AddressBookAddAddressInteractor,
        coordinator: AddressBookAddAddressRoutable
    ) {
        self.interactor = interactor
        self.coordinator = coordinator

        destinationAddressViewModel = SendDestinationAddressViewModel(
            textViewModel: .init(),
            address: .init(string: "", source: .textField)
        )

        destinationAddressViewModel.router = self

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
            .receive(on: DispatchQueue.main)
            .sink { $0.addressDidChanged(destination: $1) }
            .store(in: &bag)

        interactor.addressError
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { $0.destinationAddressViewModel.update(error: $1) }
            .store(in: &bag)

        interactor.additionalFieldType
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .map { $0.mapToAdditionalFieldViewModel(type: $1) }
            .assign(to: &$additionalFieldViewModel)

        interactor.addressAdditionalFieldError
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { $0.additionalFieldViewModel?.update(error: $1) }
            .store(in: &bag)

        interactor.resolvedNetworks
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .map { $0.mapToAddressNetworksType(networks: $1) }
            .assign(to: &$addressNetworksType)
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

        let viewModel = SendDestinationAdditionalFieldViewModel(title: type.name)

        viewModel.textPublisher()
            .dropFirst()
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { $0.interactor.update(additionalField: $1) }
            .store(in: &bag)

        return viewModel
    }

    func addressDidChanged(destination: SendDestinationAddressViewModel.Address) {
        let newUpdatingTask = runTask(in: self) { viewModel in
            await viewModel.interactor.update(address: destination.string, source: destination.source)
        }

        updatingTask?.cancel()
        updatingTask = newUpdatingTask
    }
}

// MARK: - SendDestinationAddressViewRoutable

extension AddressBookAddAddressViewModel: SendDestinationAddressViewRoutable {
    func didTapScanQRButton() {
        coordinator?.openQRScanner(output: self)
    }
}

// MARK: - QRScannerOutput

extension AddressBookAddAddressViewModel: QRScannerOutput {
    func qrScanDidScan(string: String) {
        destinationAddressViewModel.update(address: .init(string: string, source: .qrCode))
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
