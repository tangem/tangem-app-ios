//
//  CardImageLoader.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk

class CardImageLoader {
    private var networkService: NetworkService = .init()

    private var cacheConfiguration: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 30
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        return configuration
    }

    init() {}

    deinit {
        print("ImageLoaderService deinit")
    }

    private func loadImage(batch: String) -> AnyPublisher<UIImage, Error> {
        networkService = .init()

        return Just(batch)
            .replaceEmptyString(with: ImageError.nothingToLoad)
            .flatMap { self.loadImage(at: GithubEndpoint.byBatch($0)) }
            .eraseToAnyPublisher()
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

extension CardImageLoader {
    enum GithubEndpoint: NetworkEndpoint {
        case byBatch(String)
        case byNdefLink(URL)

        var baseUrl: String {
            return "https://raw.githubusercontent.com/tangem/ndef-registry/main/"
        }

        var path: String {
            switch self {
            case .byBatch(let batch):
                return "\(batch)/\(imageSuffix)"
            case .byNdefLink(let link):
                return "\(link)/\(imageSuffix)"
            }
        }

        var queryItems: [URLQueryItem]? { return nil }

        var method: String {
            switch self {
            case .byBatch, .byNdefLink:
                return "GET"
            }
        }

        var body: Data? { nil }

        var headers: [String: String] {
            ["Content-Type": "application/json"]
        }

        var configuration: URLSessionConfiguration? {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 10
            configuration.timeoutIntervalForResource = 30
            return configuration
        }

        private var imageSuffix: String { "card.png" }
    }
}

extension CardImageLoader: CardImageLoaderProtocol {
    func loadImage(cid: String, cardPublicKey: Data, artworkInfoId: String) -> AnyPublisher<UIImage, Error> {
        let endpoint = TangemEndpoint.artwork(cid: cid,
                                              cardPublicKey: cardPublicKey,
                                              artworkId: artworkInfoId)
        networkService = .init(configuration: cacheConfiguration)

        return loadImage(at: endpoint)
    }

    func loadTwinImage(for number: Int) -> AnyPublisher<UIImage, Error> {
        let image: ConstantImage = number == 1 ? .twinCardOne : .twinCardTwo
        return loadImage(by: image.rawValue)
    }

    func loadImage(byNdefLink link: String) -> AnyPublisher<UIImage, Error> {
        networkService = .init()

        return Just(link)
            .map { URL(string: $0) }
            .replaceNil(with: ImageError.badNdef)
            .flatMap { self.loadImage(at: GithubEndpoint.byNdefLink($0)) }
            .eraseToAnyPublisher()
    }
}

fileprivate extension CardImageLoader {
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

// can't move it out from here due to compile error
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
