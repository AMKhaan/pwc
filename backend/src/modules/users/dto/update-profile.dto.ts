import {
  IsEnum, IsOptional, IsString, MaxLength,
} from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  Gender,
  GenderPreference,
} from '../../../database/entities/user.entity';

export class UpdateProfileDto {
  @ApiPropertyOptional({ example: 'John' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  firstName?: string;

  @ApiPropertyOptional({ example: 'Doe' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  lastName?: string;

  @ApiPropertyOptional({ example: '+923001234567' })
  @IsOptional()
  @IsString()
  phone?: string;

  @ApiPropertyOptional({ enum: Gender })
  @IsOptional()
  @IsEnum(Gender)
  gender?: Gender;

  @ApiPropertyOptional({ enum: GenderPreference })
  @IsOptional()
  @IsEnum(GenderPreference)
  genderPreference?: GenderPreference;

  // ─── Professional fields ──────────────────────────────────────────────────────

  @ApiPropertyOptional({ example: 'Engro Corporation' })
  @IsOptional()
  @IsString()
  officeName?: string;

  @ApiPropertyOptional({ example: 'Software Engineer' })
  @IsOptional()
  @IsString()
  jobTitle?: string;

  @ApiPropertyOptional({ example: '35201-1234567-1' })
  @IsOptional()
  @IsString()
  cnicNumber?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  cnicPhotoUrl?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  officeLinkedinUrl?: string;

  // ─── Student fields ───────────────────────────────────────────────────────────

  @ApiPropertyOptional({ example: 'LUMS' })
  @IsOptional()
  @IsString()
  universityName?: string;

  @ApiPropertyOptional({ example: 'STUDENT' })
  @IsOptional()
  @IsString()
  staffType?: string;

  @ApiPropertyOptional({ example: 'BS Computer Science' })
  @IsOptional()
  @IsString()
  degreeDesignation?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  idCardPhotoUrl?: string;

  // ─── Shared optional fields ───────────────────────────────────────────────────

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  linkedinUrl?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  avatarUrl?: string;
}
