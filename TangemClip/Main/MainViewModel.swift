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
import TangemSdk

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
        didSet {}
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
    
    unowned var sdk: TangemSdk
    unowned var imageLoaderService: CardImageLoaderService
    unowned var userPrefsService: UserPrefsService
    unowned var assembly: Assembly
    
    init(sdk: TangemSdk, imageLoaderService: CardImageLoaderService, userPrefsService: UserPrefsService, assembly: Assembly) {
        self.sdk = sdk
        self.imageLoaderService = imageLoaderService
        self.userPrefsService = userPrefsService
        self.assembly = assembly
        updateCardBatch(nil, fullLink: "")
    }
    
    func scanCard() {
        isScanning = true
        
        let task = AppScanTask(userPrefsService: userPrefsService, targetBatch: savedBatch)
        sdk.startSession(with: task) { [weak self] (result) in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                Analytics.logScan(card: response.card)
                self.shouldShowGetFullApp = true
                
                let cm = self.assembly.makeCardModel(from: response.getCardInfo())
                let result: ScanResult = .card(model: cm)
                cm.getCardInfo()
                
                self.state = result
            case .failure(let error):
                Analytics.logCardSdkError(error, for: .scan)
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
