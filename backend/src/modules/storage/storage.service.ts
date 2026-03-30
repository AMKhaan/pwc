import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHmac } from 'crypto';
import { randomUUID } from 'crypto';
import * as path from 'path';
import * as fs from 'fs';

@Injectable()
export class StorageService {
  private readonly logger = new Logger(StorageService.name);
  readonly uploadsDir: string;
  private readonly appUrl: string;
  private readonly secret: string;

  constructor(private config: ConfigService) {
    this.appUrl = (this.config.get<string>('app.url') ?? 'http://localhost:3000').replace(/\/$/, '');
    this.secret = this.config.get<string>('jwt.secret') ?? 'secret';
    this.uploadsDir = process.env.UPLOADS_DIR ?? path.join(process.cwd(), 'uploads');

    for (const folder of ['avatars', 'documents']) {
      fs.mkdirSync(path.join(this.uploadsDir, folder), { recursive: true });
    }

    this.logger.log(`File storage: ${this.uploadsDir}`);
  }

  /**
   * Upload a buffer directly (server-side usage).
   */
  async upload(
    buffer: Buffer,
    originalName: string,
    folder: 'avatars' | 'documents',
    _mimeType: string,
  ): Promise<string> {
    const ext = path.extname(originalName) || '.bin';
    const key = `${folder}/${randomUUID()}${ext}`;
    fs.writeFileSync(path.join(this.uploadsDir, key), buffer);
    return `${this.appUrl}/uploads/${key}`;
  }

  /**
   * Generate a signed upload URL pointing to our own server.
   * Mobile does PUT to uploadUrl with raw bytes, then saves publicUrl to profile.
   */
  async getPresignedUploadUrl(
    folder: 'avatars' | 'documents',
    fileName: string,
    _mimeType: string,
    expiresInSeconds = 300,
  ): Promise<{ uploadUrl: string; publicUrl: string }> {
    const ext = path.extname(fileName) || '.bin';
    const key = `${folder}/${randomUUID()}${ext}`;
    const expires = Date.now() + expiresInSeconds * 1000;
    const sig = this.sign(key, expires);

    const uploadUrl =
      `${this.appUrl}/api/v1/storage/upload` +
      `?key=${encodeURIComponent(key)}&expires=${expires}&sig=${sig}`;
    const publicUrl = `${this.appUrl}/uploads/${key}`;

    return { uploadUrl, publicUrl };
  }

  /**
   * Save raw bytes to the given key path (called by StorageController).
   */
  saveFile(key: string, buffer: Buffer): void {
    const filePath = path.join(this.uploadsDir, key);
    fs.mkdirSync(path.dirname(filePath), { recursive: true });
    fs.writeFileSync(filePath, buffer);
  }

  /**
   * Verify the signed token on an incoming upload request.
   */
  verifyUploadToken(key: string, expires: number, sig: string): boolean {
    if (Date.now() > expires) return false;
    return this.sign(key, expires) === sig;
  }

  async delete(publicUrl: string): Promise<void> {
    try {
      const key = publicUrl.replace(`${this.appUrl}/uploads/`, '');
      const filePath = path.join(this.uploadsDir, key);
      if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
    } catch (err) {
      this.logger.warn(`Failed to delete file: ${publicUrl}`, err);
    }
  }

  private sign(key: string, expires: number): string {
    return createHmac('sha256', this.secret).update(`${key}:${expires}`).digest('hex');
  }
}
