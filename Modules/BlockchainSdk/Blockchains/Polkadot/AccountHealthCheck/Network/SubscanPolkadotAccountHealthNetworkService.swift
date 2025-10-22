//
//  SubscanPolkadotAccountHealthNetworkService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import enum Moya.MoyaError
import TangemNetworkUtils

public final class SubscanPolkadotAccountHealthNetworkService {
    private typealias SkipRetryIf = (_ error: Error) -> Bool

    private let provider = TangemProvider<SubscanAPITarget>(configuration: .ephemeralConfiguration)

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    private let isTestnet: Bool
    private let pageSize: Int

    public init(
        isTestnet: Bool,
        pageSize: Int
    ) {
        self.isTestnet = isTestnet
        self.pageSize = pageSize
    }

    public func getAccountHealthInfo(account: String) async throws -> PolkadotAccountHealthInfo {
        do {
            let result = try await perform(
                request: .init(
                    isTestnet: isTestnet,
                    encoder: encoder,
                    target: .getAccountInfo(address: account)
                ),
                output: SubscanAPIResult.AccountInfo.self,
                failure: SubscanAPIResult.Error.self,
                retryAttempt: 0
            ) { error in
                // Do not retry account info requests for new and non-activated accounts
                if let error = error as? SubscanAPIResult.Error, error.code == Constants.nonExistentAccountErrorCode {
                    return true
                }
                return false
            }
            .data
            .account

            return .existingAccount(extrinsicCount: result.countExtrinsic, nonceCount: result.nonce)
        } catch let error as SubscanAPIResult.Error where error.code == Constants.nonExistentAccountErrorCode {
            return .nonExistentAccount
        } catch {
            throw error
        }
    }

    public func getTransactionsList(account: String, afterId: Int) async throws -> [PolkadotTransaction] {
        let result = try await perform(
            request: .init(
                isTestnet: isTestnet,
                encoder: encoder,
                target: .getExtrinsicsList(
                    address: account,
                    afterId: afterId,
                    page: Constants.startPage,
                    limit: pageSize
                )
            ),
            output: SubscanAPIResult.ExtrinsicsList.self,
            failure: SubscanAPIResult.Error.self,
            retryAttempt: 0
        )
        .data
        .extrinsics

        return result?.map { PolkadotTransaction(id: $0.id, hash: $0.extrinsicHash) } ?? []
    }

    public func getTransactionDetails(hash: String) async throws -> PolkadotTransactionDetails {
        let result = try await perform(
            request: .init(
                isTestnet: isTestnet,
                encoder: encoder,
                target: .getExtrinsicInfo(hash: hash)
            ),
            output: SubscanAPIResult.ExtrinsicInfo.self,
            failure: SubscanAPIResult.Error.self,
            retryAttempt: 0
        )
        .data
        .lifetime

        return PolkadotTransactionDetails(birth: result?.birth, death: result?.death)
    }

    private func perform<Output, Failure>(
        request: SubscanAPITarget,
        output: Output.Type,
        failure: Failure.Type,
        retryAttempt: Int,
        skipRetryIf: SkipRetryIf? = nil
    ) async throws -> Output where Output: Decodable, Failure: Decodable, Failure: Error {
        do {
            return try await provider
                .asyncRequest(for: request)
                .filterSuccessfulStatusAndRedirectCodes()
                .tryMap(output: output, failure: failure, using: decoder)
        } catch {
            guard
                retryAttempt < Constants.maxRetryCount,
                shouldRetry(error: error, skipRetryIf: skipRetryIf)
            else {
                throw error
            }

            let nextRetryAttempt = retryAttempt + 1
            let retryInterval = ExponentialBackoffInterval(retryAttempt: nextRetryAttempt)
            try await Task.sleep(nanoseconds: retryInterval())

            return try await perform(
                request: request,
                output: output, failure: failure,
                retryAttempt: nextRetryAttempt,
                skipRetryIf: skipRetryIf
            )
        }
    }

    /// - Warning: allows retries for ANY errors except mapping and cancellation errors, use with caution.
    private func shouldRetry(error: Error, skipRetryIf: SkipRetryIf?) -> Bool {
        if skipRetryIf?(error) == true {
            return false
        }

        if error is DecodingError {
            return false
        }

        if error.asMoyaError?.isMappingError == true {
            return false
        }

        if error is CancellationError {
            return false
        }

        if let errorCode = error.networkErrorCode, errorCode == .cancelled {
            return false
        }

        return true
    }
}

// MARK: - Constants

private extension SubscanPolkadotAccountHealthNetworkService {
    enum Constants {
        // - Note: Subscan API has zero-based indexing
        static let startPage = 0
        static let maxRetryCount = 3
        static let nonExistentAccountErrorCode = 10004
    }
}
