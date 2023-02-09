//
//  UtorgService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

fileprivate struct UtorgResponse<SuccessResult: Decodable>: Decodable {
    let success: Bool
    let timestamp: Double
    let data: SuccessResult?
    let error: UtorgError?
}

fileprivate enum UtorgErrorType: String, Decodable {
    case unauthorized = "UNAUTHORIZED"
    case unknownError = "UNKNOWN_ERROR"
}

fileprivate struct UtorgError: Decodable {
    let type: UtorgErrorType
    let message: String?
}

fileprivate struct UtorgCurrency: Decodable {
    let currency: String
    let symbol: String
    let enabled: Bool
    let type: CurrencyType
    let caption: String?
    let chain: String?
}

fileprivate enum CurrencyType: String, Decodable {
    case crypto = "CRYPTO"
    case fiat = "FIAT"
}

class UtorgService {
    @Injected(\.keysManager) var keysManager: KeysManager
    @Published private var initializationSubject: Bool = false

    private var supportedCurrencies = [UtorgCurrency]()

    private var host: String {
        if AppEnvironment.current.isTestnet {
            return "app-stage.utorg.pro"
        }

        return "app.utorg.pro"
    }

    private func currency(with symbol: String, blockchain: Blockchain) -> UtorgCurrency? {
        return supportedCurrencies.first(where: {
            guard
                let chainString = $0.chain,
                let convertedBlockchain = Blockchain(from: chainString.lowercased()),
                $0.enabled,
                $0.symbol.lowercased() == symbol.lowercased(),
                convertedBlockchain == blockchain
            else {
                return false
            }

            return true
        })
    }
}

extension UtorgService: ExchangeService {
    var initialized: Published<Bool>.Publisher { $initializationSubject }

    var successCloseUrl: String { "https://success.tangem.com" }

    var sellRequestUrl: String { "" }

    func canBuy(_ currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain) -> Bool {
        AppLog.shared.debug("[Utorg] Can buy: \(currencySymbol). blockchain: \(blockchain)")
        return currency(with: currencySymbol, blockchain: blockchain) != nil
    }

    func canSell(_ currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain) -> Bool {
        return false
    }

    func getBuyUrl(currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain, walletAddress: String) -> URL? {
        guard let utorgCurrency = currency(with: currencySymbol, blockchain: blockchain) else {
            return nil
        }

        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = host

        urlComponents.queryItems = [
            .init(name: "currency", value: utorgCurrency.currency.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)),
        ]

        let url = urlComponents.url?
            .appendingPathComponent("direct")
            .appendingPathComponent(keysManager.utorgSID.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed) ?? "")
            .appendingPathComponent(walletAddress.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed) ?? "")

        return url
    }

    func getSellUrl(currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain, walletAddress: String) -> URL? {
        return nil
    }

    func extractSellCryptoRequest(from data: String) -> SellCryptoRequest? {
        return nil
    }

    func initialize() {
        if initializationSubject {
            return
        }

        Task {
            do {
                try await loadCurrencies()
            } catch {
                AppLog.shared.debug("[Utorg] Failed to load currencies. Error: \(error)")
            }
        }
    }

    private func loadCurrencies() async throws {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = host
        urlComponents.path = "/api/merchant/v1/settings/currency"

        guard let url = urlComponents.url else {
            AppLog.shared.debug("[Utorg] Failed to create url")
            return
        }

        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = [
            "Content-Type": "application/json;charset=UTF-8",
            "X-AUTH-SID": keysManager.utorgSID,
            "X-AUTH-NONCE": UUID().uuidString,
        ]
        request.httpMethod = "POST"

        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil

        AppLog.shared.debug("[Utorg] Request headers: \(request.allHTTPHeaderFields!)")
        let (responseData, _) = try await URLSession(configuration: config).upload(for: request, from: Data())

        let decoder = JSONDecoder()
        let currenciesResponse = try decoder.decode(UtorgResponse<[UtorgCurrency]>.self, from: responseData)

        guard let loadedCurrencies = currenciesResponse.data else {
            AppLog.shared.debug("[Utorg] Failed to load currencies data. Currencies response: \(currenciesResponse)")
            return
        }

        supportedCurrencies = loadedCurrencies.filter { $0.type == .crypto }
        AppLog.shared.debug("[Utorg] Filtered crypto: \(supportedCurrencies)")
        initializationSubject = true
    }
}
