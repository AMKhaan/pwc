import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
} from 'typeorm';

export enum Gender {
  MALE = 'MALE',
  FEMALE = 'FEMALE',
  OTHER = 'OTHER',
}

export enum GenderPreference {
  ANY = 'ANY',
  SAME_GENDER = 'SAME_GENDER',
}

export enum UserType {
  PROFESSIONAL = 'PROFESSIONAL',
  STUDENT = 'STUDENT',
}

export enum VerificationStatus {
  PENDING = 'PENDING',
  VERIFIED = 'VERIFIED',
  REJECTED = 'REJECTED',
}

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  email: string;

  @Column({ nullable: true, select: false })
  password: string;

  @Column({ name: 'first_name' })
  firstName: string;

  @Column({ name: 'last_name' })
  lastName: string;

  @Column({ nullable: true })
  phone: string;

  @Column({ name: 'avatar_url', nullable: true })
  avatarUrl: string;

  @Column({ type: 'enum', enum: Gender, nullable: true })
  gender: Gender;

  @Column({
    name: 'gender_preference',
    type: 'enum',
    enum: GenderPreference,
    default: GenderPreference.ANY,
  })
  genderPreference: GenderPreference;

  @Column({ name: 'user_type', type: 'enum', enum: UserType })
  userType: UserType;

  @Column({
    name: 'verification_status',
    type: 'enum',
    enum: VerificationStatus,
    default: VerificationStatus.PENDING,
  })
  verificationStatus: VerificationStatus;

  @Column({ name: 'linkedin_id', nullable: true, unique: true })
  linkedinId: string;

  @Column({ name: 'linkedin_url', nullable: true })
  linkedinUrl: string;

  @Column({ name: 'linkedin_data', type: 'jsonb', nullable: true })
  linkedinData: Record<string, any>;

  @Column({ name: 'company_email', nullable: true })
  companyEmail: string;

  @Column({ name: 'university_email', nullable: true })
  universityEmail: string;

  @Column({
    name: 'trust_score',
    type: 'decimal',
    precision: 5,
    scale: 2,
    default: 0,
  })
  trustScore: number;

  @Column({ name: 'fcm_token', nullable: true })
  fcmToken: string;

  @Column({ name: 'is_active', default: true })
  isActive: boolean;

  @Column({ name: 'is_email_verified', default: false })
  isEmailVerified: boolean;

  @Column({ name: 'is_phone_verified', default: false })
  isPhoneVerified: boolean;

  @Column({ name: 'is_suspended', default: false })
  isSuspended: boolean;

  @Column({ name: 'is_admin', default: false })
  isAdmin: boolean;

  // ─── Profile completion fields ────────────────────────────────────────────────

  @Column({ name: 'office_name', nullable: true })
  officeName: string;

  @Column({ name: 'job_title', nullable: true })
  jobTitle: string;

  @Column({ name: 'cnic_number', nullable: true })
  cnicNumber: string;

  @Column({ name: 'cnic_photo_url', nullable: true })
  cnicPhotoUrl: string;

  @Column({ name: 'id_card_photo_url', nullable: true })
  idCardPhotoUrl: string;

  @Column({ name: 'university_name', nullable: true })
  universityName: string;

  @Column({ name: 'staff_type', nullable: true })
  staffType: string;

  @Column({ name: 'degree_designation', nullable: true })
  degreeDesignation: string;

  @Column({ name: 'office_linkedin_url', nullable: true })
  officeLinkedinUrl: string;

  @Column({ name: 'verification_submitted_at', type: 'timestamptz', nullable: true })
  verificationSubmittedAt: Date;

  @Column({ name: 'rejection_reason', nullable: true, type: 'text' })
  rejectionReason: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
