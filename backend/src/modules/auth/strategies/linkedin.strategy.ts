import { Injectable, Logger } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { Strategy } from 'passport-linkedin-oauth2';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class LinkedInStrategy extends PassportStrategy(Strategy, 'linkedin') {
  private static readonly logger = new Logger('LinkedInStrategy');

  constructor(private config: ConfigService) {
    const clientID = config.get<string>('linkedin.clientId') || 'placeholder_not_configured';
    const clientSecret = config.get<string>('linkedin.clientSecret') || 'placeholder_not_configured';
    const callbackURL = config.get<string>('linkedin.callbackUrl') || 'http://localhost:3000/api/v1/auth/linkedin/callback';

    super({ clientID, clientSecret, callbackURL, scope: ['openid', 'profile', 'email'] });

    if (!config.get<string>('linkedin.clientId')) {
      LinkedInStrategy.logger.warn('LINKEDIN_CLIENT_ID not set — LinkedIn OAuth disabled');
    }
  }

  async validate(accessToken: string, refreshToken: string, profile: any, done: Function) {
    done(null, profile);
  }
}
