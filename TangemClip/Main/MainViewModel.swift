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
import TangemSdkClips

class MainViewModel: ObservableObject {
    
    @Published var isRefreshing: Bool = false
    @Published var isScanning: Bool = false
    @Published var image: UIImage? = nil
    @Published var isWithNdef: Bool = false
    @Published var shouldShowGetFullApp = false
    @Published var cardUrl: String? {
        didSet {
            objectWillChange.send()
        }
    }
    @Published var selectedAddressIndex: Int = 0
    @Published var state: ScanResult = .notScannedYet  {
        willSet {
            print("⚠️ Reset bag")
            image = nil
            bag = Set<AnyCancellable>()
        }
        didSet {
            bind()
        }
    }
    
    var isMultiWallet: Bool { cardModel?.isMultiWallet ?? false }
    var cardModel: CardViewModel? {
        state.cardModel
    }
    
    private var imageLoadingCancellable: AnyCancellable?
    private var bag: Set<AnyCancellable> = []
    
    private var savedBatch: String?
    
    var tokenItemViewModels: [TokenItemViewModel] {
        guard let cardModel = cardModel else { return [] }
        
        return cardModel.walletModels
            .flatMap ({ $0.tokenItemViewModels })
    }
    
    unowned var cardsRepository: CardsRepository
    unowned var imageLoaderService: ImageLoaderService
    
    init(cardsRepository: CardsRepository, imageLoaderService: ImageLoaderService) {
        self.cardsRepository = cardsRepository
        self.imageLoaderService = imageLoaderService
        updateCardBatch(nil)
    }
    
    func bind() {
        $state
            .compactMap { $0.cardModel }
            .flatMap { $0.$state }
            .compactMap { $0.walletModels }
            .flatMap { Publishers.MergeMany($0.map { $0.objectWillChange}) }
            .receive(on: RunLoop.main)
            .sink { [unowned self] _ in
                print("⚠️ Wallet model will change")
                withAnimation {
                    self.objectWillChange.send()
                }
            }
            .store(in: &bag)
        
        state.cardModel?.$cardInfo
            .flatMap { cardInfo -> AnyPublisher<UIImage?, Error> in
                let noImagePublisher = self.imageLoaderService.backedLoadImage(.default)
                
                guard let cid = cardInfo.card.cardId,
                      let pubkey = cardInfo.card.cardPublicKey
                else { return noImagePublisher }
                
                switch cardInfo.artwork {
                case .noArtwork:
                    return noImagePublisher
                case .artwork(let art):
                    return (self.imageLoaderService.loadImage(with: cid, pubkey: pubkey, for: art))
                case .notLoaded:
                    return Just(nil).setFailureType(to: Error.self).eraseToAnyPublisher()
                }
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        Analytics.log(error: error)
                        print(error.localizedDescription)
                    case .finished:
                        break
                    }}){ [unowned self] image in
                withAnimation {
                    self.image = image
                }
            }
            .store(in: &bag)
    }
    
    func scanCard() {
        isScanning = true
        cardsRepository.scan { [unowned self] (result) in
            switch result {
            case .success(let result):
                self.shouldShowGetFullApp = true
                self.state = result
            case .failure(let error):
                print(error)
            }
            self.isScanning = false
        }
    }
    
    func updateCardBatch(_ batch: String?) {
        isWithNdef = batch != nil
        savedBatch = batch
        state = .notScannedYet
        shouldShowGetFullApp = false
        loadImageByBatch(batch)
    }
    
    private func loadImageByBatch(_ batch: String?) {
        guard let batch = batch else {
            image = nil
            return
        }
        
        imageLoadingCancellable = imageLoaderService
            .loadImage(batch: batch)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                print(completion)
            }, receiveValue: { [weak self] image in
                withAnimation {
                    self?.image = image
                }
            })
    }
    
}
