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
    
    deinit {
        print("ImageLoaderService deinit")
    }
    
    func loadImage(cid: String, cardPublicKey: Data, artworkInfo: ArtworkInfo?) -> AnyPublisher<UIImage, Error> {
		let prefix = String(cid.prefix(4))
		if prefix.elementsEqual("BC01") { //Sergio
			return backedLoadImage(.sergio)
        }
        
		if prefix.elementsEqual("BC02") { //Marta
			return backedLoadImage(.marta)
        }
		
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
	
	func backedLoadImage(_ image: BackedImages) -> AnyPublisher<UIImage, Error> {
		backedLoadImage(name: image.name)
	}
}
