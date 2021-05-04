//
//  BitcoinNetworkService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine
import Alamofire

class BitcoinNetworkService: BitcoinNetworkProvider {
    private let isTestNet: Bool
    private var networkApi: BitcoinNetworkApi
    private let providers: [BitcoinNetworkApi: BitcoinNetworkProvider]
    
    init(providers:[BitcoinNetworkApi: BitcoinNetworkProvider], isTestNet:Bool, defaultApi: BitcoinNetworkApi = .main) {
        self.providers = providers
        self.isTestNet = isTestNet
        self.networkApi = defaultApi
    }
    
    func getInfo(addresses: [String]) -> AnyPublisher<[BitcoinResponse], Error> {
        return Just(())
            .setFailureType(to: Error.self)
            .flatMap {[unowned self] in self.getProvider().getInfo(addresses: addresses) }
            .mapError {[unowned self] in self.handleError($0)}
            .retry(2)
            .eraseToAnyPublisher()
    }
    
    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        return Just(())
            .setFailureType(to: Error.self)
            .flatMap {[unowned self] in self.getProvider().getInfo(address: address) }
            .mapError {[unowned self] in self.handleError($0)}
            .retry(2)
            .eraseToAnyPublisher()
    }
    
    func getProvider() -> BitcoinNetworkProvider {
        if providers.count == 1 {
            return providers.first!.value
        }
        
        return isTestNet ? providers[.blockcypher]!: providers[networkApi] ?? providers.first!.value
    }
    
    private func handleError(_ error: Error) -> Error {
        if let moyaError = error as? MoyaError,
           case let MoyaError.statusCode(response) = moyaError,
           self.providers.count > 1,
           response.statusCode > 299  {
            switchProvider()
        }
        
        return error
    }
	
	private func switchProvider() {
		switch networkApi {
		case .main:
			networkApi = .blockchair
		case .blockchair:
			networkApi = .blockcypher
        case .blockcypher:
            networkApi = .blockchair
		}
		print("Bitcoin network service switched to: \(networkApi)")
	}
	
}
