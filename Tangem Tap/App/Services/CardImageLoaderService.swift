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

class CardImageLoaderService {
	enum BackedImages {
		case `default`, twinCardOne, twinCardTwo
		
		var name: String {
			switch self {
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
    
    deinit {
        print("ImageLoaderService deinit")
    }
    
    func loadImage(cid: String, cardPublicKey: Data, artworkInfo: ArtworkInfo?) -> AnyPublisher<UIImage, Error> {
		let prefix = String(cid.prefix(4))
		
		if let series = TwinCardSeries.allCases.first(where: { prefix.elementsEqual($0.rawValue.uppercased()) }) {
			return backedLoadImage(series.number == 1 ? .twinCardOne : .twinCardTwo)
		}
        
        guard let artworkId = artworkInfo?.id else {
			return backedLoadImage(.default)
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
                
				return self.backedLoadImage(name: BackedImages.default.name)
            }
            .eraseToAnyPublisher()
    }
    
    func backedLoadImage(name: String) -> AnyPublisher<UIImage, Error> {
        return Just(UIImage(named: "dark_card")!)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
//
//
//        let configuration = URLSessionConfiguration.default
//        configuration.requestCachePolicy = .returnCacheDataElseLoad
//        let session = URLSession(configuration: configuration)
//        return session
//            .dataTaskPublisher(for: URL(string: "https://app.tangem.com/cards/\(name).png")!)
//            .subscribe(on: DispatchQueue.global())
//            .tryMap { data, response -> UIImage in
//                if let image = UIImage(data: data) {
//                    return image
//                }
//
//                throw "Image mapping failed"
//            }.eraseToAnyPublisher()
    }
	
	func backedLoadImage(_ image: BackedImages) -> AnyPublisher<UIImage, Error> {
		backedLoadImage(name: image.name)
	}
}


extension CardImageLoaderService {
    enum ImageEndpoint: NetworkEndpoint {
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

    }
    
    func loadImage(batch: String) -> AnyPublisher<UIImage, Error> {
        if batch.isEmpty {
            return backedLoadImage(.default)
        }

        let endpoint = ImageEndpoint.byBatch(batch)

        return publisher(for: endpoint)
    }

    func loadImage(byNdefLink link: String) -> AnyPublisher<UIImage, Error> {
        guard let url = URL(string: link) else {
            return backedLoadImage(.default)
        }

        return publisher(for: ImageEndpoint.byNdefLink(url))
    }
    
    private func publisher(for endpoint: NetworkEndpoint) -> AnyPublisher<UIImage, Error> {
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

                return self.backedLoadImage(name: BackedImages.default.name)
            }
            .eraseToAnyPublisher()
    }
}
