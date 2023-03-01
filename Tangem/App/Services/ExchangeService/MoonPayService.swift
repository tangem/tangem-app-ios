//
//  TopupService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit
import Alamofire
import Combine
import BlockchainSdk

// MARK: - Models

fileprivate enum QueryKey: String {
    case apiKey
    case currencyCode
    case walletAddress
    case redirectURL
    case baseCurrencyCode
    case refundWalletAddress
    case signature
    case baseCurrencyAmount
    case depositWalletAddress
}

fileprivate struct IpCheckResponse: Decodable {
    let countryCode: String
    let stateCode: String
    let isMoonpayAllowed: Bool
    let isBuyAllowed: Bool
    let isSellAllowed: Bool

    private enum CodingKeys: String, CodingKey {
        case countryCode = "alpha3"
        case isMoonpayAllowed = "isAllowed"
        case stateCode = "state"
        case isBuyAllowed, isSellAllowed
    }
}

struct MoonpayCurrency: Decodable {
    enum CurrencyType: String, Decodable {
        case crypto
        case fiat
    }

    enum NetworkCode: String, Decodable {
        case bitcoin
        case bitcoinCash = "bitcoin_cash"
        case ethereum
        case bnbChain = "bnb_chain"
        case stellar
        case litecoin
        case solana
        case unknown

        func blockchain(testnet: Bool) -> Blockchain? {
            switch self {
            case .unknown:
                return nil
            case .bitcoin:
                return .bitcoin(testnet: testnet)
            case .bitcoinCash:
                return .bitcoinCash(testnet: testnet)
            case .ethereum:
                return .ethereum(testnet: testnet)
            case .bnbChain:
                return .binance(testnet: testnet)
            case .solana:
                return .solana(testnet: testnet)
            case .litecoin:
                return .litecoin
            case .stellar:
                return .stellar(testnet: testnet)
            }
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            self = NetworkCode(rawValue: value) ?? .unknown
        }
    }

    struct Metadata: Decodable {
        let contractAddress: String?
        let chainId: String?
        let networkCode: NetworkCode
    }

    let type: CurrencyType
    let code: String
    let supportsLiveMode: Bool?
    let isSuspended: Bool?
    let isSupportedInUS: Bool?
    let isSellSupported: Bool?
    let notAllowedUSStates: [String]?
    let metadata: Metadata?
}

struct AvailableToSell: Hashable {
    let currencyCode: String
    let networkCode: MoonpayCurrency.NetworkCode
}

// MARK: - Service

class MoonPayService {
    @Injected(\.keysManager) var keysManager: KeysManager

    @Published private var initialized = false

    private var keys: MoonPayKeys { keysManager.moonPayKeys }

    private var availableToBuy: Set<String> = [
        "ZRX", "AAVE", "ALGO", "AXS", "BAT", "BNB", "BUSD", "BTC", "BCH", "BTT", "ADA", "CELO", "CUSD", "LINK", "CHZ", "COMP", "ATOM", "DAI", "DASH", "MANA", "DGB", "DOGE", "EGLD",
        "ENJ", "EOS", "ETC", "ETH", "KETH", "RINKETH", "FIL", "HBAR", "MIOTA", "KAVA", "KLAY", "LBC", "LTC", "LUNA", "MKR", "OM", "MATIC", "NANO", "NEAR", "XEM", "NEO", "NIM", "OKB",
        "OMG", "ONG", "ONT", "DOT", "QTUM", "RVN", "RFUEL", "KEY", "SRM", "SOL", "XLM", "STMX", "SNX", "KRT", "UST", "USDT", "XTZ", "RUNE", "SAND", "TOMO", "AVA", "TRX", "TUSD", "UNI",
        "USDC", "UTK", "VET", "WAXP", "WBTC", "XRP", "ZEC", "ZIL",
    ]

    private var availableToSell: Set<AvailableToSell> = [
        AvailableToSell(currencyCode: "BTC", networkCode: .bitcoin),
        AvailableToSell(currencyCode: "ETH", networkCode: .ethereum),
        AvailableToSell(currencyCode: "BCH", networkCode: .bnbChain),
    ]

    private(set) var canBuyCrypto = true
    private(set) var canSellCrypto = true
    private var bag: Set<AnyCancellable> = []

    deinit {
        AppLog.shared.debug("MoonPay deinit")
    }

    private func makeSignature(for components: URLComponents) -> URLQueryItem {
        let queryData = "?\(components.percentEncodedQuery!)".data(using: .utf8)!
        let secretKey = keys.secretApiKey.data(using: .utf8)!
        let signature = HMAC<SHA256>.authenticationCode(for: queryData, using: SymmetricKey(data: secretKey))

        return .init(key: .signature, value: Data(signature).base64EncodedString().addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed))
    }
}

extension MoonPayService: ExchangeService {
    var initializationPublisher: Published<Bool>.Publisher { $initialized }

    var successCloseUrl: String { "https://success.tangem.com" }

    var sellRequestUrl: String { "https://sell-request.tangem.com" }

    func canBuy(_ currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain) -> Bool {
        if currencySymbol.uppercased() == "BNB", blockchain == .bsc(testnet: true) || blockchain == .bsc(testnet: false) {
            return false
        }

        return availableToBuy.contains(currencySymbol.uppercased()) && canBuyCrypto
    }

