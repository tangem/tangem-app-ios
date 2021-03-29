//
//  ImageLoaderService.swift
//  TangemClip
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import UIKit
import TangemSdkClips

class ImageLoaderService {
    enum ImageEndpoint: NetworkEndpoint {
        case byBatch(String)
        
        private var baseURL: URL {
            URL(string: "https://app.tangem.com/")!
        }
        
        var url: URL {
            switch self {
            case .byBatch(let batch):
                var url = baseURL.appendingPathComponent("cards")
                url.appendPathComponent("card_tg" + batch + ".png")
                return url
            }
        }
        
        var method: String {
            switch self {
            case .byBatch:
                return "GET"
            }
        }
        
        var body: Data? {
            nil
        }
        
        var headers: [String : String] {
            ["application/json" : "Content-Type"]
        }
        
    }
    
    enum BackedImages {
        case sergio, marta, `default`, twinCardOne, twinCardTwo
        
        var name: String {
            switch self {
            case .sergio: return "card_tg059"
            case .marta: return "card_tg083"
            case .default: return "card_default"
            case .twinCardOne: return "card_tg085"
            case .twinCardTwo: return "card_tg086"
            }
        }
    }
    
    let networkService: NetworkService
    
    init(networkService: NetworkService) {
        self.networkService = networkService
    }
    
    func loadImage(with cid: String, pubkey: Data, for artworkInfo: ArtworkInfo) -> AnyPublisher<UIImage?, Error> {
        let endpoint = TangemEndpoint.artwork(cid: cid, cardPublicKey: pubkey, artworkId: artworkInfo.id)
        return publisher(for: endpoint)
    }
    
    func loadImage(batch: String) -> AnyPublisher<UIImage?, Error> {
        let endpoint = ImageEndpoint.byBatch(batch)
        
        return publisher(for: endpoint)
    }
    
    func backedLoadImage(name: String) -> AnyPublisher<UIImage?, Error> {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        let session = URLSession(configuration: configuration)
        return session
            .dataTaskPublisher(for: URL(string: "https://app.tangem.com/cards/\(name).png")!)
            .subscribe(on: DispatchQueue.global())
            .tryMap { data, response -> UIImage? in
                if let image = UIImage(data: data) {
                    return image
                }
                
                return nil
            }.eraseToAnyPublisher()
    }
    
    func backedLoadImage(_ image: BackedImages) -> AnyPublisher<UIImage?, Error> {
        backedLoadImage(name: image.name)
    }
    
    private func publisher(for endpoint: NetworkEndpoint) -> AnyPublisher<UIImage?, Error> {
        return networkService
            .requestPublisher(endpoint)
            .subscribe(on: DispatchQueue.global())
            .tryMap { data -> UIImage? in
                if let image = UIImage(data: data) {
                    return image
                }
                
                return nil
            }
            .tryCatch {[weak self] error -> AnyPublisher<UIImage?, Error> in
                guard let self = self else {
                    throw error
                }
                
                return self.backedLoadImage(name: BackedImages.default.name)
            }
            .eraseToAnyPublisher()
    }
}
