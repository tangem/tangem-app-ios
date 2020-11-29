//
//  ImageLoaderService.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import UIKit
import TangemSdk

class ImageLoaderService {
    let networkService: TmpNetworkService
    private let defaultImageName = "card_default"
    
    init(networkService: TmpNetworkService) {
        self.networkService = networkService
    }
    
    func loadImage(cid: String, cardPublicKey: Data, artworkInfo: ArtworkInfo?) -> AnyPublisher<UIImage, Error> {
        if cid.starts(with: "BC01") { //Sergio
            return backedLoadImage(name: "card_tg059")
        }
        
        if cid.starts(with: "BC02") { //Marta
            return backedLoadImage(name: "card_tg083")
        }
        
        guard let artworkId = artworkInfo?.id else {
            return backedLoadImage(name: defaultImageName)
        }
        
        let endpoint = TangemEndpoint.artwork(cid: cid,
                                              cardPublicKey: cardPublicKey,
                                              artworkId: artworkId)
        
        return networkService
            .requestPublisher(endpoint)
            .subscribe(on: DispatchQueue.global())
            .tryMap { data -> UIImage in
                if let image = UIImage(data: data) {
                    return image
                }
                
                throw "Image mapping failed"
            }
            .tryCatch {[weak self] error -> AnyPublisher<UIImage, Error> in
                guard let self = self else {
                    throw error
                }
                
                return self.backedLoadImage(name: self.defaultImageName)
            }
            .eraseToAnyPublisher()
    }
    
    func backedLoadImage(name: String) -> AnyPublisher<UIImage, Error> {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        let session = URLSession(configuration: configuration)
        return session
            .dataTaskPublisher(for: URL(string: "https://app.tangem.com/cards/\(name).png")!)
            .subscribe(on: DispatchQueue.global())
            .tryMap { data, response -> UIImage in
                if let image = UIImage(data: data) {
                    return image
                }
                
                throw "Image mapping failed"
            }.eraseToAnyPublisher()
    }
}

 class TmpNetworkService {
    public init () {}
    
    public func request<T: Decodable>(_ endpoint: NetworkEndpoint, responseType: T.Type, completion: @escaping (Result<T, NetworkServiceError>) -> Void) {
        let request = prepareRequest(from: endpoint)
        
        requestData(request: request) { result in
            switch result {
            case .success(let data):
                if let mapped = self.map(data, type: T.self) {
                    completion(.success(mapped))
                } else {
                    completion(.failure(.mapError))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func request(_ endpoint: NetworkEndpoint, completion: @escaping (Result<Data, NetworkServiceError>) -> Void) {
        let request = prepareRequest(from: endpoint)
        requestData(request: request, completion: completion)
    }
    
    @available(iOS 13.0, *)
    public func requestPublisher(_ endpoint: NetworkEndpoint) -> AnyPublisher<Data, NetworkServiceError> {
        let request = prepareRequest(from: endpoint)
        return requestDataPublisher(request: request)
    }
    
    private func requestData(request: URLRequest, completion: @escaping (Result<Data, NetworkServiceError>) -> Void) {
        print("request to: \(request.url!)")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(NetworkServiceError.urlSessionError(error)))
                print(error.localizedDescription)
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                completion(.failure(NetworkServiceError.emptyResponse))
                return
            }
            
            guard (200 ..< 300) ~= response.statusCode else {
                completion(.failure(NetworkServiceError.statusCode(response.statusCode, String(data: data ?? Data(), encoding: .utf8))))
                return
            }
            
            guard let data = data else {
                completion(.failure(NetworkServiceError.emptyResponseData))
                return
            }
            
            print("status code: \(response.statusCode), response: \(String(data: data, encoding: .utf8) ?? "" )")
            completion(.success(data))
        }.resume()
    }
    
    @available(iOS 13.0, *)
    private func requestDataPublisher(request: URLRequest) -> AnyPublisher<Data, NetworkServiceError> {
        print("request to: \(request.url!)")
        return URLSession.shared.dataTaskPublisher(for: request)
            .subscribe(on: DispatchQueue.global())
            .tryMap { data, response -> Data in
                guard let response = response as? HTTPURLResponse else {
                    throw NetworkServiceError.emptyResponse
                }
                
                guard (200 ..< 300) ~= response.statusCode else {
                    throw NetworkServiceError.statusCode(response.statusCode, String(data: data, encoding: .utf8))
                }
                
                print("status code: \(response.statusCode), response: \(String(data: data, encoding: .utf8) ?? "" )")
                return data
            }
            .mapError { error in
                if let nse = error as? NetworkServiceError {
                    return nse
                } else {
                    return NetworkServiceError.urlSessionError(error)
                }
            }
            .eraseToAnyPublisher()
    }
    
    private func prepareRequest(from endpoint: NetworkEndpoint) -> URLRequest {
        var urlRequest = URLRequest(url: endpoint.url)
        urlRequest.httpMethod = endpoint.method
        urlRequest.httpBody = endpoint.body
        
        for header in endpoint.headers {
            urlRequest.addValue(header.key, forHTTPHeaderField: header.value)
        }
        
        return urlRequest
    }
    
    private func map<T: Decodable>(_ data: Data, type: T.Type) -> T? {
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
