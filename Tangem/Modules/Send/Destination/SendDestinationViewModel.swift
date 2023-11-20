//
//  SendDestinationViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

protocol SendDestinationViewModelInput {
    var destinationTextBinding: Binding<String> { get }
    var destinationAdditionalFieldTextBinding: Binding<String> { get }

    var destinationError: AnyPublisher<Error?, Never> { get }
    var destinationAdditionalFieldError: AnyPublisher<Error?, Never> { get }

    var networkName: String { get }

    var additionalField: SendAdditionalFields? { get }

    var suggestedWallets: [SendSuggestedDestinationWallet] { get }
    var recentTransactions: AnyPublisher<[SendSuggestedDestinationTransactionRecord], Never> { get }
}

protocol SendDestinationViewDelegate: AnyObject {
    func didSelectAddress(_ address: String)
    func didSelectAdditionalField(_ additionalField: String)
    func didSelectDestination(_ destination: SendSuggestedDestination)
}

class SendDestinationViewModel: ObservableObject {
    var destination: Binding<String>
    var additionalField: Binding<String>

    var addressViewModel: SendDestinationInputViewModel?
    var additionalFieldViewModel: SendDestinationInputViewModel?
    var suggestedDestinationViewModel: SendSuggestedDestinationViewModel?

    @Published var destinationErrorText: String?
    @Published var destinationAdditionalFieldErrorText: String?

    weak var delegate: SendDestinationViewDelegate?

    private var bag: Set<AnyCancellable> = []

    init(input: SendDestinationViewModelInput) {
        destination = input.destinationTextBinding
        additionalField = input.destinationAdditionalFieldTextBinding

        addressViewModel = SendDestinationInputViewModel(
            name: Localization.sendRecipient,
            input: input.destinationTextBinding,
            showAddressIcon: true,
            placeholder: Localization.sendEnterAddressField,
            description: Localization.sendRecipientAddressFooter(input.networkName),
            didPasteAddress: { [weak self] strings in
                guard let address = strings.first else { return }
                self?.delegate?.didSelectAddress(address)
            }
        )

        if let additionalField = input.additionalField,
           let name = additionalField.name {
            additionalFieldViewModel = SendDestinationInputViewModel(
                name: name,
                input: input.destinationAdditionalFieldTextBinding,
                showAddressIcon: false,
                placeholder: Localization.sendOptionalField,
                description: Localization.sendRecipientMemoFooter,
                didPasteAddress: { [weak self] strings in
                    guard let additionalField = strings.first else { return }
                    self?.delegate?.didSelectAdditionalField(additionalField)
                }
            )
        }

        bind(from: input)
    }

    private func bind(from input: SendDestinationViewModelInput) {
        input
            .destinationError
            .map {
                $0?.localizedDescription
            }
            .assign(to: \.destinationErrorText, on: self, ownership: .weak)
            .store(in: &bag)

        input
            .destinationAdditionalFieldError
            .map {
                $0?.localizedDescription
            }
            .assign(to: \.destinationAdditionalFieldErrorText, on: self, ownership: .weak)
            .store(in: &bag)

        input
            .recentTransactions
            .sink { [weak self] recentTransactions in
                if input.suggestedWallets.isEmpty, recentTransactions.isEmpty {
                    self?.suggestedDestinationViewModel = nil
                    return
                }

                self?.suggestedDestinationViewModel = SendSuggestedDestinationViewModel(
                    wallets: input.suggestedWallets,
                    recentTransactions: recentTransactions
                ) { [weak self] destination in
                    self?.delegate?.didSelectDestination(destination)
                }
            }
            .store(in: &bag)
    }
}

extension SendAdditionalFields {
    var name: String? {
        switch self {
        case .memo:
            return Localization.sendExtrasHintMemo
        case .destinationTag:
            return Localization.sendDestinationTagField
        case .none:
            return nil
        }
    }
}