    func canSell(_ currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain) -> Bool {
        if currencySymbol.uppercased() == "BNB", blockchain == .bsc(testnet: true) || blockchain == .bsc(testnet: false) {
            return false
        }

        guard let currency = availableToSell.first(where: { $0.currencyCode == currencySymbol.uppercased() }), canSellCrypto else {
            return false
        }

        return currency.networkCode.blockchain(testnet: blockchain.isTestnet) == blockchain
    }

    func getBuyUrl(currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain, walletAddress: String) -> URL? {
        guard canBuy(currencySymbol, amountType: amountType, blockchain: blockchain) else {
            return nil
        }

        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "buy.moonpay.io"

        var queryItems = [URLQueryItem]()
        queryItems.append(.init(key: .apiKey, value: keys.apiKey.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        queryItems.append(.init(key: .currencyCode, value: currencySymbol.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        queryItems.append(.init(key: .walletAddress, value: walletAddress.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        queryItems.append(.init(key: .redirectURL, value: successCloseUrl.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)))
        queryItems.append(.init(key: .baseCurrencyCode, value: "USD".addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        urlComponents.percentEncodedQueryItems = queryItems
        let signatureItem = makeSignature(for: urlComponents)
        queryItems.append(signatureItem)
        urlComponents.percentEncodedQueryItems = queryItems

        let url = urlComponents.url
        return url
    }

    func getSellUrl(currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain, walletAddress: String) -> URL? {
        guard canSell(currencySymbol, amountType: amountType, blockchain: blockchain) else {
            return nil
        }

        var components = URLComponents()
        components.scheme = "https"
        components.host = "sell.moonpay.com"

        var queryItems = [URLQueryItem]()
        queryItems.append(.init(key: .apiKey, value: keys.apiKey.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        queryItems.append(.init(key: .baseCurrencyCode, value: currencySymbol.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        queryItems.append(.init(key: .refundWalletAddress, value: walletAddress.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        queryItems.append(.init(key: .redirectURL, value: sellRequestUrl.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)))

        components.percentEncodedQueryItems = queryItems
        let signature = makeSignature(for: components)
        queryItems.append(signature)
        components.percentEncodedQueryItems = queryItems

        let url = components.url
        return url
    }

    func extractSellCryptoRequest(from data: String) -> SellCryptoRequest? {
        guard
            data.starts(with: sellRequestUrl),
            let url = URL(string: data),
            let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
            let items = components.queryItems,
            let currencyCode = items.first(where: { $0.name == QueryKey.baseCurrencyCode.rawValue })?.value,
            let amountStr = items.first(where: { $0.name == QueryKey.baseCurrencyAmount.rawValue })?.value,
            let amount = Decimal(string: amountStr),
            let targetAddress = items.first(where: { $0.name == QueryKey.depositWalletAddress.rawValue })?.value
        else {
            return nil
        }

        return .init(currencyCode: currencyCode, amount: amount, targetAddress: targetAddress)
    }

    func initialize() {
        if initialized {
            return
        }

        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil

        let session = URLSession(configuration: config)

        Publishers.Zip(
            session.dataTaskPublisher(for: URL(string: "https://api.moonpay.com/v4/ip_address?" + QueryKey.apiKey.rawValue + "=" + keys.apiKey)!),
            session.dataTaskPublisher(for: URL(string: "https://api.moonpay.com/v3/currencies?" + QueryKey.apiKey.rawValue + "=" + keys.apiKey)!)
        )
        .sink(receiveCompletion: { _ in }) { [weak self] ipOutput, currenciesOutput in
            guard let self = self else { return }
            let decoder = JSONDecoder()
            var countryCode = ""
            var stateCode = ""
            do {
                let decodedResponse = try decoder.decode(IpCheckResponse.self, from: ipOutput.data)
                self.canBuyCrypto = decodedResponse.isBuyAllowed
                self.canSellCrypto = decodedResponse.isSellAllowed
                countryCode = decodedResponse.countryCode
                stateCode = decodedResponse.stateCode
            } catch {
                AppLog.shared.debug("Failed to check IP address")
                AppLog.shared.error(error)
            }
            do {
                var currenciesToBuy = Set<String>()
                var currenciesToSell = Set<AvailableToSell>()
                let decodedResponse = try decoder.decode([MoonpayCurrency].self, from: currenciesOutput.data)
                decodedResponse.forEach {
                    guard
                        $0.type == .crypto,
                        let isSuspended = $0.isSuspended, !isSuspended,
                        let supportsLiveMode = $0.supportsLiveMode, supportsLiveMode
                    else { return }

                    if countryCode == "USA" {
                        if let isSupportedInUS = $0.isSupportedInUS, !isSupportedInUS {
                            return
                        }

                        if let notAllowedUSStates = $0.notAllowedUSStates, notAllowedUSStates.contains(stateCode) {
                            return
                        }
                    }

                    currenciesToBuy.insert($0.code.uppercased())

                    if let isSellSupported = $0.isSellSupported, isSellSupported, let metadata = $0.metadata {
                        currenciesToSell.insert(
                            AvailableToSell(currencyCode: $0.code.uppercased(), networkCode: metadata.networkCode)
                        )
                    }
                }
                self.availableToBuy = currenciesToBuy
                self.availableToSell = currenciesToSell
            } catch {
                AppLog.shared.debug("Failed to load currencies")
                AppLog.shared.error(error)
            }

            self.initialized = true
        }
        .store(in: &bag)
    }
}

fileprivate extension URLQueryItem {
    init(key: QueryKey, value: String?) {
        self.init(name: key.rawValue, value: value)
    }
}
