//
//  AddressBookAddAddressViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Combine
import Foundation
import TangemFoundation
import TangemLocalization
import TangemUI
import TangemUIUtils

final class AddressBookAddAddressViewModel: ObservableObject, Identifiable {
    @Published private(set) var destinationAddressViewModel: SendDestinationAddressViewModel
    @Published private(set) var additionalFieldViewModel: SendDestinationAdditionalFieldViewModel?

    @Published private(set) var addressNetworksType: AddressNetworksType = .idle
    @Published private(set) var isAddAddressEnabled: Bool = false

    @Published var alert: AlertBinder?

    let screenTitle: String

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

        switch options {
        case .add:
            screenTitle = Localization.addressBookAddAddress
        case .edit:
            screenTitle = Localization.addressBookEditAddress
        }

        destinationAddressViewModel = SendDestinationAddressViewModel(
            textViewModel: .init(),
            address: .init(string: "", source: .textField),
            title: Localization.commonAddress,
            iconStyle: .blockies
        )

        destinationAddressViewModel.router = self

        if case .edit(let address, let memo, _, _) = options {
            prefilledMemo = memo
            destinationAddressViewModel.update(address: .init(string: address, source: .textField))
        }

        bind()
    }

    func onFirstAppear() {
        interactor.logScreenOpened()
    }

    func userDidRequestDismiss() {
        guard interactor.hasUnsavedChanges else {
            coordinator?.dismissAddAddressFlow()
            return
        }

        alert = AlertBuilder.makeExitAlert(
            title: Localization.addressBookUnsavedChanges,
            message: Localization.addressBookUnsavedChangesDescription,
            keepEditingButtonText: Localization.addressBookKeepEditing,
            discardButtonText: Localization.addressBookDiscard,
            discardAction: { [weak self] in
                self?.coordinator?.dismissAddAddressFlow()
            }
        )
    }

    func userDidRequestNetworksChange() {
        guard case .resolved(let value) = addressNetworksType, let coordinator else {
            return
        }

        let viewModel = ChooseNetworkViewModel(
            candidates: value.resolved,
            preselected: value.selected,
            output: self,
            routable: coordinator
        )
        coordinator.presentChooseNetwork(viewModel)
    }

    func userDidRequestSaveAddress() {
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

        let sortedSelected = selected.sorted { $0.networkId < $1.networkId }
        let icons = sortedSelected.map { NetworkIconItem.image(NetworkImageProvider().provide(by: $0, filled: true)) }
        let name = sortedSelected.count == 1 ? sortedSelected.first?.displayName : nil

        return .resolved(.init(resolved: resolved, selected: selected, icons: icons, name: name))
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

    func chooseNetworkDidTapSelectAll(didSelectAll: Bool) {
        interactor.logSelectAllTapped(didSelectAll: didSelectAll)
    }
}

// MARK: - Types

extension AddressBookAddAddressViewModel {
    enum AddressNetworksType: Identifiable {
        case idle
        case resolved(Resolved)

        struct Resolved {
            let resolved: Set<BSDKBlockchain>
            let selected: Set<BSDKBlockchain>
            let icons: [NetworkIconItem]
            let name: String?

            var isEditable: Bool { resolved.count > 1 }
        }

        var id: String {
            switch self {
            case .idle: "idle"
            case .resolved: "resolved"
            }
        }

        var isEditable: Bool {
            switch self {
            case .idle: false
            case .resolved(let resolved): resolved.isEditable
            }
        }
    }
}
