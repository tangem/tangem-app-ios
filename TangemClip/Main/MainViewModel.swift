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
    @Published var cardUrl: String? {
        didSet {
            objectWillChange.send()
        }
    }
    @Published var selectedAddressIndex: Int = 0
    @Published var state: ScanResult = .unsupported  {
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
    
    var tokenItemViewModels: [TokenItemViewModel] {
        guard let cardModel = cardModel else { return [] }
        
        return cardModel.walletModels
            .flatMap ({ $0.tokenItemViewModels })
    }
    
    let defaults: UserDefaults = UserDefaults(suiteName: "group.com.tangem.Tangem") ?? .standard
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
                self.objectWillChange.send()
            }
            .store(in: &bag)
        
        state.cardModel?.$cardInfo
            .tryMap { cardInfo -> (String, Data, ArtworkInfo?) in
                if let cid = cardInfo.card.cardId,
                   let pubkey = cardInfo.card.cardPublicKey {
                    return (cid, pubkey, cardInfo.artworkInfo)
                }
                
                throw "Some error"
            }
            .flatMap { [unowned self] (info: (String, Data, ArtworkInfo?)) -> AnyPublisher<UIImage, Error> in
                guard let artwork: ArtworkInfo = info.2 else {
                    return self.imageLoaderService
                        .loadImage(batch: String(info.0.prefix(4)))
                }
                return self.imageLoaderService.loadImage(with: info.0, pubkey: info.1, for: artwork)
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
                self.image = image
            }
            .store(in: &bag)
    }
    
    func scanCard() {
        cardsRepository.scan { (result) in
            switch result {
            case .success(let result):
                self.state = result
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
