// Homey script to find the cheapest start time for running a dishwasher for 1.5 hours within the next 8 hours based on Tibber electricity prices.
// The script retrieves the Tibber API token and optionally a home ID from either the script arguments or Homey Logic variables. It then queries the Tibber GraphQL API for price information, calculates the optimal start time based on a sliding window of price periods, and tags various outputs for use in Homey flows.
// Usage:
// - Provide the Tibber token as the first argument or create a Homey Logic variable named "TIBBER_TOKEN
// - Optionally provide a specific Tibber home ID as the second argument or create a Homey Logic variable named "TIBBER_HOME_ID" (if you have multiple homes on the same account)
// - Add the Homey script to your environment and use the tagged outputs in your flows to schedule the dishwasher or for informational purposes.
// - Version 1.0 by Simon Skotheimsvik, created on 2024-06-20.

// Fallback Tibber API token for manual testing
const FALLBACK_TIBBER_TOKEN = "";

// Retrieve a logic variable value from Homey by name
async function getLogicVariableValueByName(variableName) {
  const allVariables = await Homey.logic.getVariables();
  const variable = Object.values(allVariables).find((v) => v.name === variableName);
  return variable?.value ? String(variable.value).trim() : "";
}

// Resolve Tibber token from multiple sources (args > logic variable > fallback)
const tokenFromArgs = args?.[0] ? String(args[0]).trim() : "";
const tokenFromLogic = await getLogicVariableValueByName("TIBBER_TOKEN");
const tokenFromFallback = FALLBACK_TIBBER_TOKEN ? String(FALLBACK_TIBBER_TOKEN).trim() : "";

// Resolve home ID from multiple sources (args > logic variable)
const homeIdFromArgs = args?.[1] ? String(args[1]).trim() : "";
const homeIdFromLogic = await getLogicVariableValueByName("TIBBER_HOME_ID");
const SELECTED_HOME_ID = homeIdFromArgs || homeIdFromLogic;

// Use the first available token
const TIBBER_TOKEN = tokenFromArgs || tokenFromLogic || tokenFromFallback;

// Validate that we have a token
if (!TIBBER_TOKEN) {
  throw new Error(
    "Missing Tibber token. Provide args[0], create Homey Logic variable TIBBER_TOKEN, or set FALLBACK_TIBBER_TOKEN for manual testing."
  );
}

// Configuration: 8-hour scheduling window and 1.5-hour program duration
const WINDOW_HOURS = 8;
const PROGRAM_DURATION_HOURS = 1.5;

const now = new Date();
const nowMs = now.getTime();
const windowEndMs = nowMs + WINDOW_HOURS * 60 * 60 * 1000;

const TIMEZONE = "Europe/Oslo";

function formatDateTime(date) {
  const parts = new Intl.DateTimeFormat("nb-NO", {
    timeZone: TIMEZONE,
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
    hour12: false
  }).formatToParts(date);
  const get = (type) => parts.find((p) => p.type === type)?.value || "";
  return `${get("day")}.${get("month")}.${get("year")} ${get("hour")}:${get("minute")}`;
}

const query = `
{
  viewer {
    homes {
      id
      appNickname
      currentSubscription {
        priceInfo {
          current {
            total
            energy
            tax
            startsAt
            currency
          }
          today {
            total
            energy
            tax
            startsAt
            currency
          }
          tomorrow {
            total
            energy
            tax
            startsAt
            currency
          }
        }
      }
    }
  }
}
`;

const response = await fetch("https://api.tibber.com/v1-beta/gql", {
  method: "POST",
  headers: {
    Authorization: `Bearer ${TIBBER_TOKEN}`,
    "Content-Type": "application/json"
  },
  body: JSON.stringify({ query })
});

const json = await response.json();

if (json.errors) {
  throw new Error(JSON.stringify(json.errors));
}

const homes = json?.data?.viewer?.homes || [];
if (!homes.length) {
  throw new Error("No Tibber homes found for this token.");
}

const selectedHome = SELECTED_HOME_ID
  ? homes.find((h) => h.id === SELECTED_HOME_ID)
  : homes[0];

if (!selectedHome) {
  throw new Error(`Home not found for TIBBER_HOME_ID: ${SELECTED_HOME_ID}`);
}

