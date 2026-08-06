import http from "k6/http";
import { check } from "k6";
import { Counter } from "k6/metrics";

const rate = Number(__ENV.RATE || 1000);
const duration = Number(__ENV.DURATION || 10);
const concurrency = Number(__ENV.CONCURRENCY || 50);
const baseUrl = __ENV.BASE_URL || "http://localhost:3000";
const electionId = __ENV.ELECTION_ID;

if (!electionId) {
  throw new Error("Defina ELECTION_ID.");
}

export const options = {
  scenarios: {
    votes: {
      executor: "constant-arrival-rate",
      rate,
      timeUnit: "1s",
      duration: `${duration}s`,
      preAllocatedVUs: concurrency,
      maxVUs: concurrency,
    },
  },
  thresholds: {
    checks: ["rate==1"],
    dropped_iterations: ["count==0"],
    votes_success: [`count==${rate * duration}`],
  },
};

const votesSuccess = new Counter("votes_success");

function candidacyIdsFrom(html) {
  return [...html.matchAll(/<input[^>]+name="vote\[candidacy_id\]"[^>]*>/g)]
    .map(([tag]) => tag.match(/value="([^"]+)"/)?.[1])
    .filter(Boolean);
}

function weightedCandidacyIds(ids) {
  if (ids.length === 1) return ids;

  const weights = Array(ids.length).fill(0);
  const leader = Math.floor(Math.random() * ids.length);
  weights[leader] = 70 + Math.floor(Math.random() * 21);

  for (let index = 0; index < 100 - weights[leader]; index += 1) {
    let candidate;
    do candidate = Math.floor(Math.random() * ids.length);
    while (candidate === leader);
    weights[candidate] += 1;
  }

  return ids.flatMap((id, index) => Array(weights[index]).fill(id));
}

export function setup() {
  const page = http.get(`${baseUrl}/elections/${electionId}`);
  if (page.status !== 200) {
    throw new Error(`Não foi possível abrir a eleição: HTTP ${page.status}.`);
  }

  const csrfToken = page.body.match(
    /<meta name="csrf-token" content="([^"]+)"/
  )?.[1];
  if (!csrfToken) throw new Error("Token CSRF não encontrado.");

  if (!page.body.includes("data-voting-form")) {
    if (page.body.includes('data-empty-state="candidates"')) {
      throw new Error("A eleição não possui candidatos.");
    }

    throw new Error("A eleição precisa estar aberta.");
  }

  const ids = candidacyIdsFrom(page.body);
  if (!ids.length) throw new Error("Campos de candidatura não encontrados.");

  const cookie = Object.values(page.cookies)
    .flat()
    .map(({ name, value }) => `${name}=${value}`)
    .join("; ");

  return { csrfToken, cookie, candidacyIds: weightedCandidacyIds(ids) };
}

export default function (data) {
  const candidacyId =
    data.candidacyIds[Math.floor(Math.random() * data.candidacyIds.length)];
  const response = http.post(
    `${baseUrl}/elections/${electionId}/votes`,
    {
      authenticity_token: data.csrfToken,
      "vote[candidacy_id]": candidacyId,
    },
    {
      redirects: 0,
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        ...(data.cookie ? { Cookie: data.cookie } : {}),
      },
    }
  );

  if (
    check(response, {
      "voto redirecionou com sucesso": (result) =>
        result.status === 302 || result.status === 303,
    })
  ) {
    votesSuccess.add(1);
  }
}
