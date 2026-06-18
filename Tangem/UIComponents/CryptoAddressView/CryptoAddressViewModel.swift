//
//  CryptoAddressViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

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
        let hasValue = !destination.string.isEmpty
        let shouldResolve = addressProcessor.willResolving(address: destination.string)
        let shouldDebounce = hasValue && shouldResolve

        let newUpdatingTask = runWithDelayedLoading(onLongRunning: { [weak self] in
            await MainActor.run { [weak self] in
                self?.destinationAddressViewModel.update(isValidating: true)
            }
        }, operation: { [weak self] in
            if shouldDebounce {
                try await Task.sleep(for: .seconds(1))
            }

            await self?.update(destination: destination)
            await MainActor.run { [weak self] in
                self?.destinationAddressViewModel.update(isValidating: false)
            }
        })

        resolvingTask?.cancel()
        resolvingTask = newUpdatingTask

        return newUpdatingTask
    }

    private func additionalFieldDidChanged(additionalField: String) {
        do {
            let additionalField = try additionalFieldProcessor.makeAdditionalField(value: additionalField)
            try addressProcessor.update(additionalField: additionalField)
        } catch {
            additionalFieldViewModel?.update(error: error.localizedDescription)
        }
    }

    func update(destination: SendDestinationAddressViewModel.Address) async {
        do {
            let parameters = try await addressProcessor.update(destination: destination.string, source: destination.source)
            await setupView(addressParameters: parameters)
        } catch {
            destinationAddressViewModel.update(error: error.localizedDescription)
        }
    }

    @MainActor
    func setupView(addressParameters: CryptoAddressParameters) {
        destinationAddressSection = makeDestinationAddressSection(addressParameters: addressParameters)

        if !addressParameters.canEmbedAdditionalField {
            additionalFieldViewModel?.update(text: "")
        }

        additionalFieldViewModel?.update(disabled: !addressParameters.canEmbedAdditionalField)
    }

    func makeDestinationAddressSection(addressParameters: CryptoAddressParameters) -> [DestinationAddressSectionType] {
        var section: [DestinationAddressSectionType] = [.destinationAddress(destinationAddressViewModel)]
        if let destinationResolvedAddress = addressParameters.resolvedAddress {
            section.append(.destinationResolvedAddress(destinationResolvedAddress))
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
            .sink { $0.additionalFieldDidChanged(additionalField: $1) }
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
