//
//  MultiNetworkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Moya
import stellarsdk
import TangemNetworkUtils
import TangemFoundation

@available(iOS 13.0, *)
protocol MultiNetworkProvider: AnyObject, HostProvider {
    associatedtype Provider: HostProvider

    var providers: [Provider] { get }
    var blockchainName: String { get }
    var currentProviderIndex: Int { get set }
}

extension MultiNetworkProvider {
    var provider: Provider? {
        if currentProviderIndex >= providers.count {
            return nil
        }

        return providers[currentProviderIndex]
    }

    var host: String { provider?.host ?? .unknown }

    func providerPublisher<T>(for requestPublisher: @escaping (_ provider: Provider) -> AnyPublisher<T, Error>) -> AnyPublisher<T, Error> {
        guard let provider else {
            return .anyFail(error: BlockchainSdkError.noAPIInfo)
        }

        let currentHost = provider.host
        return requestPublisher(provider)
            .catch { [weak self] error -> AnyPublisher<T, Error> in
                guard let self = self else { return .anyFail(error: error) }

                if let moyaError = error as? MoyaError, case .statusCode(let resp) = moyaError {
                    NetworkLogger.error("Message: \(String(describing: String(data: resp.data, encoding: .utf8)))", error: moyaError)
                } else {
                    NetworkLogger.error(error: error)
                }

                if case BlockchainSdkError.noAccount = error {
                    return .anyFail(error: error)
                }

                if case HorizonRequestError.notFound = error {
                    return .anyFail(error: error)
                }

                if case BlockchainSdkError.accountNotActivated = error {
                    return .anyFail(error: error)
                }

                let beforeSwitchIfNeededHost = host

                if let nextHost = switchProviderIfNeeded(for: currentHost) {
                    // Send event if API was switched by a host value
                    if nextHost != beforeSwitchIfNeededHost {
                        NetworkLogger.info("Next host: \(nextHost)")

                        ExceptionHandler.shared.handleAPISwitch(
                            currentHost: currentHost,
                            nextHost: nextHost,
                            message: error.localizedDescription,
                            blockchainName: blockchainName
                        )
                    }

                    return providerPublisher(for: requestPublisher)
                }

                // Need captured currentHost, to be able to get hosting after switching.
                let returnedError = MultiNetworkProviderError(networkError: error.toUniversalError(), lastRetryHost: currentHost)
                return .anyFail(error: returnedError)
            }
            .eraseToAnyPublisher()
    }

    /// NOTE: There also copy of this behaviour in the wild, if you want to update something
    /// in the code, don't forget to update also Solano.Swift framework, class NetworkingRouter
    private func switchProviderIfNeeded(for errorHost: String) -> String? {
        if errorHost != host { // Do not switch the provider, if it was switched already
            return providers[currentProviderIndex].host
        }

        currentProviderIndex += 1
        if currentProviderIndex < providers.count {
            return providers[currentProviderIndex].host
        }
        resetProviders()
        return nil
    }

    private func resetProviders() {
        currentProviderIndex = 0
    }
}

struct MultiNetworkProviderError: UniversalError {
    let networkError: UniversalError
    let lastRetryHost: String

    var errorDescription: String? {
        networkError.localizedDescription
    }

    var errorCode: Int {
        networkError.errorCode
    }
}
