//
//  MainViewModel.swift
//  TangemClip
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

class MainViewModel: ObservableObject {
    
    @Published var isRefreshing: Bool = false
    @Published var isScanning: Bool = false
    @Published var image: UIImage? = nil
    @Published var isWithNdef: Bool = false
    @Published var cardUrl: String? {
        didSet {
            objectWillChange.send()
        }
    }
    
    var isMultiWallet: Bool { false }
    
    private var imageLoadingCancellable: AnyCancellable?
    
    let defaults: UserDefaults = UserDefaults(suiteName: "group.com.tangem.Tangem") ?? .standard
    unowned var cardsRepository: CardsRepository
    unowned var imageLoaderService: ImageLoaderService
    
    init(cardsRepository: CardsRepository, imageLoaderService: ImageLoaderService) {
        self.cardsRepository = cardsRepository
        self.imageLoaderService = imageLoaderService
        updateCardBatch(nil)
    }
    
    func bind() {
        
    }
    
    func scanCard() {
        cardsRepository.scan { (result) in
            switch result {
            case .success(let result):
                break
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func updateCardBatch(_ batch: String?) {
        isWithNdef = batch != nil
        imageLoadingCancellable = imageLoaderService
            .loadImage(batch: batch)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                print(completion)
            }, receiveValue: { [weak self] in
                self?.image = $0
            })
    }
    
}