const priceInfo = selectedHome?.currentSubscription?.priceInfo;
if (!priceInfo) {
  throw new Error("No Tibber priceInfo found for current subscription.");
}

const prices = [...(priceInfo.today || []), ...(priceInfo.tomorrow || [])];

prices.sort((a, b) => new Date(a.startsAt) - new Date(b.startsAt));

// --- Statistics & price list (for all hour slots in the scheduling window) ---
let totalPrice = 0;
let count = 0;
let highestPrice = -Infinity;
const priceListText = [];

for (let i = 0; i < prices.length; i++) {
  const slotMs = new Date(prices[i].startsAt).getTime();
  const slotEndMs = slotMs + 60 * 60 * 1000;
  // Include any slot that overlaps with [now, windowEnd]
  if (slotEndMs <= nowMs || slotMs > windowEndMs) continue;

  const p0 = Number(prices[i].total);
  const energy = Number(prices[i].energy ?? 0);
  const tax = Number(prices[i].tax ?? 0);
  const currency = prices[i].currency || "";
  priceListText.push(
    `${formatDateTime(new Date(slotMs))}: energy:${energy.toFixed(3)} + tax:${tax.toFixed(3)} = total:${p0.toFixed(3)} ${currency}`
  );

  totalPrice += p0;
  count++;
  if (p0 > highestPrice) highestPrice = p0;
}

if (count === 0) {
  throw new Error("No prices found inside selected window.");
}

// --- Optimal start calculation (sliding window over actual price periods) ---
const durationMs = PROGRAM_DURATION_HOURS * 60 * 60 * 1000;

// Calculate the total electricity cost for running from startMs for durationMs
// by summing price × overlap-hours for every hourly price slot.
function calculateCost(startMs) {
  const endMs = startMs + durationMs;
  let cost = 0;
  let coveredMs = 0;
  for (const p of prices) {
    const slotStart = new Date(p.startsAt).getTime();
    const slotEnd = slotStart + 60 * 60 * 1000;
    const overlapStart = Math.max(startMs, slotStart);
    const overlapEnd = Math.min(endMs, slotEnd);
    if (overlapStart < overlapEnd) {
      const overlapHours = (overlapEnd - overlapStart) / (60 * 60 * 1000);
      cost += Number(p.total) * overlapHours;
      coveredMs += overlapEnd - overlapStart;
    }
  }
  // Only valid when price data covers the full program duration (1 min tolerance)
  if (coveredMs < durationMs - 60000) return Infinity;
  return cost;
}

// Candidate start times: "right now" + the start of each future hour in the window
const candidates = [nowMs];
for (const p of prices) {
  const slotMs = new Date(p.startsAt).getTime();
  if (slotMs > nowMs && slotMs <= windowEndMs) {
    candidates.push(slotMs);
  }
}

let bestStartMs = null;
let bestCost = Infinity;

for (const candidateMs of candidates) {
  const cost = calculateCost(candidateMs);
  if (cost < bestCost) {
    bestCost = cost;
    bestStartMs = candidateMs;
  }
}

if (bestStartMs === null) {
  throw new Error("No valid scheduling window found");
}

const startDelaySeconds = Math.max(0, Math.floor((bestStartMs - nowMs) / 1000));
const startTimeText = formatDateTime(new Date(bestStartMs));
const estimatedRuntimeCost = Number(bestCost.toFixed(3));
const avgPrice = Number((totalPrice / count).toFixed(3));
const highestPriceValue = Number(highestPrice.toFixed(3));
const priceList = priceListText.join("\n");
const selectedHomeText = `${selectedHome.appNickname || "(no nickname)"} | ${selectedHome.id}`;

await tag("oppvask_start_delay_seconds", startDelaySeconds);
await tag("oppvask_start_time_text", startTimeText);
await tag("oppvask_estimated_runtime_cost", estimatedRuntimeCost);
await tag("oppvask_avg_price", avgPrice);
await tag("oppvask_highest_price", highestPriceValue);
await tag("oppvask_price_list_text", priceList);
await tag("oppvask_selected_home", selectedHomeText);

return `Best start: ${startTimeText} | delay: ${startDelaySeconds}s | cost: ${estimatedRuntimeCost} | priceList: ${priceList}`;
