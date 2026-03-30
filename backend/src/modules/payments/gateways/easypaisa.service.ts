import { Injectable, Logger, BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';
import * as crypto from 'crypto';

export interface EasypaisaPaymentRequest {
  mobileNumber: string;   // Customer's EasyPaisa number e.g. 03001234567
  amount: number;          // PKR amount
  orderRefNum: string;     // Unique reference from our system
  description: string;
}

export interface EasypaisaPaymentResult {
  success: boolean;
  transactionReference: string;
  responseCode: string;
  responseMessage: string;
  raw: Record<string, any>;
}

@Injectable()
export class EasypaisaService {
  private readonly logger = new Logger(EasypaisaService.name);

  constructor(private config: ConfigService) {}

  // ─── Initiate Mobile Account Payment ─────────────────────────────────────────
  // EasyPaisa MA (Mobile Account) payment API

  async initiatePayment(req: EasypaisaPaymentRequest): Promise<EasypaisaPaymentResult> {
    const storeId = this.config.get<string>('easypaisa.storeId');
    const hashKey = this.config.get<string>('easypaisa.hashKey');
    const apiUrl = this.config.get<string>('easypaisa.apiUrl');

    const payload = {
      storeId,
      amount: req.amount.toFixed(2),
      postBackURL: `${this.config.get('app.url')}/api/v1/payments/easypaisa/callback`,
      orderRefNum: req.orderRefNum,
      expiryDate: this.getExpiryDate(),
      autoRedirect: '0',
      paymentMethod: 'MA_PAYMENT',
      supportedPaymentInstruments: 'MA',
      mobileNum: req.mobileNumber,
      emailAddress: '',
      merchantHashedReq: '',
    };

    // Generate MD5 hash for EasyPaisa
    payload.merchantHashedReq = this.generateHash(payload, hashKey!);

    try {
      const response = await axios.post(
        `${apiUrl}/initPayment`,
        payload,
        {
          headers: { 'Content-Type': 'application/json', storeId: storeId! },
          timeout: 30000,
        },
      );

      const data = response.data;
      const success = data.responseCode === '0000';

      this.logger.log(
        `EasyPaisa [${req.orderRefNum}]: ${data.responseCode} — ${data.responseDesc}`,
      );

      return {
        success,
        transactionReference: data.transactionId || req.orderRefNum,
        responseCode: data.responseCode,
        responseMessage: data.responseDesc,
        raw: data,
      };
    } catch (error) {
      this.logger.error('EasyPaisa API error', error);
      throw new BadRequestException('Payment gateway error. Please try again.');
    }
  }

  // ─── Inquiry ──────────────────────────────────────────────────────────────────

  async inquirePayment(orderRefNum: string): Promise<EasypaisaPaymentResult> {
    const storeId = this.config.get<string>('easypaisa.storeId');
    const hashKey = this.config.get<string>('easypaisa.hashKey');
    const apiUrl = this.config.get<string>('easypaisa.apiUrl');

    const dateTime = new Date().toISOString().replace('T', ' ').slice(0, 19);
    const hashInput = `${storeId}${orderRefNum}${dateTime}${hashKey}`;
    const hash = crypto.createHash('md5').update(hashInput).digest('hex');

    const response = await axios.post(`${apiUrl}/getTransactionStatus`, {
      storeId,
      orderRefNum,
      transactionDateTime: dateTime,
      merchantHashReq: hash,
    }, { timeout: 15000 });

    const data = response.data;
    return {
      success: data.responseCode === '0000',
      transactionReference: data.transactionId || orderRefNum,
      responseCode: data.responseCode,
      responseMessage: data.responseDesc,
      raw: data,
    };
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────────

  private generateHash(payload: Record<string, any>, hashKey: string): string {
    const hashInput = [
      payload.amount,
      payload.storeId,
      payload.orderRefNum,
      payload.paymentMethod,
      payload.mobileNum,
      payload.emailAddress,
      payload.expiryDate,
      hashKey,
    ].join('');

    return crypto.createHash('md5').update(hashInput).digest('hex');
  }

  private getExpiryDate(): string {
    const expiry = new Date(Date.now() + 60 * 60 * 1000); // +1 hour
    return expiry.toISOString().replace('T', ' ').slice(0, 19);
  }
}
