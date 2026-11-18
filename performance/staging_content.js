// k6 smoke/load script. NEVER run against production.
// Usage: BASE_URL=https://staging.example.org k6 run performance/staging_content.js
import http from 'k6/http';
import { check, sleep } from 'k6';
export const options = {
  stages: [
    { duration: '20s', target: 5 },
    { duration: '45s', target: 20 },
    { duration: '20s', target: 0 },
  ],
  thresholds: {
    http_req_failed: ['rate<0.02'],
    http_req_duration: ['p(95)<1500'],
  },
};
const base = __ENV.BASE_URL || '';
if (!/^https:\/\/[^/]*staging[^/]*\/?$/.test(base)) {
  throw new Error('Set HTTPS BASE_URL with "staging" hostname only');
}
export default function () {
  const response = http.get(base + '/health', { timeout: '10s' });
  check(response, { 'healthy response': (r) => r.status === 200 });
  sleep(1);
}
