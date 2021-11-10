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

typealias ImageResponse = (image: UIImage, canBeCached: Bool)

class CardImageLoaderService {
    private var networkService: NetworkService = .init()
    private var defaultImage: UIImage { .init(named: "dark_card")! }
    
    private var cacheConfiguration: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 30
        configuration.requestCachePolicy = .returnCacheDataDontLoad
        return configuration
    }
    
    init() {}
    
    deinit {
        print("ImageLoaderService deinit")
    }
    
    func loadImage(cid: String, cardPublicKey: Data, artworkInfo: ArtworkInfo?) -> AnyPublisher<ImageResponse, Never> {
        let prefix = String(cid.prefix(4))
        
        if let series = TwinCardSeries.allCases.first(where: { prefix.elementsEqual($0.rawValue.uppercased()) }) {
            return loadImage(image: series.number == 1 ? .twinCardOne : .twinCardTwo)
                .map { ($0, true) }
                .replaceError(with: (defaultImage, false))
                .eraseToAnyPublisher()
        }
        
        guard let artworkId = artworkInfo?.id else {
            return Just((defaultImage, false)).eraseToAnyPublisher()
        }
        
        let endpoint = TangemEndpoint.artwork(cid: cid,
                                              cardPublicKey: cardPublicKey,
                                              artworkId: artworkId)
        
        networkService = .init(configuration: cacheConfiguration)
        
        return loadImage(at: endpoint)
            .map { ($0, true) }
            .replaceError(with: (defaultImage, false))
            .eraseToAnyPublisher()
    }
    
    func loadImage(byNdefLink link: String) -> AnyPublisher<UIImage, Never> {
        networkService = .init()
        
        return Just(link)
            .map { URL(string: $0) }
            .replaceNil(with: ImageError.badNdef)
            .flatMap { self.loadImage(at: GithubEndpoint.byNdefLink($0)) }
            .replaceError(with: defaultImage)
            .eraseToAnyPublisher()
    }
    
    func loadImage(_ image: ConstantImage) -> AnyPublisher<UIImage, Never> {
        loadImage(image: image)
            .replaceError(with: defaultImage)
            .eraseToAnyPublisher()
    }
    
    func loadImage(batch: String) -> AnyPublisher<UIImage, Never> {
        networkService = .init()
        
        return Just(batch)
            .replaceEmptyString(with: ImageError.nothingToLoad)
            .flatMap { self.loadImage(at: GithubEndpoint.byBatch($0)) }
            .replaceError(with: defaultImage)
            .eraseToAnyPublisher()
    }
    
    private func loadImage(image: ConstantImage) -> AnyPublisher<UIImage, Error> {
        loadImage(by: image.rawValue)
    }
    
    private func loadImage(at endpoint: NetworkEndpoint) -> AnyPublisher<UIImage, Error> {
        return networkService
            .requestPublisher(endpoint)
            .subscribe(on: DispatchQueue.global())
            .map { UIImage(data: $0) }
            .replaceNil(with: ImageError.mapFailed)
            .eraseToAnyPublisher()
    }
    
    private func loadImage(by name: String) -> AnyPublisher<UIImage, Error> {
        return URLSession(configuration: cacheConfiguration)
            .dataTaskPublisher(for: URL(string: "https://app.tangem.com/cards/\(name).png")!)
            .subscribe(on: DispatchQueue.global())
            .map { UIImage(data: $0.0) }
            .replaceNil(with: ImageError.mapFailed)
            .eraseToAnyPublisher()
    }
}

extension CardImageLoaderService {
    enum GithubEndpoint: NetworkEndpoint {
        case byBatch(String)
        case byNdefLink(URL)
        
        private var baseURL: URL {
            URL(string: "https://raw.githubusercontent.com/tangem/ndef-registry/main")!
        }
        
        private var imageSuffix: String { "card.png" }
        
        var url: URL {
            switch self {
            case .byBatch(let batch):
                let url = baseURL.appendingPathComponent(batch)
                    .appendingPathComponent(imageSuffix)
                return url
            case .byNdefLink(let link):
                let url = link.appendingPathComponent(imageSuffix)
                return url
            }
        }
        
        var method: String {
            switch self {
            case .byBatch, .byNdefLink:
                return "GET"
            }
        }
        
        var body: Data? {
            nil
        }
        
        var headers: [String : String] {
            ["application/json" : "Content-Type"]
        }
        
        var configuration: URLSessionConfiguration? {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 10
            configuration.timeoutIntervalForResource = 30
            return configuration
        }
    }
}
extension CardImageLoaderService {
    enum ConstantImage: String {
        case twinCardOne = "card_tg085"
        case twinCardTwo = "card_tg086"
    }
}

fileprivate enum ImageError: Error {
    case nothingToLoad
    case mapFailed
    case badNdef
}


extension Publisher where Output == String {
    func replaceEmptyString(with error: Error) -> AnyPublisher<String, Error> {
        tryMap { string -> String in
            if string.isEmpty {
                throw error
            }
            
            return string
        }
        .eraseToAnyPublisher()
    }
}

extension Publisher {
    public func replaceNil<T>(with error: Error) -> Publishers.TryMap<Self, T> where Self.Output == T? {
        tryMap { output -> T in
            if let output = output {
                return output
            }
            
            throw error
        }
    }
}
