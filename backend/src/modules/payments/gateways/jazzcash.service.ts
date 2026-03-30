import { Injectable, Logger, BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';
import * as crypto from 'crypto';

export interface JazzCashPaymentRequest {
  mobileNumber: string;   // Customer's JazzCash number e.g. 03001234567
  amount: number;          // PKR amount (we convert to paisas)
  txnRefNo: string;        // Unique reference from our system
  description: string;
  billReference: string;   // Our booking/payment ID
}

export interface JazzCashPaymentResult {
  success: boolean;
  transactionReference: string;
  responseCode: string;
  responseMessage: string;
  raw: Record<string, any>;
}

@Injectable()
export class JazzCashService {
  private readonly logger = new Logger(JazzCashService.name);

  constructor(private config: ConfigService) {}

  // ─── Initiate Mobile Wallet Payment ──────────────────────────────────────────
  // JazzCash MWALLET API — debits customer's JazzCash account

  async initiatePayment(req: JazzCashPaymentRequest): Promise<JazzCashPaymentResult> {
    const merchantId = this.config.get<string>('jazzcash.merchantId');
    const password = this.config.get<string>('jazzcash.password');
    const integritySalt = this.config.get<string>('jazzcash.integritySalt');
    const apiUrl = this.config.get<string>('jazzcash.apiUrl');

    const txnDateTime = this.getTxnDateTime();
    const txnExpiryDateTime = this.getTxnExpiryDateTime();
    const amountPaisas = String(Math.round(req.amount * 100)); // PKR → paisas

    const payload: Record<string, string> = {
      pp_Version: '1.1',
      pp_TxnType: 'MWALLET',
      pp_Language: 'EN',
      pp_MerchantID: merchantId!,
      pp_SubMerchantID: '',
      pp_Password: password!,
      pp_BankID: 'TBANK',
      pp_ProductID: 'RETL',
      pp_TxnRefNo: req.txnRefNo,
      pp_Amount: amountPaisas,
      pp_TxnCurrency: 'PKR',
      pp_TxnDateTime: txnDateTime,
      pp_BillReference: req.billReference,
      pp_Description: req.description,
      pp_TxnExpiryDateTime: txnExpiryDateTime,
      pp_SecureHash: '',
      ppmpf_1: req.mobileNumber,
      ppmpf_2: '',
      ppmpf_3: '',
      ppmpf_4: '',
      ppmpf_5: '',
    };

    // Generate HMAC-SHA256 secure hash
    payload.pp_SecureHash = this.generateSecureHash(payload, integritySalt!);

    try {
      const response = await axios.post(
        `${apiUrl}/DoMWalletTransaction`,
        payload,
        { headers: { 'Content-Type': 'application/json' }, timeout: 30000 },
      );

      const data = response.data;
      const success = data.pp_ResponseCode === '000';

      this.logger.log(
        `JazzCash [${req.txnRefNo}]: ${data.pp_ResponseCode} — ${data.pp_ResponseMessage}`,
      );

      return {
        success,
        transactionReference: data.pp_TxnRefNo || req.txnRefNo,
        responseCode: data.pp_ResponseCode,
        responseMessage: data.pp_ResponseMessage,
        raw: data,
      };
    } catch (error) {
      this.logger.error('JazzCash API error', error);
      throw new BadRequestException('Payment gateway error. Please try again.');
    }
  }

  // ─── Inquiry (check payment status) ──────────────────────────────────────────

  async inquirePayment(txnRefNo: string): Promise<JazzCashPaymentResult> {
    const merchantId = this.config.get<string>('jazzcash.merchantId');
    const password = this.config.get<string>('jazzcash.password');
    const integritySalt = this.config.get<string>('jazzcash.integritySalt');
    const apiUrl = this.config.get<string>('jazzcash.apiUrl');

    const payload: Record<string, string> = {
      pp_Version: '1.1',
      pp_TxnType: 'MWALLET',
      pp_Language: 'EN',
      pp_MerchantID: merchantId!,
      pp_Password: password!,
      pp_TxnRefNo: txnRefNo,
      pp_SecureHash: '',
    };

    payload.pp_SecureHash = this.generateSecureHash(payload, integritySalt!);

    const response = await axios.post(`${apiUrl}/GetMWalletTransStatus`, payload, {
      timeout: 15000,
    });

    const data = response.data;
    return {
      success: data.pp_ResponseCode === '000',
      transactionReference: txnRefNo,
      responseCode: data.pp_ResponseCode,
      responseMessage: data.pp_ResponseMessage,
      raw: data,
    };
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────────

  // HMAC-SHA256 hash over sorted key=value pairs
  private generateSecureHash(
    payload: Record<string, string>,
    salt: string,
  ): string {
    const sorted = Object.keys(payload)
      .filter((k) => k !== 'pp_SecureHash' && payload[k] !== '')
      .sort()
      .map((k) => payload[k])
      .join('&');

    const hashInput = `${salt}&${sorted}`;
    return crypto.createHmac('sha256', salt).update(hashInput).digest('hex').toUpperCase();
  }

  private getTxnDateTime(): string {
    return new Date().toISOString().replace(/[-T:.Z]/g, '').slice(0, 14);
  }

  private getTxnExpiryDateTime(): string {
    const expiry = new Date(Date.now() + 60 * 60 * 1000); // +1 hour
    return expiry.toISOString().replace(/[-T:.Z]/g, '').slice(0, 14);
  }
}
