//
//  SendDestinationCompactViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import UIKit

class SendDestinationCompactViewModel: ObservableObject, Identifiable {
    typealias AdditionalField = (SendDestinationAdditionalFieldType, String)

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    let suiTextViewModel: SUITextViewModel
    @Published var address: String = ""
    @Published var resolved: String?
    @Published var additionalField: String?
    @Published var addressIconType: AddressIconProviderViewType?

    private var inputSubscription: AnyCancellable?

    init(input: SendDestinationInput) {
        suiTextViewModel = .init()

        bind(input: input)
    }

    func bind(input: SendDestinationInput) {
        inputSubscription = Publishers
            .CombineLatest3(input.destinationPublisher, input.additionalFieldPublisher, addressBooksChangePublisher)
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { viewModel, args in
                viewModel.updateView(address: args.0, additionalField: args.1)
            }
    }

    private var addressBooksChangePublisher: AnyPublisher<Void, Never> {
        guard FeatureProvider.isAvailable(.addressBook) else {
            return .just(output: ())
        }

        let publishers = userWalletRepository.models
            .filter { !$0.isUserWalletLocked }
            .map { $0.addressBookManager.contactsPublisher.mapToVoid() }

        return Publishers.MergeMany(publishers)
            .prepend(())
            .eraseToAnyPublisher()
    }

    private func updateView(address: SendDestination?, additionalField: SendDestinationAdditionalField) {
        self.address = address?.value.typedAddress ?? ""
        addressIconType = AddressIconProvider.makeViewType(address: self.address)
        resolved = address?.value.showableResolved

        switch additionalField {
        case .filled(let type, let value, _):
            self.additionalField = "\(type.name): \(value)"
        default:
            self.additionalField = nil
        }
    }
}
