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
    let networkService: NetworkService
    private let defaultImageName = "card_default"
    
    init(networkService: NetworkService) {
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
