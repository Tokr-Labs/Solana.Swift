//
//  SolanaPay.swift
//  
//
//  Created by Arturo Jamaica on 2022/02/20.
//

import Foundation
let PROTOCOL = "solana"
public enum SolanaPayError: Error {
    case recipientNotProvided
    case invalidAmmount
    case unsupportedProtocol
    case canNotParse
    case couldNotDecodeURL
    case other(Error)
}
public class SolanaPay {
    public func getSolanaPayURL(
        recipient: String,
        uiAmountString: String,
        label: String? = nil,
        message: String? = nil,
        memo: String? = nil,
        reference: String? = nil,
        splToken: String? = nil
    ) -> Result<URL, SolanaPayError> {
        var solanaPayURL = "\(PROTOCOL):\(recipient)?amount=\(uiAmountString)"
        if let label = label {
            solanaPayURL += "&label=\(label)"
        }
        if let message = message {
            solanaPayURL += "&message=\(message)"
        }
        if let memo = memo {
            solanaPayURL += "&memo=\(memo)"
        }
        if let reference = reference {
            solanaPayURL += "&reference=\(reference)"
        }
        if let splToken = splToken {
            solanaPayURL += "&spl-token=\(splToken)"
        }
        do{
            guard let url = URL(string: solanaPayURL) else {
                throw SolanaPayError.couldNotDecodeURL
            }
            return .success(url)
        } catch SolanaPayError.couldNotDecodeURL {
            return .failure(SolanaPayError.couldNotDecodeURL)
        } catch let e {
            return .failure(SolanaPayError.other(e))
        }
    }
    
    public func parseSolanaPay(urlString: String) -> Result<SolanaPaySpecification, SolanaPayError> {
        
        
        let decodedString = urlString.removingPercentEncoding
        
        guard decodedString?.hasPrefix("solana:") == true else {
            return .failure(SolanaPayError.unsupportedProtocol)
        }
        
        let sanatizedString = decodedString?.replacingOccurrences(of: "solana:", with: "")
        guard let components = URLComponents(string: sanatizedString ?? "") else {
            return .failure(SolanaPayError.canNotParse)
        }

        guard let address = getParamURL(components: components, name: "recipient"), let recipient = PublicKey(string: address)  else {
            return .failure(SolanaPayError.recipientNotProvided)
        }

        var doubleAmount: Double? = nil
        var splTokenPubKey: PublicKey? = nil
        if let amount: String = getParamURL(components: components, name: "amount") {
            let parsedAmount = Double(amount) ?? -1
            if parsedAmount < 0 {
                return .failure(SolanaPayError.invalidAmmount)
            }
            doubleAmount = parsedAmount
        }
        
        let label: String? = getParamURL(components: components, name: "label")?.replacingOccurrences(of: "+", with: " ")
        let message: String? = getParamURL(components: components, name: "message")
        let memo: String? = getParamURL(components: components, name: "memo")
        let reference: String? = getParamURL(components: components, name: "reference")
        if let splToken: String = getParamURL(components: components, name: "spl-token") {
            splTokenPubKey = PublicKey(string: splToken) ?? nil
        }
        
        let spec = SolanaPaySpecification(recipient: recipient, label: label, splToken: splTokenPubKey, message: message, memo: memo, reference: reference, amount: doubleAmount)
        return .success(spec)
    }
    
    private func getParamURL(components: URLComponents, name: String) -> String? {
        return components.queryItems?.first(where: { $0.name == name })?.value
    }
}

public struct SolanaPaySpecification {
    public let recipient: PublicKey
    public let label: String?
    public let splToken: PublicKey?
    public let message: String?
    public let memo: String?
    public let reference: String?
    public let amount: Double?
}
