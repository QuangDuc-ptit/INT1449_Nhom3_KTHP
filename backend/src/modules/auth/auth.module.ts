import { Global, Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { JwtModule } from '@nestjs/jwt';
import { JwtAuthGuard } from '../../common/auth/jwt-auth.guard';
import { Env, durationToSeconds } from '../../config/env.schema';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { PasswordResetService } from './password-reset.service';
import { FacebookVerifier } from './social/facebook.verifier';
import { GoogleVerifier } from './social/google.verifier';
import { MockSocialVerifier } from './social/mock-social.verifier';
import { RealSocialVerifier } from './social/real-social.verifier';
import { SocialVerifier } from './social/social-verifier';
import { TokenService } from './token.service';

@Global()
@Module({
  imports: [
    JwtModule.registerAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService<Env, true>) => ({
        secret: config.get('JWT_ACCESS_SECRET', { infer: true }),
        signOptions: {
          expiresIn: durationToSeconds(
            config.get('JWT_ACCESS_TTL', { infer: true }),
          ),
        },
      }),
    }),
  ],
  controllers: [AuthController],
  providers: [
    AuthService,
    TokenService,
    PasswordResetService,
    {
      provide: SocialVerifier,
      inject: [ConfigService],
      useFactory: (config: ConfigService<Env, true>): SocialVerifier =>
        config.get('SOCIAL_AUTH_MODE', { infer: true }) === 'real'
          ? new RealSocialVerifier(
              new GoogleVerifier(
                config.get('GOOGLE_CLIENT_ID', { infer: true }),
              ),
              new FacebookVerifier(
                config.get('FACEBOOK_APP_ID', { infer: true }),
                config.get('FACEBOOK_APP_SECRET', { infer: true }),
              ),
            )
          : new MockSocialVerifier(),
    },
    { provide: APP_GUARD, useClass: JwtAuthGuard },
  ],
  exports: [TokenService],
})
export class AuthModule {}
