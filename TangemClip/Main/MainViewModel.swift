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
    
    @Published var isScanning: Bool = false
    @Published var image: UIImage? = nil
    @Published var shouldShowGetFullApp = false
    @Published var state: ScanResult = .notScannedYet  {
        willSet {
            print("⚠️ Reset bag")
            if newValue == .notScannedYet {
                image = nil
            }
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
    
    var isCardEmpty: Bool {
        state.cardModel?.isCardEmpty ?? true
    }
    
    private var imageLoadingCancellable: AnyCancellable?
    private var bag: Set<AnyCancellable> = []
    
    private var savedBatch: String?
    
    var tokenItemViewModels: [TokenItemViewModel] {
        guard let cardModel = cardModel else { return [] }
        
        return cardModel.walletModels
            .flatMap { $0.tokenItemViewModels }
    }
    
    unowned var cardsRepository: CardsRepository
    unowned var imageLoaderService: CardImageLoaderService
    
    init(cardsRepository: CardsRepository, imageLoaderService: CardImageLoaderService) {
        self.cardsRepository = cardsRepository
        self.imageLoaderService = imageLoaderService
        updateCardBatch(nil, fullLink: "")
    }
    
    func bind() {
        $state
            .compactMap { $0.cardModel }
            .flatMap { $0.$state }
            .compactMap { $0.walletModels }
            .flatMap { Publishers.MergeMany($0.map { $0.objectWillChange}) }
            .receive(on: RunLoop.main)
            .sink { [unowned self] _ in
//                print("⚠️ Wallet model will change")
                withAnimation {
                    self.objectWillChange.send()
                }
            }
            .store(in: &bag)
    }
    
    func scanCard() {
        isScanning = true
        cardsRepository.scan(with: savedBatch) { [unowned self] (result) in
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
    
    func updateCardBatch(_ batch: String?, fullLink: String) {
        savedBatch = batch
        state = .notScannedYet
      //  shouldShowGetFullApp = false
        loadImageByBatch(batch, fullLink: fullLink)
    }
    
    func onAppear() {
        DispatchQueue.main.async {
            self.shouldShowGetFullApp = true
        }
    }
    
    private func loadImageByBatch(_ batch: String?, fullLink: String) {
        guard let _ = batch, !fullLink.isEmpty else {
            image = nil
            return
        }
        
        imageLoadingCancellable = imageLoaderService
            .loadImage(byNdefLink: fullLink)
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
