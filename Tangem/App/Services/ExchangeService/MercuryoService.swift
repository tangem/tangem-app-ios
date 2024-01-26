//
//  MercuryoService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemSdk

private enum QueryKey: String {
    case widget_id
    case type
    case currency
    case address
    case signature
    case lang
    case fix_currency
    case redirect_url
    case theme
    case network
}

private struct MercuryoCurrencyResponse: Decodable {
    let data: MercuryoData
}

private struct MercuryoData: Decodable {
    let crypto: [String]
    let config: MercuryoConfig
}

private struct MercuryoConfig: Decodable {
    let cryptoCurrencies: [MercuryoCryptoCurrency]
}

private struct MercuryoCryptoCurrency: Decodable {
    let currency: String
    let network: String
    let contract: String?
}

class MercuryoService {
    @Injected(\.keysManager) private var keysManager: KeysManager

    @Published private var initialized = false

    private var widgetId: String {
        keysManager.mercuryoWidgetId
    }

    private var secret: String {
        keysManager.mercuryoSecret
    }

    private var useDarkTheme: Bool {
        UITraitCollection.isDarkMode
    }

    private var cryptoCurrencies: [MercuryoCryptoCurrency] = []

    private var bag: Set<AnyCancellable> = []

    private let darkThemeName = "1inch"

    deinit {
        AppLog.shared.debug("MercuryoService deinit")
    }
}

extension MercuryoService: ExchangeService {
    var initializationPublisher: Published<Bool>.Publisher { $initialized }

    var successCloseUrl: String { "https://success.tangem.com" }

    var sellRequestUrl: String { "" }

    // [REDACTED_TODO_COMMENT]
    func canBuy(_ currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain) -> Bool {
        getCryptoCurrency(amountType: amountType, blockchain: blockchain) != nil
    }

    func canSell(_ currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain) -> Bool {
        return false
    }

    func getBuyUrl(currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain, walletAddress: String) -> URL? {
        guard let cryptoCurrency = getCryptoCurrency(amountType: amountType, blockchain: blockchain) else {
            return nil
        }
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "exchange.mercuryo.io"
        var queryItems = [URLQueryItem]()
        queryItems.append(.init(key: .widget_id, value: widgetId.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        queryItems.append(.init(key: .type, value: "buy"))
        queryItems.append(.init(key: .currency, value: cryptoCurrency.currency.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        queryItems.append(.init(key: .network, value: cryptoCurrency.network.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        queryItems.append(.init(key: .address, value: walletAddress.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        queryItems.append(.init(key: .signature, value: signature(for: walletAddress).addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        queryItems.append(.init(key: .fix_currency, value: "true"))
        queryItems.append(.init(key: .redirect_url, value: successCloseUrl.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)))

        if let languageCode = Locale.current.languageCode {
            queryItems.append(.init(key: .lang, value: languageCode))
        }

        if useDarkTheme {
            queryItems.append(.init(key: .theme, value: darkThemeName))
        }

        urlComponents.percentEncodedQueryItems = queryItems

        let url = urlComponents.url
        return url
    }

    func getSellUrl(currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain, walletAddress: String) -> URL? {
        fatalError("[REDACTED_TODO_COMMENT]")
    }

    func extractSellCryptoRequest(from data: String) -> SellCryptoRequest? {
        return nil
    }

    func initialize() {
        if initialized {
            return
        }

        let request = URLRequest(url: URL(string: "https://api.mercuryo.io/v1.6/lib/currencies")!)

        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        URLSession(configuration: config).dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: MercuryoCurrencyResponse.self, decoder: decoder)
            .sink { _ in

            } receiveValue: { [unowned self] response in
                cryptoCurrencies = response.data.config.cryptoCurrencies
                initialized = true
            }
            .store(in: &bag)
    }

    private func signature(for address: String) -> String {
        (address + secret).sha512()
    }

    private func getCryptoCurrency(amountType: Amount.AmountType, blockchain: Blockchain) -> MercuryoCryptoCurrency? {
        let symbol = amountType.token?.symbol ?? blockchain.currencySymbol

        guard let mercuryoNetwork = blockchain.mercuryoNetwork else {
            return nil
        }

        let cryptoCurrency = cryptoCurrencies.first(where: {
            let contract = amountType.token?.contractAddress.lowercased() ?? ""
            let cryptoCurrencyContract = $0.contract?.lowercased() ?? ""

            return $0.currency == symbol.uppercased()
                && $0.network == mercuryoNetwork
                && contract == cryptoCurrencyContract
        })

        return cryptoCurrency
    }
}

private extension URLQueryItem {
    init(key: QueryKey, value: String?) {
        self.init(name: key.rawValue, value: value)
    }
}

private extension Blockchain {
    var mercuryoNetwork: String? {
        switch self {
//        case .algorand:   //[REDACTED_TODO_COMMENT]
//            return "ALGORAND"
        case .arbitrum:
            return "ARBITRUM"
        case .avalanche:
            return "AVALANCHE"
        case .bsc:
            return "BINANCESMARTCHAIN"
        case .bitcoin:
            return "BITCOIN"
        case .bitcoinCash:
            return "BITCOINCASH"
        case .cardano:
            return "CARDANO"
        case .cosmos:
            return "COSMOS"
        case .dash:
            return "DASH"
        case .dogecoin:
            return "DOGECOIN"
        case .ethereum:
            return "ETHEREUM"
        case .fantom:
            return "FANTOM"
        case .kusama:
            return "KUSAMA"
        case .litecoin:
            return "LITECOIN"
        case .near:
            return "NEAR_PROTOCOL"
        case .ton:
            return "NEWTON"
        case .optimism:
            return "OPTIMISM"
        case .polkadot:
            return "POLKADOT"
        case .polygon:
            return "POLYGON"
        case .xrp:
            return "RIPPLE"
        case .solana:
            return "SOLANA"
        case .stellar:
            return "STELLAR"
        case .tezos:
            return "TEZOS"
        case .tron:
            return "TRON"
        default:
            return nil
        }
    }
}
