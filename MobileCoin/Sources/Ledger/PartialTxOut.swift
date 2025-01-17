//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin

struct PartialTxOut: TxOutProtocol {
    let commitment: Data32
    let maskedValue: UInt64
    let targetKey: RistrettoPublic
    let publicKey: RistrettoPublic
}

extension PartialTxOut: Equatable {}
extension PartialTxOut: Hashable {}

extension PartialTxOut {
    init(_ txOut: TxOut) {
        self.init(
            commitment: txOut.commitment,
            maskedValue: txOut.maskedValue,
            targetKey: txOut.targetKey,
            publicKey: txOut.publicKey)
    }
}

extension PartialTxOut {
    init?(_ txOut: External_TxOut) {
        guard let commitment = Data32(txOut.amount.commitment.data),
              let targetKey = RistrettoPublic(txOut.targetKey.data),
              let publicKey = RistrettoPublic(txOut.publicKey.data)
        else {
            return nil
        }
        self.init(
            commitment: commitment,
            maskedValue: txOut.amount.maskedValue,
            targetKey: targetKey,
            publicKey: publicKey)
    }

    init?(_ txOutRecord: FogView_TxOutRecord, viewKey: RistrettoPrivate) {
        guard let targetKey = RistrettoPublic(txOutRecord.txOutTargetKeyData),
              let publicKey = RistrettoPublic(txOutRecord.txOutPublicKeyData),
              let commitment = TxOutUtils.reconstructCommitment(
                                                    maskedValue: txOutRecord.txOutAmountMaskedValue,
                                                    publicKey: publicKey,
                                                    viewPrivateKey: viewKey),
              Self.isCrc32Matching(commitment, txOutRecord: txOutRecord)
        else {
            return nil
        }

        self.init(
            commitment: commitment,
            maskedValue: txOutRecord.txOutAmountMaskedValue,
            targetKey: targetKey,
            publicKey: publicKey)
    }

    static func isCrc32Matching(_ reconstructed: Data32, txOutRecord: FogView_TxOutRecord) -> Bool {
        let reconstructedCrc32 = reconstructed.commitmentCrc32
        let txIsSentWithCrc32 = (txOutRecord.txOutAmountCommitmentDataCrc32 != .emptyCrc32)

        // Older code may not set the crc32 value for the tx record,
        // so it must be calculated off the data of the record itself
        // until that code is deprecated.
        //
        // once it is required that crc32 be set, remove the 'else' below
        // and add a guard check for the
        if txIsSentWithCrc32 {
            return reconstructedCrc32 == txOutRecord.txOutAmountCommitmentDataCrc32
        } else {
            return reconstructedCrc32 == txOutRecord.txOutAmountCommitmentData.commitmentCrc32
        }
    }
}

