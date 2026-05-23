import http from 'k6/http';
import { sleep, check } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 10 },
    { duration: '2m', target: 50 },
    { duration: '1m', target: 0 },
  ],
};

export default function () {
  const res = http.get('http://demo.local/api', {
    headers: { 'Host': 'demo.local' },
  });
  check(res, { 'status 200': (r) => r.status === 200 });
  sleep(0.5);
}
