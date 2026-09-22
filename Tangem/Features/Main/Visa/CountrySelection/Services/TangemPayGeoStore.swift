//
//  TangemPayGeoStore.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemPay
import TangemVisa

final class TangemPayGeoStore {
    typealias CountriesState = LoadingResult<[TangemPayGeoCountry], any Error>
    typealias RegionsState = LoadingResult<[TangemPayGeoRegion], any Error>

    var countriesPublisher: some Publisher<CountriesState, Never> {
        countriesSubject
    }

    private let repository: any TangemPayGeoRepository

    private let countriesSubject = CurrentValueSubject<CountriesState, Never>(.loading)
    private let regionsSubject = CurrentValueSubject<[String: RegionsState], Never>([:])

    private var countriesTask: Task<Void, Never>?
    private var regionsTasks: [String: Task<Void, Never>] = [:]

    init(repository: any TangemPayGeoRepository) {
        self.repository = repository
    }

    func regionsPublisher(countryCode: String) -> some Publisher<RegionsState, Never> {
        regionsSubject.map { $0[countryCode] ?? .loading }
    }

    func loadCountries() {
        guard countriesTask == nil || countriesSubject.value.isFailure else { return }

        reloadCountries()
    }

    func reloadCountries() {
        countriesTask?.cancel()
        countriesSubject.send(.loading)

        countriesTask = Task { @MainActor [weak self, repository] in
            do {
                let countries = try await repository.countries()
                guard !Task.isCancelled else { return }
                self?.countriesSubject.send(.success(countries))
            } catch {
                guard !Task.isCancelled else { return }
                VisaLogger.error("Failed to load Tangem Pay countries", error: error)
                self?.countriesSubject.send(.failure(error))
            }
        }
    }

    func loadRegions(countryCode: String) {
        let isFailed = regionsSubject.value[countryCode]?.isFailure ?? false

        guard regionsTasks[countryCode] == nil || isFailed else { return }

        reloadRegions(countryCode: countryCode)
    }

    func reloadRegions(countryCode: String) {
        regionsTasks[countryCode]?.cancel()
        update(regionsState: .loading, for: countryCode)

        regionsTasks[countryCode] = Task { @MainActor [weak self, repository] in
            do {
                let regions = try await repository.regions(countryCode: countryCode)
                guard !Task.isCancelled else { return }
                self?.update(regionsState: .success(regions), for: countryCode)
            } catch {
                guard !Task.isCancelled else { return }
                VisaLogger.error("Failed to load Tangem Pay regions", error: error)
                self?.update(regionsState: .failure(error), for: countryCode)
            }
        }
    }
}

// MARK: - Regions state

private extension TangemPayGeoStore {
    func update(regionsState: RegionsState, for countryCode: String) {
        var states = regionsSubject.value
        states[countryCode] = regionsState
        regionsSubject.send(states)
    }
}
