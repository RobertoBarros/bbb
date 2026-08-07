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
  const election = http.get(`${baseUrl}/elections/${electionId}`, {
    headers: { Accept: "application/json" },
  });
  if (election.status !== 200) {
    throw new Error(`Não foi possível consultar a eleição: HTTP ${election.status}.`);
  }

  const electionData = election.json();

  if (electionData.status !== "open") {
    throw new Error("A eleição precisa estar aberta.");
  }

  if (!electionData.candidacies.length) throw new Error("A eleição não possui candidatos.");

  return { candidacyIds: weightedCandidacyIds(electionData.candidacies.map((candidacy) => candidacy.id)) };
}

export default function (data) {
  const candidacyId =
    data.candidacyIds[Math.floor(Math.random() * data.candidacyIds.length)];
  const response = http.post(
    `${baseUrl}/elections/${electionId}/votes`,
    JSON.stringify({ vote: { candidacy_id: candidacyId } }),
    {
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json",
      },
    }
  );

  if (
    check(response, {
      "voto aceito com sucesso": (result) => result.status === 202,
    })
  ) {
    votesSuccess.add(1);
  }
}
