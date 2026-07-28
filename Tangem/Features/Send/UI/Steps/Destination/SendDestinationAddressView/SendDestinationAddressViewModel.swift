//
//  SendDestinationAddressViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

protocol SendDestinationAddressViewRoutable: AnyObject {
    func didTapScanQRButton()
}

final class SendDestinationAddressViewModel: ObservableObject, Identifiable {
    @Published private(set) var textViewModel: SUITextViewModel
    @Published private(set) var addressIconViewModel: AddressIconViewModel
    @Published private(set) var error: String?
    @Published private(set) var isValidating: Bool = false
    @Published private(set) var address: Address {
        didSet { updateAddressIconViewModel(oldAddress: oldValue, newAddress: address) }
    }

    private var shouldIgnoreClearButton: Bool = false

    var text: BindingValue<String> {
        .init(
            root: self, default: "",
            get: { $0.address.string },
            set: { $0.address = .init(string: $1.trimmed(), source: .textField) }
        )
    }

    weak var router: SendDestinationAddressViewRoutable?

    init(textViewModel: SUITextViewModel, address: Address) {
        self.textViewModel = textViewModel
        self.address = address
        addressIconViewModel = AddressIconViewModel(address: address.string)
    }

    func addressPublisher() -> AnyPublisher<Address, Never> {
        $address.eraseToAnyPublisher()
    }

    func update(error: String?) {
        self.error = error
    }

    func update(address: Address) {
        self.address = address
    }

    func update(isValidating: Bool) {
        self.isValidating = isValidating
    }

    func update(shouldIgnoreClearButton: Bool) {
        self.shouldIgnoreClearButton = shouldIgnoreClearButton
    }

    func didTapPasteButton(string: String) {
        FeedbackGenerator.heavy()
        address = .init(string: string.trimmed(), source: .pasteButton)
    }

    func didTapClearButton() {
        guard !shouldIgnoreClearButton else { return }

        address = .init(string: "", source: .textField)
    }

    func didTapScanQRButton() {
        router?.didTapScanQRButton()
    }

    private func updateAddressIconViewModel(oldAddress: Address, newAddress: Address) {
        guard newAddress.string != oldAddress.string else {
            return
        }

        addressIconViewModel = AddressIconViewModel(address: newAddress.string)
    }
}

extension SendDestinationAddressViewModel {
    enum TitleType {
        case title
        case error(String)
    }

    struct Address {
        let string: String
        let source: Analytics.DestinationAddressSource
    }
}
