import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { User } from './user.entity';

export enum EmailVerificationType {
  PRIMARY = 'PRIMARY',
  COMPANY = 'COMPANY',
  UNIVERSITY = 'UNIVERSITY',
}

@Entity('email_verifications')
export class EmailVerification {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ name: 'user_id' })
  userId: string;

  @Column()
  email: string;

  @Column({ length: 10 })
  token: string;

  @Column({ type: 'enum', enum: EmailVerificationType })
  type: EmailVerificationType;

  @Column({ name: 'expires_at' })
  expiresAt: Date;

  @Column({ name: 'verified_at', nullable: true })
  verifiedAt: Date;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
