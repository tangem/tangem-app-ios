//
//  XRPNetworkManager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import RxSwift
import Combine

class XRPNetworkManager {
    let provider = MoyaProvider<XrpTarget>()
    
    @available(iOS 13.0, *)
    func getFee() -> AnyPublisher<XRPFeeResponse, Error> {
        return provider
            .requestPublisher(.fee)
            .map(XrpResponse.self)
            .tryMap { xrpResponse -> XRPFeeResponse in
                guard let minFee = xrpResponse.result?.drops?.minimum_fee,
                    let normalFee = xrpResponse.result?.drops?.open_ledger_fee,
                    let maxFee = xrpResponse.result?.drops?.median_fee,
                    let minFeeDecimal = Decimal(string: minFee),
                    let normalFeeDecimal = Decimal(string: normalFee),
                    let maxFeeDecimal = Decimal(string: maxFee) else {
                        throw "Failed to get fee"
                }
                
                return XRPFeeResponse(min: minFeeDecimal, normal: normalFeeDecimal, max: maxFeeDecimal)
        }
        .eraseToAnyPublisher()
    }
    
    @available(iOS 13.0, *)
    func send(blob: String) -> AnyPublisher<Bool, Error> {
        return provider
            .requestPublisher(.submit(tx: blob))
            .map(XrpResponse.self)
            .tryMap { xrpResponse -> Bool in
                guard let code = xrpResponse.result?.engine_result_code else {
                    throw "Submit error"
                }
                
                if code != 0 {
                    let message = xrpResponse.result?.engine_result_message ?? "Failed to send"
                    throw message
                }
                
                return true
        }
        .eraseToAnyPublisher()
    }
    
    func getUnconfirmed(account: String) -> Single<Decimal> {
        return provider
            .rx
            .request(.unconfirmed(account: account))
            .map(XrpResponse.self)
            .map { xrpResponse -> Decimal in
                guard let unconfirmedBalanceString = xrpResponse.result?.account_data?.balance,
                    let unconfirmedBalance = Decimal(unconfirmedBalanceString) else {
                        throw "Failed to load balance"
                }
                
                return unconfirmedBalance
        }
    }
    
    func getReserve() -> Single<Decimal> {
        return provider
            .rx
            .request(.reserve)
            .map(XrpResponse.self)
            .map{ xrpResponse -> Decimal in
                guard let reserveBase = xrpResponse.result?.state?.validated_ledger?.reserve_base else {
                    throw "Failed to load reserve"
                }
                
                return Decimal(reserveBase)
        }
    }
    
    func getAccountInfo(account: String) -> Single<(balance: Decimal, sequence: Int)> {
        return provider
            .rx
            .request(.accountInfo(account: account))
            .map(XrpResponse.self)
            .map{ xrpResponse in
                if let code = xrpResponse.result?.error_code, code == 19 {
                    throw "No account"
                }
                
                guard let accountResponse = xrpResponse.result?.account_data,
                    let balanceString = accountResponse.balance,
                    let sequence = accountResponse.sequence,
                    let balance = Decimal(balanceString) else {
                        throw "Failed to load data"
                }
                
                return (balance: balance, sequence: sequence)
        }
    }
    
    func getInfo(account: String) -> Single<XrpInfoResponse> {
        return Single.zip(getUnconfirmed(account: account),
                          getReserve(),
                          getAccountInfo(account: account))
            .map { (unconfirmed, reserve, info) -> XrpInfoResponse in
                return XrpInfoResponse(balance: info.balance,
                                       sequence: info.sequence,
                                       unconfirmedBalance: unconfirmed,
                                       reserve: reserve)
        }
    }
    
    @available(iOS 13.0, *)
    func checkAccountCreated(account: String) -> AnyPublisher<Bool, Error> {
        return provider
            .requestPublisher(.accountInfo(account: account))
            .map(XrpResponse.self)
            .tryMap { xrpResponse -> Bool in
                if let code = xrpResponse.result?.error_code, code == 19 {
                    return false
                }
                return true
        }
        .eraseToAnyPublisher()
    }
}
