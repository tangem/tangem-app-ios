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

        if case .edit(let address, let memo, _, _) = options {
            prefilledMemo = memo
            destinationAddressViewModel.update(address: .init(string: address, source: .textField))
        }

        bind()
    }

    func userDidRequestDismiss() {
        coordinator?.dismissAddAddress()
    }

    func userDidRequestNetworksChange() {
        guard case .resolved(let resolved, let selected) = addressNetworksType, let coordinator else {
            return
        }

        let viewModel = ChooseNetworkViewModel(
            candidates: resolved,
            preselected: selected,
            output: self,
            routable: coordinator
        )
        coordinator.presentChooseNetwork(viewModel)
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

        Publishers.CombineLatest(interactor.resolvedNetworks, interactor.selectedNetworks)
            .removeDuplicates { $0 == $1 }
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .map { $0.mapToAddressNetworksType(resolved: $1.0, selected: $1.1) }
            .assign(to: &$addressNetworksType)

        interactor.isAddAddressEnabledPublisher
            .removeDuplicates()
            .receiveOnMain()
            .assign(to: &$isAddAddressEnabled)
    }

    func mapToAddressNetworksType(resolved: Set<BSDKBlockchain>, selected: Set<BSDKBlockchain>) -> AddressNetworksType {
        guard !resolved.isEmpty else {
            return .idle
        }

        return .resolved(resolved: resolved, selected: selected)
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

// MARK: - ChooseNetworkOutput

extension AddressBookAddAddressViewModel: ChooseNetworkOutput {
    func chooseNetworkDidConfirm(_ selected: Set<BSDKBlockchain>) {
        interactor.update(selectedNetworks: selected)
    }
}

// MARK: - Types

extension AddressBookAddAddressViewModel {
    enum AddressNetworksType: Identifiable {
        case idle
        case resolved(resolved: Set<BSDKBlockchain>, selected: Set<BSDKBlockchain>)

        var id: String {
            switch self {
            case .idle: "idle"
            case .resolved: "resolved"
            }
        }

        var isEditable: Bool {
            switch self {
            case .idle: false
            case .resolved(let resolved, _): resolved.count > 1
            }
        }
    }
}
