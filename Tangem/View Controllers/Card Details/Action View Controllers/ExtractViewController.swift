//
//  ExtractViewController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation
import CoreNFC
import TangemKit

@available(iOS 13.0, *)
class ExtractViewController: ModalActionViewController {
    
    var card: Card!
    var onDone: (()-> Void)?
    
    @IBOutlet weak var targetText: UITextField!
    @IBOutlet weak var amountText: UITextField!
    @IBOutlet weak var feeText: UITextField!
    @IBOutlet weak var feeControl: UISegmentedControl!
    
    
    private var readerSession: NFCTagReaderSession?
    private var validatedAmount: String?
    private var validatedTarget: String?
    private var validatedFee: String?
    private var fee: (min: String, normal: String, max: String)?
    private var feeTimer: Timer?
    
    
    @IBAction func feePresetChanged(_ sender: UISegmentedControl, forEvent event: UIEvent) {
        updateFee()
    }
    
    func updateFee() {
        switch feeControl.selectedSegmentIndex {
        case 0:
            feeText.text = fee?.min ?? ""
        case 1:
            feeText.text = fee?.normal ?? ""
        case 2:
            feeText.text = fee?.max ?? ""
        default:
            feeText.text = ""
        }
    }
    
    
    @IBAction func targetChanged(_ sender: UITextField, forEvent event: UIEvent) {
        tryUpdateFeePreset()
    }
    @IBAction func amountChanged(_ sender: UITextField, forEvent event: UIEvent) {
        tryUpdateFeePreset()
    }
    
    @IBAction func scanTapped() {
        
        guard validateInput() else {
            return
        }
        
        readerSession = NFCTagReaderSession(pollingOption: .iso14443, delegate: self)
        readerSession?.alertMessage = "Hold your iPhone near a Tangem card"
        readerSession?.begin()
    }
    
    
    
    func validateInput() -> Bool {
        validatedAmount = ""
        validatedFee = ""
        validatedTarget = ""
        
        guard let amount = amountText.text,
            let target = targetText.text,
            let fee = feeText.text,
            let amountValue = Decimal(string: amount),
            let feeValue = Decimal(string: fee),
            let total = Decimal(string: card.walletValue),
            total >= amountValue + feeValue,
            targetText.text != card.walletPublicKey else {
                return false
        }
        
        validatedAmount = amount
        validatedFee = fee
        validatedTarget = target
        return true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        amountText.text = card.walletValue
    }
    
    func tryUpdateFeePreset() {
        feeTimer?.invalidate()
        
        guard let targetAddress = targetText.text,
            let amount = amountText.text,
            !targetAddress.isEmpty,
            !amount.isEmpty else {
                return
        }
        
        feeTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(0.3), repeats: false, block: { [weak self] _ in
            guard let cProvider = self?.card.cardEngine as? CoinProvider else {
                return
            }
            cProvider.getFee(targetAddress: targetAddress, amount: amount) {[weak self] fee in
                guard let self = self,
                    let fee = fee else {
                        return
                }
                self.fee = fee
                DispatchQueue.main.async {
                    self.updateFee()
                }
                print("min fee: \(fee.min) normal fee: \(fee.normal) max fee \(fee.max)")
            }
        })
    }
    
}


@available(iOS 13.0, *)
extension ExtractViewController: NFCTagReaderSessionDelegate {
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        print(error)
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        if case let .iso7816(tag7816) = tags.first {
            let nfcTag = tags.first!
            session.connect(to: nfcTag) {[unowned self] error in
                guard error == nil else {
                    session.invalidate(errorMessage: error!.localizedDescription)
                    return
                }
                
                let cProvider = self.card.cardEngine as! CoinProvider
                let hashToSign = cProvider.getHashForSignature(amount: self.validatedAmount!, fee: self.validatedFee!, includeFee: false, targetAddress: self.validatedTarget!)
                
                
                let cardId = self.card.cardID.asciiHexToData()!
                let hSize = [UInt8(hashToSign!.count)]
                
                let tlvData = [
                    CardTLV(.pin, value: "000000".sha256().asciiHexToData()),
                    CardTLV(.cardId, value: cardId),
                    CardTLV(.pin2, value: "000".sha256().asciiHexToData()),
                    CardTLV(.transactionOutHashSize, value: hSize),
                    CardTLV(.transactionOutHash, value: hashToSign?.bytes)]
                
                let commandApdu = CommandApdu(with: .sign, tlv: tlvData)
                let signApduBytes = commandApdu.buildCommand()
                let signApdu = NFCISO7816APDU(data: Data(bytes: signApduBytes))!
                self.sendSignRequest(to: tag7816, with: session, signApdu)
            }
        }
        
    }
    
    private func sendSignRequest(to tag: NFCISO7816Tag, with session: NFCTagReaderSession, _ apdu: NFCISO7816APDU) {
        tag.sendCommand(apdu: apdu) {[unowned self] (data, sw1, sw2, apduError) in
            guard apduError == nil else {
                // session.invalidate(errorMessage: apduError!.localizedDescription)
                session.alertMessage = "Hold your iPhone near a Tangem card"
                session.restartPolling()
                return
            }
            
            let respApdu = ResponseApdu(with: data, sw1: sw1, sw2: sw2)
            
            if let cardState = respApdu.state {
                switch cardState {
                case .needPause:
                    if let remainingMilliseconds = respApdu.tlv[.pause]?.intValue {
                        self.readerSession?.alertMessage = "Security delay: \(remainingMilliseconds/100) seconds"
                    }
                    
                    if respApdu.tlv[.flash] != nil {
                        self.readerSession?.restartPolling()
                        
                    } else {
                        self.sendSignRequest(to: tag, with: session, apdu)
                    }
                    
                case .processCompleted:
                    session.alertMessage = "Sign completed"
                    session.invalidate()
                    if let sign = respApdu.tlv[.signature]?.value {
                        // session.alertMessage = "Signed :)"
                        let cProvider = self.card.cardEngine as! CoinProvider
                        cProvider.sendToBlockchain(signFromCard: sign) {result in
                            if result {
                                print("Tx send successfully")
                            } else {
                                print("error")
                            }
                            DispatchQueue.main.async {
                                self.dismiss(animated: true) {
                                    self.onDone?()
                                }
                            }
                        }
                    }
                    
                //[REDACTED_TODO_COMMENT]
                default:
                    session.invalidate(errorMessage: cardState.localizedDescription)
                }
            } else {
                session.invalidate(errorMessage: "Unknown card state: \(sw1) \(sw2)")
            }
        }
    }
    
}
