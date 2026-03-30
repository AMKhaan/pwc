import {
  Injectable,
  ConflictException,
  UnauthorizedException,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, IsNull } from 'typeorm';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { User, UserType, VerificationStatus } from '../../database/entities/user.entity';
import { RedisService } from '../redis/redis.service';
import {
  EmailVerification,
  EmailVerificationType,
} from '../../database/entities/email-verification.entity';
import { UniversityDomain } from '../../database/entities/university-domain.entity';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { VerifyEmailDto } from './dto/verify-email.dto';
import { EmailService } from '../notifications/email.service';

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(User)
    private userRepo: Repository<User>,

    @InjectRepository(EmailVerification)
    private emailVerifRepo: Repository<EmailVerification>,

    @InjectRepository(UniversityDomain)
    private uniDomainRepo: Repository<UniversityDomain>,

    private jwtService: JwtService,
    private config: ConfigService,
    private redis: RedisService,
    private emailService: EmailService,
  ) {}

  // ─── Register ────────────────────────────────────────────────────────────────

  // ─── Free email provider blocklist ─────────────────────────────────────────
  private readonly FREE_EMAIL_DOMAINS = [
    'gmail.com', 'yahoo.com', 'yahoo.co.uk', 'ymail.com',
    'hotmail.com', 'hotmail.co.uk', 'outlook.com', 'live.com', 'msn.com',
    'icloud.com', 'me.com', 'mac.com',
    'aol.com', 'protonmail.com', 'proton.me',
    'mail.com', 'gmx.com', 'gmx.net',
    'zoho.com', 'tutanota.com', 'temp-mail.org',
  ];

  private getEmailDomain(email: string): string {
    return email.split('@')[1]?.toLowerCase() ?? '';
  }

  async register(dto: RegisterDto) {
    const domain = this.getEmailDomain(dto.email);

    // ─── Professional: must use company email (no free providers) ────────────
    if (dto.userType === UserType.PROFESSIONAL) {
      if (this.FREE_EMAIL_DOMAINS.includes(domain)) {
        throw new BadRequestException(
          'Please sign up with your company email address. Free email providers (Gmail, Yahoo, Outlook etc.) are not allowed for professional accounts.',
        );
      }
    }

    // ─── Student: must use an approved university domain ─────────────────────
    if (dto.userType === UserType.STUDENT) {
      const approvedDomain = await this.uniDomainRepo.findOne({
        where: { domain },
      });
      if (!approvedDomain) {
        throw new BadRequestException(
          `Your email domain (@${domain}) is not on the approved university list. Please use your official university email (e.g. @lums.edu.pk, @nu.edu.pk).`,
        );
      }
    }

    // Check duplicate email
    const existing = await this.userRepo.findOne({ where: { email: dto.email } });
    if (existing) {
      throw new ConflictException('Email already registered');
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(dto.password, 12);

    // Create user
    const user = this.userRepo.create({
      email: dto.email,
      password: hashedPassword,
      firstName: dto.firstName,
      lastName: dto.lastName,
      userType: dto.userType,
      phone: dto.phone,
      verificationStatus: VerificationStatus.PENDING,
    });

    await this.userRepo.save(user);

    // Send OTP for primary email verification
    await this.sendEmailOtp(user, dto.email, EmailVerificationType.PRIMARY);

    return {
      message: 'Registration successful. Please verify your email.',
      userId: user.id,
    };
  }

  // ─── Login ───────────────────────────────────────────────────────────────────

  async login(dto: LoginDto) {
    const user = await this.userRepo.findOne({
      where: { email: dto.email, isActive: true },
      select: ['id', 'email', 'password', 'firstName', 'lastName', 'userType',
               'verificationStatus', 'isEmailVerified'],
    });

    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    if (!user.password) {
      throw new UnauthorizedException('Please log in with LinkedIn');
    }

    const passwordMatch = await bcrypt.compare(dto.password, user.password);
    if (!passwordMatch) {
      throw new UnauthorizedException('Invalid credentials');
    }

    if (!user.isEmailVerified) {
      throw new UnauthorizedException('Please verify your email before logging in');
    }

    const token = this.generateToken(user);

    return {
      accessToken: token,
      user: this.sanitizeUser(user),
    };
  }

  // ─── Admin Login ─────────────────────────────────────────────────────────────

  async adminLogin(dto: LoginDto) {
    const user = await this.userRepo.findOne({
      where: { email: dto.email, isActive: true },
      select: ['id', 'email', 'password', 'firstName', 'lastName', 'isAdmin'],
    });

    if (!user || !user.isAdmin) {
      throw new UnauthorizedException('Invalid credentials');
    }

    if (!user.password) {
      throw new UnauthorizedException('Password login not configured for this account');
    }

    const passwordMatch = await bcrypt.compare(dto.password, user.password);
    if (!passwordMatch) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const token = this.generateToken(user);
    return { token, user: { id: user.id, email: user.email, firstName: user.firstName, lastName: user.lastName } };
  }

  // ─── Verify Primary Email ────────────────────────────────────────────────────

  async verifyEmail(dto: VerifyEmailDto) {
    const verification = await this.emailVerifRepo.findOne({
      where: {
        email: dto.email,
        token: dto.token,
        type: EmailVerificationType.PRIMARY,
        verifiedAt: IsNull(),
      },
    });

    if (!verification) {
      throw new BadRequestException('Invalid or expired OTP');
    }

    if (new Date() > verification.expiresAt) {
      throw new BadRequestException('OTP has expired. Please request a new one.');
    }

    // Mark verified
    verification.verifiedAt = new Date();
    await this.emailVerifRepo.save(verification);

    // Update user
    await this.userRepo.update(verification.userId, { isEmailVerified: true });

    return { message: 'Email verified successfully' };
  }

  // ─── Resend OTP ──────────────────────────────────────────────────────────────

  async resendOtp(email: string) {
    const user = await this.userRepo.findOne({ where: { email } });
    if (!user) {
      throw new NotFoundException('User not found');
    }

    if (user.isEmailVerified) {
      throw new BadRequestException('Email already verified');
    }

    await this.sendEmailOtp(user, email, EmailVerificationType.PRIMARY);
    return { message: 'OTP sent successfully' };
  }

  // ─── Verify Company Email ────────────────────────────────────────────────────

  async sendCompanyEmailOtp(userId: string, companyEmail: string) {
    const user = await this.userRepo.findOne({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');

    // Basic domain validation — not a free email provider
    const freeDomains = ['gmail.com', 'yahoo.com', 'hotmail.com', 'outlook.com'];
    const domain = companyEmail.split('@')[1];
    if (freeDomains.includes(domain)) {
      throw new BadRequestException('Please use your official company email, not a personal email');
    }

    await this.sendEmailOtp(user, companyEmail, EmailVerificationType.COMPANY);
    return { message: 'OTP sent to company email' };
  }

  async verifyCompanyEmail(userId: string, dto: VerifyEmailDto) {
    const verification = await this.emailVerifRepo.findOne({
      where: {
        userId,
        email: dto.email,
        token: dto.token,
        type: EmailVerificationType.COMPANY,
        verifiedAt: IsNull(),
      },
    });

    if (!verification) throw new BadRequestException('Invalid or expired OTP');
    if (new Date() > verification.expiresAt) {
      throw new BadRequestException('OTP expired. Please request a new one.');
    }

    verification.verifiedAt = new Date();
    await this.emailVerifRepo.save(verification);

    await this.userRepo.update(userId, { companyEmail: dto.email });

    return { message: 'Company email verified successfully' };
  }

  // ─── Verify University Email ──────────────────────────────────────────────────

  async sendUniversityEmailOtp(userId: string, universityEmail: string) {
    const user = await this.userRepo.findOne({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');

    const domain = universityEmail.split('@')[1];
    const uniDomain = await this.uniDomainRepo.findOne({
      where: { domain, isActive: true },
    });

    if (!uniDomain) {
      throw new BadRequestException(
        `${domain} is not in our approved university list. Contact support to add your university.`,
      );
    }

    await this.sendEmailOtp(user, universityEmail, EmailVerificationType.UNIVERSITY);
    return { message: `OTP sent to ${universityEmail}` };
  }

  async verifyUniversityEmail(userId: string, dto: VerifyEmailDto) {
    const verification = await this.emailVerifRepo.findOne({
      where: {
        userId,
        email: dto.email,
        token: dto.token,
        type: EmailVerificationType.UNIVERSITY,
        verifiedAt: IsNull(),
      },
    });

    if (!verification) throw new BadRequestException('Invalid or expired OTP');
    if (new Date() > verification.expiresAt) {
      throw new BadRequestException('OTP expired. Please request a new one.');
    }

    verification.verifiedAt = new Date();
    await this.emailVerifRepo.save(verification);

    await this.userRepo.update(userId, {
      universityEmail: dto.email,
      userType: UserType.STUDENT,
    });

    return { message: 'University email verified successfully' };
  }

  // ─── LinkedIn OAuth callback ──────────────────────────────────────────────────

  async handleLinkedInCallback(linkedinProfile: any) {
    const { id, emails, name, profileUrl, _json } = linkedinProfile;
    const email = emails?.[0]?.value;

    if (!email) {
      throw new BadRequestException('LinkedIn account has no email associated');
    }

    // Find or create user
    let user = await this.userRepo.findOne({
      where: [{ linkedinId: id }, { email }],
    });

    if (!user) {
      user = this.userRepo.create({
        email,
        firstName: name?.givenName || '',
        lastName: name?.familyName || '',
        linkedinId: id,
        linkedinUrl: profileUrl,
        linkedinData: _json,
        userType: UserType.PROFESSIONAL,
        isEmailVerified: true, // LinkedIn email is pre-verified
        verificationStatus: VerificationStatus.PENDING,
      });
      await this.userRepo.save(user);
    } else {
      // Update LinkedIn data on each login
      await this.userRepo.update(user.id, {
        linkedinId: id,
        linkedinUrl: profileUrl,
        linkedinData: _json,
        isEmailVerified: true,
      });
    }

    const token = this.generateToken(user);
    return { accessToken: token, user: this.sanitizeUser(user) };
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  private async sendEmailOtp(
    user: User,
    email: string,
    type: EmailVerificationType,
  ) {
    // Rate limit: max 3 OTP requests per 10 minutes
    await this.redis.checkOtpRateLimit(email);
    await this.redis.incrementOtpCount(email);

    // Generate 6-digit OTP (fixed when no real email provider is configured)
    const hasEmailProvider = !!this.config.get<string>('resend.apiKey');
    const token = hasEmailProvider
      ? Math.floor(100000 + Math.random() * 900000).toString()
      : '112233';
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000); // 15 minutes

    // Invalidate previous OTPs for this email+type
    await this.emailVerifRepo.update(
      { userId: user.id, email, type },
      { verifiedAt: new Date() }, // mark old ones as used
    );

    const verification = this.emailVerifRepo.create({
      userId: user.id,
      email,
      token,
      type,
      expiresAt,
    });

    await this.emailVerifRepo.save(verification);

    const emailType =
      type === EmailVerificationType.PRIMARY
        ? 'primary'
        : type === EmailVerificationType.COMPANY
        ? 'company'
        : 'university';

    await this.emailService.sendOtp(email, token, emailType);

    return token;
  }

  private generateToken(user: User): string {
    return this.jwtService.sign({
      sub: user.id,
      email: user.email,
    });
  }

  private sanitizeUser(user: User) {
    const { password, ...safe } = user as any;
    return safe;
  }
}
