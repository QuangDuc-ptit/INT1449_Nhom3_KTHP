import {
  SocialProfile,
  socialEmailRequired,
  socialTokenInvalid,
} from './social-verifier';

const GRAPH = 'https://graph.facebook.com';

interface DebugTokenResponse {
  data?: { is_valid?: boolean; app_id?: string };
}

interface MeResponse {
  id?: string;
  name?: string;
  email?: string;
  picture?: { data?: { url?: string } };
}

/** Xác thực access token Facebook bằng Graph API debug_token rồi lấy hồ sơ /me. */
export class FacebookVerifier {
  constructor(
    private readonly appId: string,
    private readonly appSecret: string,
  ) {}

  async verify(accessToken: string): Promise<SocialProfile> {
    const debugUrl = new URL(`${GRAPH}/debug_token`);
    debugUrl.searchParams.set('input_token', accessToken);
    debugUrl.searchParams.set(
      'access_token',
      `${this.appId}|${this.appSecret}`,
    );
    const debug = (await getJson(debugUrl)) as DebugTokenResponse;
    if (!debug.data?.is_valid || debug.data.app_id !== this.appId) {
      throw socialTokenInvalid();
    }

    const meUrl = new URL(`${GRAPH}/me`);
    meUrl.searchParams.set('fields', 'id,name,email,picture');
    meUrl.searchParams.set('access_token', accessToken);
    const me = (await getJson(meUrl)) as MeResponse;
    if (!me.id) throw socialTokenInvalid();
    if (!me.email) throw socialEmailRequired();
    return {
      providerId: me.id,
      email: me.email.trim().toLowerCase(),
      fullName: me.name?.trim() || me.email,
      avatarUrl: me.picture?.data?.url,
    };
  }
}

async function getJson(url: URL): Promise<unknown> {
  let res: Response;
  try {
    res = await fetch(url);
  } catch {
    throw socialTokenInvalid();
  }
  if (!res.ok) throw socialTokenInvalid();
  return res.json();
}
