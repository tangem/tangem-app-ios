//
//  SendNewDestinationCompactViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import UIKit

class SendNewDestinationCompactViewModel: ObservableObject, Identifiable {
    typealias AdditionalField = (SendDestinationAdditionalFieldType, String)

    let suiTextViewModel: SUITextViewModel
    @Published var address: String = ""
    @Published var additionalField: String?

    private var inputSubscription: AnyCancellable?

    init(input: SendDestinationInput) {
        suiTextViewModel = .init()

        bind(input: input)
    }

    func bind(input: SendDestinationInput) {
        inputSubscription = Publishers
            .CombineLatest(input.destinationPublisher, input.additionalFieldPublisher)
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { viewModel, args in
                viewModel.updateView(address: args.0?.value ?? "", additionalField: args.1)
            }
    }

    private func updateView(address: String, additionalField: SendDestinationAdditionalField) {
        self.address = address

        switch additionalField {
        case .filled(let type, let value, _):
            self.additionalField = "\(type.name): \(value)"
        default:
            self.additionalField = nil
        }
    }
}
