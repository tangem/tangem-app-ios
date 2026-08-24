//
//  TangemPayOrderCardDataViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLocalization

final class TangemPayOrderCardDataViewModel: ObservableObject, Identifiable {
    @Published var sections: [TangemPayOrderCardDataSection]
    @Published private(set) var isPlacingOrder = false

    private weak var coordinator: TangemPayOrderCardDataRoutable?
    private var orderTask: Task<Void, Never>?

    init(
        nameOnCard: String?,
        countryName: String?,
        email: String?,
        phoneMask: String?,
        coordinator: TangemPayOrderCardDataRoutable?
    ) {
        sections = Self.makeSections(
            nameOnCard: nameOnCard,
            countryName: countryName,
            email: email,
            phoneMask: phoneMask
        )
        self.coordinator = coordinator
    }

    func placeOrder() {
        guard !isPlacingOrder else { return }

        isPlacingOrder = true

        orderTask = runTask(in: self) { @MainActor viewModel in
            // [REDACTED_TODO_COMMENT]
            try? await Task.sleep(for: Constants.orderRequestDuration)

            guard !Task.isCancelled else { return }

            viewModel.isPlacingOrder = false
            viewModel.coordinator?.orderCardDataDidPlaceOrder()
        }
    }

    func fieldAfter(_ id: TangemPayOrderCardDataField.ID) -> TangemPayOrderCardDataField.ID? {
        let editable = sections.flatMap(\.fields).filter(\.isEditable).map(\.id)

        guard let index = editable.firstIndex(of: id), editable.indices.contains(index + 1) else {
            return nil
        }

        return editable[index + 1]
    }

    func back() {
        orderTask?.cancel()
        coordinator?.orderCardDataDidGoBack()
    }

    func close() {
        orderTask?.cancel()
        coordinator?.closeOrderCardData()
    }
}

// MARK: - Fields

private extension TangemPayOrderCardDataViewModel {
    static func makeSections(
        nameOnCard: String?,
        countryName: String?,
        email: String?,
        phoneMask: String?
    ) -> [TangemPayOrderCardDataSection] {
        [
            TangemPayOrderCardDataSection(
                id: .cardName,
                fields: [
                    TangemPayOrderCardDataField(
                        id: .nameOnCard,
                        title: Localization.tangempayOrderDataNameOnCard,
                        text: nameOnCard ?? ""
                    ),
                ]
            ),
            TangemPayOrderCardDataSection(
                id: .recipient,
                fields: recipientFields(countryName: countryName, email: email, phoneMask: phoneMask)
            ),
        ]
    }

    // [REDACTED_TODO_COMMENT]
    static func recipientFields(
        countryName: String?,
        email: String?,
        phoneMask: String?
    ) -> [TangemPayOrderCardDataField] {
        [
            TangemPayOrderCardDataField(
                id: .country,
                title: Localization.tangempayOrderDataCountry,
                text: countryName ?? "",
                isEditable: false
            ),
            TangemPayOrderCardDataField(
                id: .email,
                title: Localization.tangempayOrderDataEmail,
                text: email ?? "",
                isEditable: false
            ),
            TangemPayOrderCardDataField(
                id: .firstName,
                title: Localization.tangempayOrderDataFirstName,
                textContentType: .givenName
            ),
            TangemPayOrderCardDataField(
                id: .lastName,
                title: Localization.tangempayOrderDataLastName,
                textContentType: .familyName
            ),
            TangemPayOrderCardDataField(
                id: .region,
                title: Localization.tangempayOrderDataRegion,
                textContentType: .addressState
            ),
            TangemPayOrderCardDataField(
                id: .city,
                title: Localization.tangempayOrderDataCity,
                textContentType: .addressCity
            ),
            TangemPayOrderCardDataField(
                id: .addressLine1,
                title: Localization.tangempayOrderDataAddressLine1,
                textContentType: .streetAddressLine1
            ),
            TangemPayOrderCardDataField(
                id: .addressLine2,
                title: Localization.tangempayOrderDataAddressLine2,
                isOptional: true,
                textContentType: .streetAddressLine2
            ),
            TangemPayOrderCardDataField(
                id: .postalCode,
                title: Localization.tangempayOrderDataPostalCode,
                keyboardType: .numbersAndPunctuation,
                textContentType: .postalCode
            ),
            TangemPayOrderCardDataField(
                id: .phone,
                title: Localization.tangempayOrderDataPhone,
                keyboardType: .phonePad,
                textContentType: .telephoneNumber,
                mask: phoneMask
            ),
        ]
    }
}

// MARK: - Constants

private extension TangemPayOrderCardDataViewModel {
    enum Constants {
        static let orderRequestDuration: Duration = .seconds(2)
    }
}
