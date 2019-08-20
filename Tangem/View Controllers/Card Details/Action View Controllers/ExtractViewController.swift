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
    
    @IBOutlet weak var amountText: UITextField! {
        didSet {
            amountText.delegate = self
        }
    }
    @IBOutlet weak var topStackView: UIStackView!
    @IBOutlet weak var targetStackView: UIStackView!
    @IBOutlet weak var feeControl: UISegmentedControl!
    @IBOutlet weak var cardLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var targetAddressText: UITextField! {
        didSet {
            targetAddressText.delegate = self
        }
    }
    @IBOutlet weak var pasteTargetAddressContainer: UIStackView!
    @IBOutlet weak var pasteTargetAddressLabel: UILabel!
    @IBOutlet weak var includeFeeSwitch: UISwitch!
    @IBOutlet weak var feeLabel: UILabel!
    @IBOutlet weak var pasteTargetAdressButton: UIButton!
    @IBOutlet weak var btnSend: UIButton!
    @IBOutlet weak var cardInfoContainer: UIStackView!
    
    private var readerSession: NFCTagReaderSession?
    private var validatedAmount: String?
    private var validatedTarget: String?
    private var validatedFee: String?
    private var bgLayer = CALayer()
    private var pasteLayer = CALayer()
    private var triangleLayer = CAShapeLayer()
    private var feeTimer: Timer?
    private var feeTime = Date(timeIntervalSince1970: TimeInterval(1.0))
    
    
    private var fee: (min: String, normal: String, max: String)? {
        didSet {
            feeTime = Date()
        }
    }
    
    @IBAction func feePresetChanged(_ sender: UISegmentedControl, forEvent event: UIEvent) {
        updateFee()
    }
    @IBAction func pasteTapped(_ sender: Any, forEvent event: UIEvent) {
        targetAddressText.text = pasteTargetAddressLabel.text
        hidePasteboardIfNeeded()
    }
    
    @IBAction func targetChanged(_ sender: UITextField, forEvent event: UIEvent) {
        tryUpdateFeePreset()
        hidePasteboardIfNeeded()
    }
    @IBAction func amountChanged(_ sender: UITextField, forEvent event: UIEvent) {
        tryUpdateFeePreset()
    }
    
    @IBAction func scanTapped() {
        guard feeTime.distance(to: Date()) < TimeInterval(60.0) else {
            tryUpdateFeePreset()
            return
        }
        
        guard validateInput() else {
            return
        }
        btnSend.showActivityIndicator()
        readerSession = NFCTagReaderSession(pollingOption: .iso14443, delegate: self)
        readerSession?.alertMessage = "Hold your iPhone near a Tangem card"
        readerSession?.begin()
    }
    
    func updateFee() {
        switch feeControl.selectedSegmentIndex {
        case 0:
            feeLabel.text = fee?.min ?? ""
        case 1:
            feeLabel.text = fee?.normal ?? ""
        case 2:
            feeLabel.text = fee?.max ?? ""
        default:
            feeLabel.text = ""
        }
        
        if !feeLabel.text!.isEmpty {
            feeLabel.text! += " \(card.walletUnits)"
        } else {
            feeLabel.text = Constants.feeStub
        }
        
        feeLabel.hideActivityIndicator()
        print("min fee: \(fee?.min) normal fee: \(fee?.normal) max fee \(fee?.max)")
    }
    
    func validateInput(skipFee: Bool = false) -> Bool {
        validatedAmount = ""
        validatedFee = ""
        validatedTarget = ""
        
        guard let amount = amountText.text,
            let target = targetAddressText.text,
            !target.isEmpty,
            
            !amount.isEmpty,
            let amountValue = Decimal(string: amount),
            let total = Decimal(string: card.walletValue),
            target != card.cardEngine.walletAddress else {
                return false
        }
        
        if !skipFee {
            guard let fee = feeLabel.text?.remove(" \(card.walletUnits)"),
                let feeValue = Decimal(string: fee),
                !fee.isEmpty else {
                    return false
            }
            
            let valueToSend = includeFeeSwitch.isOn ? amountValue : amountValue + feeValue
            guard total >= valueToSend else {
                return false
            }
            validatedFee = fee
        }
        
        validatedAmount = amount
        validatedTarget = target
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        btnSend.layer.cornerRadius = 8.0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let cardText = NSMutableAttributedString(string: "Card: \(card.cardID)")
        cardText.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.black, range: NSRange(location: 0, length: 5))
        
        cardLabel.attributedText = cardText
        amountLabel.text = "\(card.walletValue) \(card.cardEngine.walletUnits)"
        
        
        let addressText = NSMutableAttributedString(string: "Address: \(card.address)")
        addressText.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.black, range: NSRange(location: 0, length: 8))
        
        addressLabel.attributedText = addressText
        if let pasteString = UIPasteboard.general.string,
            (card.cardEngine as! CoinProvider).validate(address: pasteString) {
            pasteTargetAddressLabel.text = pasteString
            pasteTargetAddressContainer.isHidden = false
        }
        feeLabel.text = Constants.feeStub
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        addBgLayers()
    }
    
    
    private func addBgLayers(){
        
        let color = UIColor.init(red: 244.0/255.0, green: 244.0/255.0, blue: 244.0/255.0, alpha: 1.0).cgColor
        let padding = CGFloat(8.0)
        
        
        bgLayer.backgroundColor = color
        let converted = topStackView.convert(cardInfoContainer.frame, to: view)
        bgLayer.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: converted.height + converted.minY + padding)
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: view.center.x-40, y: converted.maxY + padding))
        path.addLine(to: CGPoint(x: view.center.x+40, y: converted.maxY + padding))
        path.addLine(to: CGPoint(x: view.center.x, y: converted.maxY + 10 + padding))
        path.close()
        triangleLayer.fillColor = color
        triangleLayer.path = path.cgPath
        
        let convertedPasteFrame =  topStackView.convert(targetStackView.convert(pasteTargetAddressContainer.frame, to: topStackView), to: view)
        pasteLayer.frame = CGRect(x: 0, y: convertedPasteFrame.minY, width: view.frame.width, height: convertedPasteFrame.height)
        pasteLayer.backgroundColor = color
        
        if bgLayer.superlayer == nil {
            view.layer.insertSublayer(triangleLayer, at: 0)
            view.layer.insertSublayer(bgLayer, at: 0)
            view.layer.insertSublayer(pasteLayer, at: 0)
        }
        
        bgLayer.setNeedsLayout()
        triangleLayer.setNeedsLayout()
        pasteLayer.setNeedsLayout()
    }
    
    func hidePasteboardIfNeeded() {
        if pasteTargetAddressContainer.alpha == CGFloat(1.0) {
            UIView.animate(withDuration: 0.2) {
                self.pasteTargetAddressContainer.isHidden = true
                self.pasteLayer.isHidden = true
            }
        }
    }
    
    func tryUpdateFeePreset() {
        feeLabel.showActivityIndicator()
        feeTimer?.invalidate()
        
        guard let targetAddress = targetAddressText.text,
            let amount = amountText.text,
            validateInput(skipFee: true) else {
                fee = nil
                updateFee()
                return
        }
        
        feeTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(0.3), repeats: false, block: { [weak self] _ in
            guard let cProvider = self?.card.cardEngine as? CoinProvider else {
                DispatchQueue.main.async {
                    self?.updateFee()
                }
                return
            }
            cProvider.getFee(targetAddress: targetAddress, amount: amount) {[weak self] fee in
                self?.fee = fee
                DispatchQueue.main.async {
                    self?.updateFee()
                }
            }
        })
    }
    
    private func setError(_ error: Bool, for textField: UITextField) {
        textField.layer.borderColor = error ? UIColor.red.cgColor : UIColor.clear.cgColor
        textField.layer.borderWidth = error ? 1.0 : 0.0
        textField.layer.cornerRadius = error ? 8.0 : 0.0
        textField.textColor = error ? UIColor.red : UIColor.black
    }
}


@available(iOS 13.0, *)
extension ExtractViewController: NFCTagReaderSessionDelegate {
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        guard session.alertMessage != "Sign completed" else {
            return
        }
        
        DispatchQueue.main.async {
            self.btnSend.hideActivityIndicator()
        }
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
                let hashToSign = cProvider.getHashForSignature(amount: self.validatedAmount!, fee: self.validatedFee!, includeFee: self.includeFeeSwitch.isOn, targetAddress: self.validatedTarget!)
                
                
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
                        cProvider.sendToBlockchain(signFromCard: sign) {[weak self] result in
                            self?.btnSend.hideActivityIndicator()
                            if result {
                                DispatchQueue.main.async {
                                    self?.dismiss(animated: true) {
                                        self?.onDone?()
                                    }
                                }
                            } else {
                                self?.handleTXSendError()
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

@available(iOS 13.0, *)
extension ExtractViewController: DefaultErrorAlertsCapable {
    
}


@available(iOS 13.0, *)
extension ExtractViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}


//MARK: Constants
@available(iOS 13.0, *)
extension ExtractViewController {
    struct Constants {
        static let feeStub = "Specify amount and address to see the fee"
    }
}
