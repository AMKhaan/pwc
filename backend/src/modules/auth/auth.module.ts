import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { JwtStrategy } from './strategies/jwt.strategy';
import { LinkedInStrategy } from './strategies/linkedin.strategy';
import { User } from '../../database/entities/user.entity';
import { EmailVerification } from '../../database/entities/email-verification.entity';
import { UniversityDomain } from '../../database/entities/university-domain.entity';

@Module({
  imports: [
    PassportModule,
    TypeOrmModule.forFeature([User, EmailVerification, UniversityDomain]),
    JwtModule.registerAsync({
      imports: [ConfigModule],
      useFactory: (config: ConfigService) => ({
        secret: config.get<string>('jwt.secret') as string,
        signOptions: { expiresIn: (config.get<string>('jwt.expiresIn') || '7d') as `${number}${'s'|'m'|'h'|'d'}` },
      }),
      inject: [ConfigService],
    }),
  ],
  controllers: [AuthController],
  providers: [AuthService, JwtStrategy, LinkedInStrategy],
  exports: [AuthService, JwtModule],
})
export class AuthModule {}
