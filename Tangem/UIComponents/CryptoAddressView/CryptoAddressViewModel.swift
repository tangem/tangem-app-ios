//
//  CryptoAddressViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemLocalization

class CryptoAddressViewModel: ObservableObject, Identifiable {
    @Published private(set) var destinationAddressSection: [DestinationAddressSectionType]
    @Published private(set) var additionalFieldViewModel: SendDestinationAdditionalFieldViewModel?

    private let destinationAddressViewModel: SendDestinationAddressViewModel
    private let addressProcessor: CryptoAddressProcessor
    private let additionalFieldProcessor: CryptoAddressAdditionalFieldProcessor

    private var resolvingTask: Task<Void, Error>?
    private var bag: Set<AnyCancellable> = []

    init(
        addressProcessor: CryptoAddressProcessor,
        additionalFieldProcessor: CryptoAddressAdditionalFieldProcessor,
        addressViewRoutable: SendDestinationAddressViewRoutable
    ) {
        self.addressProcessor = addressProcessor
        self.additionalFieldProcessor = additionalFieldProcessor

        destinationAddressViewModel = SendDestinationAddressViewModel(
            textViewModel: .init(),
            address: .init(string: "", source: .textField)
        )
        destinationAddressViewModel.router = addressViewRoutable

        destinationAddressSection = [.destinationAddress(destinationAddressViewModel)]
        bind()
    }
}

// MARK: - Private

private extension CryptoAddressViewModel {
    func bind() {
        addressProcessor
            .cryptoAddressViewStatePublisher
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { $0.render(state: $1) }
            .store(in: &bag)

        destinationAddressViewModel
            .addressPublisher()
            .dropFirst()
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { $0.addressDidChanged(destination: $1) }
            .store(in: &bag)

        additionalFieldProcessor
            .additionalFieldTypePublisher
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .map { $0.makeAdditionalFieldViewModel(additionalFieldType: $1) }
            .assign(to: &$additionalFieldViewModel)
    }

    @discardableResult
    private func addressDidChanged(destination: SendDestinationAddressViewModel.Address) -> Task<Void, Error> {
        destinationAddressViewModel.update(error: .none)

        let shouldDebounce = !destination.string.isEmpty && addressProcessor.willResolving(address: destination.string)

        let task = runWithDelayedLoading(onLongRunning: { [weak self] in
            self?.destinationAddressViewModel.update(isValidating: true)
        }, operation: { [weak self] in
            guard let self else { return }

            if shouldDebounce {
                try await Task.sleep(for: .seconds(1))
            }

            // Resolution publishes its result through `cryptoAddressViewStatePublisher`; await it only to toggle the spinner.
            await addressProcessor.update(destination: destination.string, source: destination.source).value
            await runOnMain { self.destinationAddressViewModel.update(isValidating: false) }
        })

        resolvingTask?.cancel()
        resolvingTask = task

        return task
    }

    private func additionalFieldDidChanged(value: String) {
        additionalFieldViewModel?.update(error: .none)

        do {
            let additionalField = try additionalFieldProcessor.makeAdditionalField(value: value)
            addressProcessor.update(additionalField: additionalField)
        } catch {
            // Malformed memo: surface the parse error on the field; don't commit it to the processor.
            additionalFieldViewModel?.update(error: error.localizedDescription)
        }
    }

    func render(state: CryptoAddressViewState) {
        switch state {
        case .empty:
            destinationAddressViewModel.update(error: nil)
            destinationAddressSection = makeDestinationAddressSection(resolvedAddress: nil)
            additionalFieldViewModel?.update(error: nil)
            additionalFieldViewModel?.update(disabled: false)

        case .invalidAddress(let message):
            destinationAddressViewModel.update(error: message)
            destinationAddressSection = makeDestinationAddressSection(resolvedAddress: nil)

        case .valid(let context):
            destinationAddressViewModel.update(error: nil)
            destinationAddressSection = makeDestinationAddressSection(resolvedAddress: context.destination.address.showableResolved)

            if !context.canEmbedAdditionalField, additionalFieldViewModel?.text.isEmpty == false {
                additionalFieldViewModel?.update(text: "")
            }

            additionalFieldViewModel?.update(error: nil)
            additionalFieldViewModel?.update(disabled: !context.canEmbedAdditionalField)

        case .additionalFieldRequired(let context):
            destinationAddressViewModel.update(error: nil)
            destinationAddressSection = makeDestinationAddressSection(resolvedAddress: context.destination.address.showableResolved)
            additionalFieldViewModel?.update(disabled: !context.canEmbedAdditionalField)
            additionalFieldViewModel?.update(error: Localization.sendValidationDestinationTagRequiredDescription)
        }
    }

    func makeDestinationAddressSection(resolvedAddress: String?) -> [DestinationAddressSectionType] {
        var section: [DestinationAddressSectionType] = [.destinationAddress(destinationAddressViewModel)]
        if let resolvedAddress {
            section.append(.destinationResolvedAddress(resolvedAddress))
        }
        return section
    }

    func makeAdditionalFieldViewModel(additionalFieldType: SendDestinationAdditionalFieldType?) -> SendDestinationAdditionalFieldViewModel? {
        guard let additionalFieldType else {
            return nil
        }

        let viewModel = SendDestinationAdditionalFieldViewModel(title: additionalFieldType.name)

        viewModel
            .textPublisher()
            .dropFirst()
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { $0.additionalFieldDidChanged(value: $1) }
            .store(in: &bag)

        return viewModel
    }
}

extension CryptoAddressViewModel {
    enum DestinationAddressSectionType: Identifiable {
        case destinationAddress(SendDestinationAddressViewModel)
        case destinationResolvedAddress(String)

        var id: String {
            switch self {
            case .destinationAddress(let viewModel): String(describing: viewModel.id)
            case .destinationResolvedAddress(let address): address
            }
        }
    }
}
