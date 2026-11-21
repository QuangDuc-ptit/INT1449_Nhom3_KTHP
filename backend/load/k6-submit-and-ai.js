// Load test KarVocab (BE2-S4-04): nộp bài luyện tập và sinh từ AI.
// Mục tiêu đặc tả: 500 người dùng đồng thời, P95 < 300 ms.
//
// Chạy (cần cài k6: https://k6.io), backend để AI_PROVIDER=mock:
//   k6 run -e BASE_URL=http://localhost:3100 load/k6-submit-and-ai.js
// Chạy thử nhẹ:
//   k6 run -e VUS=10 -e DURATION=30s load/k6-submit-and-ai.js
//
// Lưu ý: /ai/generate-vocab giới hạn 5 lần/phút/user, nên mỗi VU dùng tài khoản
// riêng và chỉ gọi AI ở một phần nhỏ vòng lặp; 429 không tính là lỗi hệ thống.
import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE = `${__ENV.BASE_URL || 'http://localhost:3100'}/api/v1`;
const VUS = Number(__ENV.VUS || 500);

export const options = __ENV.DURATION
  ? { vus: VUS, duration: __ENV.DURATION }
  : {
      stages: [
        { duration: '1m', target: Math.round(VUS / 5) },
        { duration: '2m', target: VUS },
        { duration: '2m', target: VUS },
        { duration: '30s', target: 0 },
      ],
      thresholds: {
        'http_req_duration{name:submit}': ['p(95)<300'],
        'http_req_duration{name:ai}': ['p(95)<300'],
        checks: ['rate>0.99'],
      },
    };

const json = { 'Content-Type': 'application/json' };

function uuid() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    return (c === 'x' ? r : (r & 0x3) | 0x8).toString(16);
  });
}

/** Mỗi VU: đăng ký tài khoản riêng, tạo học phần, lưu 10 từ. */
function setupUser() {
  const email = `k6-${__VU}-${Date.now()}-${Math.random().toString(36).slice(2)}@load.test`;
  const reg = http.post(
    `${BASE}/auth/register`,
    JSON.stringify({ email, password: 'Password123', fullName: `K6 ${__VU}` }),
    { headers: json },
  );
  const token = reg.json('data.accessToken');
  const auth = { ...json, Authorization: `Bearer ${token}` };
  const col = http.post(
    `${BASE}/collections`,
    JSON.stringify({ title: 'Load test', category: 'other' }),
    { headers: auth },
  );
  const collectionId = col.json('data.id');
  const gen = http.post(
    `${BASE}/ai/generate-vocab`,
    JSON.stringify({ topic: 'Travel', cefrLevel: 'B1', wordCount: 10 }),
    { headers: auth },
  );
  const words = (gen.json('data.words') || []).map((w) => {
    const { existsInCollection, ...rest } = w;
    return rest;
  });
  http.post(
    `${BASE}/vocabularies/batch-save`,
    JSON.stringify({ collectionId, words }),
    { headers: auth },
  );
  return { auth, collectionId };
}

let ctx;

export default function () {
  if (!ctx) ctx = setupUser();
  const { auth, collectionId } = ctx;

  const qs = http.get(
    `${BASE}/practice/questions?collectionId=${collectionId}&mode=choose_meaning&limit=10`,
    { headers: auth, tags: { name: 'questions' } },
  );
  const questions = qs.json('data.questions') || [];

  const submit = http.post(
    `${BASE}/practice/submit-session`,
    JSON.stringify({
      clientSessionId: uuid(),
      collectionId,
      mode: 'choose_meaning',
      durationSeconds: 60,
      answers: questions.map((q) => ({
        vocabularyId: q.vocabularyId,
        userAnswer: q.answer,
        responseTimeMs: 1500,
      })),
    }),
    { headers: auth, tags: { name: 'submit' } },
  );
  check(submit, { 'nộp bài 200': (r) => r.status === 200 });

  if (Math.random() < 0.05) {
    const ai = http.post(
      `${BASE}/ai/generate-vocab`,
      JSON.stringify({ topic: 'Green energy', cefrLevel: 'B2', wordCount: 5 }),
      { headers: auth, tags: { name: 'ai' } },
    );
    check(ai, { 'AI 200 hoặc 429': (r) => r.status === 200 || r.status === 429 });
  }
  sleep(1);
}
