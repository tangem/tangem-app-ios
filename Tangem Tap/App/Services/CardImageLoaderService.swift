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
		case twinCardOne, twinCardTwo
		
		var name: String {
			switch self {
			case .twinCardOne: return "card_tg085"
			case .twinCardTwo: return "card_tg086"
			}
		}
	}
	
    let networkService: NetworkService
    
    private var defaultImage: UIImage { .init(named: "dark_card")! }
    
    init(networkService: NetworkService) {
        self.networkService = networkService
    }
    
    deinit {
        print("ImageLoaderService deinit")
    }
    
    func loadImage(cid: String, cardPublicKey: Data, artworkInfo: ArtworkInfo?) -> AnyPublisher<UIImage, Never> {
		let prefix = String(cid.prefix(4))
		
		if let series = TwinCardSeries.allCases.first(where: { prefix.elementsEqual($0.rawValue.uppercased()) }) {
			return loadImage(series.number == 1 ? .twinCardOne : .twinCardTwo)
		}
        
        guard let artworkId = artworkInfo?.id else {
			return Just(defaultImage).eraseToAnyPublisher()
        }
        
        let endpoint = TangemEndpoint.artwork(cid: cid,
                                              cardPublicKey: cardPublicKey,
                                              artworkId: artworkId)
        
        return loadImage(at: endpoint)
    }
    
    func loadImage(batch: String) -> AnyPublisher<UIImage, Never> {
        if batch.isEmpty {
            return Just(defaultImage).eraseToAnyPublisher()
        }

        return loadImage(at: GithubEndpoint.byBatch(batch))
    }

    func loadImage(byNdefLink link: String) -> AnyPublisher<UIImage, Never> {
        guard let url = URL(string: link) else {
            return Just(defaultImage).eraseToAnyPublisher()
        }

        return loadImage(at: GithubEndpoint.byNdefLink(url))
    }
    
    func loadImage(_ image: BackedImages) -> AnyPublisher<UIImage, Never> {
        backedLoadImage(name: image.name)
    }
    
    private func loadImage(at endpoint: NetworkEndpoint) -> AnyPublisher<UIImage, Never> {
        return networkService
            .requestPublisher(endpoint)
            .subscribe(on: DispatchQueue.global())
            .tryMap { data -> UIImage in
                if let image = UIImage(data: data) {
                    return image
                }
                
                throw "Image mapping failed"
            }
            .replaceError(with: defaultImage)
            .eraseToAnyPublisher()
    }
    
    private func backedLoadImage(name: String) -> AnyPublisher<UIImage, Never> {
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
            }
            .replaceError(with: defaultImage)
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
    }
}
