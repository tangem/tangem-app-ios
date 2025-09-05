//
//  XRPNetworkService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine
import TangemFoundation
import TangemNetworkUtils

class XRPNetworkProvider: XRPNetworkServiceType, HostProvider {
    var host: String {
        node.url.absoluteString
    }

    private let node: NodeInfo
    private let provider: TangemProvider<XRPTarget>

    init(node: NodeInfo, configuration: TangemProviderConfiguration) {
        self.node = node
        provider = TangemProvider<XRPTarget>(configuration: configuration)
    }

    func getFee() -> AnyPublisher<XRPFeeResponse, Error> {
        return request(.fee)
            .tryMap { xrpResponse -> XRPFeeResponse in
                guard let minFee = xrpResponse.result?.drops?.minimum_fee,
                      let normalFee = xrpResponse.result?.drops?.open_ledger_fee,
                      let maxFee = xrpResponse.result?.drops?.median_fee,
                      let minFeeDecimal = Decimal(string: minFee),
                      let normalFeeDecimal = Decimal(string: normalFee),
                      let maxFeeDecimal = Decimal(string: maxFee) else {
                    throw BlockchainSdkError.failedToGetFee
                }

                return XRPFeeResponse(min: minFeeDecimal, normal: normalFeeDecimal, max: maxFeeDecimal)
            }
            .eraseToAnyPublisher()
    }

    func send(blob: String) -> AnyPublisher<String, Error> {
        return request(.submit(tx: blob))
            .tryMap { xrpResponse -> String in
                guard let code = xrpResponse.result?.engine_result_code else {
                    throw BlockchainSdkError.failedToSendTx
                }

                if code != 0 {
                    let message = xrpResponse.result?.engine_result_message ?? BlockchainSdkError.failedToSendTx.localizedDescription
                    if message != "Held until escalated fee drops." { // [REDACTED_TODO_COMMENT]
                        throw message
                    }
                }

                guard let hash = xrpResponse.result?.tx_json?.hash else {
                    throw BlockchainSdkError.failedToSendTx
                }

                return hash
            }
            .eraseToAnyPublisher()
    }

    func getUnconfirmed(account: String) -> AnyPublisher<Decimal, Error> {
        return request(.unconfirmed(account: account))
            .tryMap { xrpResponse -> Decimal in
                try xrpResponse.assertAccountCreated()

                guard let unconfirmedBalanceString = xrpResponse.result?.account_data?.balance,
                      let unconfirmedBalance = Decimal(stringValue: unconfirmedBalanceString) else {
                    throw XRPError.failedLoadUnconfirmed
                }

                return unconfirmedBalance
            }
            .eraseToAnyPublisher()
    }

    func getReserve() -> AnyPublisher<Decimal, Error> {
        return request(.reserve)
            .tryMap { xrpResponse -> Decimal in
                try xrpResponse.assertAccountCreated()

                guard let reserveBase = xrpResponse.result?.state?.validated_ledger?.reserve_base else {
                    throw XRPError.failedLoadReserve
                }

                return Decimal(reserveBase)
            }
            .eraseToAnyPublisher()
    }

    func getAccountInfo(account: String) -> AnyPublisher<(balance: Decimal, sequence: Int), Error> {
        return request(.accountInfo(account: account))
            .tryMap { xrpResponse in
                let accountResponse = try Self.validateXRPResponseAndGetAccountResponse(xrpResponse)

                guard
                    let balanceString = accountResponse.balance,
                    let sequence = accountResponse.sequence,
                    let balance = Decimal(stringValue: balanceString)
                else {
                    throw XRPError.failedLoadInfo
                }

                return (balance: balance, sequence: sequence)
            }
            .eraseToAnyPublisher()
    }

    func getSequence(account: String) -> AnyPublisher<Int, Error> {
        return request(.accountInfo(account: account))
            .tryMap { xrpResponse in
                let accountResponse = try Self.validateXRPResponseAndGetAccountResponse(xrpResponse)

                guard let sequence = accountResponse.sequence else {
                    throw XRPError.failedLoadInfo
                }

                return sequence
            }
            .eraseToAnyPublisher()
    }

    func shouldAllowPartialPayment(for issuer: String) -> AnyPublisher<Bool, Error> {
        return request(.accountInfo(account: issuer))
            .tryMap { xrpResponse in
                let accountResponse = try Self.validateXRPResponseAndGetAccountResponse(xrpResponse)
                // A TransferRate of 0, 1_000_000_000, or nil means no fee is set, so partial payments are not required.
                // Only values greater than 1_000_000_000 indicate an issuer fee.
                return accountResponse.transferRate ?? 0 > 1_000_000_000
            }
            .eraseToAnyPublisher()
    }

    func getInfo(account: String) -> AnyPublisher<XrpInfoResponse, Error> {
        return Publishers.Zip4(
            getUnconfirmed(account: account),
            getReserve(),
            getAccountInfo(account: account),
            getAccountTrustlines(account: account)
        )
        .map { unconfirmed, reserve, info, trustlines -> XrpInfoResponse in
            return XrpInfoResponse(
                balance: info.balance,
                sequence: info.sequence,
                unconfirmedBalance: unconfirmed,
                reserve: reserve,
                trustlines: trustlines
            )
        }
        .eraseToAnyPublisher()
    }

    func checkAccountCreated(account: String) -> AnyPublisher<Bool, Error> {
        return request(.accountInfo(account: account))
            .map { xrpResponse -> Bool in
                do {
                    try xrpResponse.assertAccountCreated()
                    return true
                } catch {
                    return false
                }
            }
            .eraseToAnyPublisher()
            .eraseError()
    }

    func getAccountTrustlines(account: String) -> AnyPublisher<Result<[XRPTrustLine], Error>, Error> {
        request(.accountLines(account: account))
            .map { response in
                let trustlines = response.result?.lines ?? []
                return .success(trustlines)
            }
            .catch { error in
                Just(.failure(error)).setFailureType(to: Error.self)
            }
            .eraseToAnyPublisher()
    }

    func checkAccountDestinationTag(account: String) -> AnyPublisher<Bool, Error> {
        return request(.accountInfo(account: account))
            .map { xrpResponse -> Bool in
                xrpResponse.result?.account_flags?.requireDestinationTag ?? false
            }
            .eraseToAnyPublisher()
            .eraseError()
    }

    private func request(_ target: XRPTarget.XRPTargetType) -> AnyPublisher<XrpResponse, MoyaError> {
        provider
            .requestPublisher(XRPTarget(node: node, target: target))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(XrpResponse.self)
    }

    private static func validateXRPResponseAndGetAccountResponse(_ xrpResponse: XrpResponse) throws -> XrpAccountData {
        try xrpResponse.assertAccountCreated()

        if let accountResponse = xrpResponse.result?.account_data {
            return accountResponse
        }

        throw XRPError.failedLoadInfo
    }
}
