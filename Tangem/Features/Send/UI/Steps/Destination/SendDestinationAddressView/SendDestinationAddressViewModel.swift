//
//  SendDestinationAddressViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemLocalization

protocol SendDestinationAddressViewRoutable: AnyObject {
    func didTapScanQRButton()
}

class SendDestinationAddressViewModel: ObservableObject, Identifiable {
    let title: String

    @Published private(set) var textViewModel: SUITextViewModel
    @Published private(set) var address: Address
    @Published private(set) var error: String?
    @Published private(set) var isValidating: Bool = false
    @Published private(set) var addressIconType: AddressIconProviderViewType?

    private let iconStyle: IconStyle
    private var shouldIgnoreClearButton: Bool = false

    var text: BindingValue<String> {
        .init(
            root: self, default: "",
            get: { $0.address.string },
            set: { $0.address = .init(string: $1.trimmed(), source: .textField) }
        )
    }

    weak var router: SendDestinationAddressViewRoutable?

    init(textViewModel: SUITextViewModel, address: Address, title: String = Localization.sendRecipient, iconStyle: IconStyle = .automatic) {
        self.textViewModel = textViewModel
        self.address = address
        self.title = title
        self.iconStyle = iconStyle
        addressIconType = Self.makeIcon(for: address.string, style: iconStyle)

        bind()
    }

    private func bind() {
        // `addressIconType` is seeded in `init`; react only to subsequent address changes.
        addressPublisher()
            .dropFirst()
            .receiveOnMain()
            .map { [iconStyle] in Self.makeIcon(for: $0.string, style: iconStyle) }
            .assign(to: &$addressIconType)
    }

    func addressPublisher() -> AnyPublisher<Address, Never> {
        $address.eraseToAnyPublisher()
    }

    private static func makeIcon(for address: String, style: IconStyle) -> AddressIconProviderViewType? {
        switch style {
        case .automatic: AddressIconProvider.makeViewType(address: address)
        case .blockies: .blockies(AddressIconProvider.makeBlockiesIconViewData(address: address))
        }
    }

    enum IconStyle {
        case automatic
        case blockies
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
