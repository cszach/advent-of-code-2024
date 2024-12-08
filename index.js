const path = require("path");
const fs = require("fs");

const arg0 = process.argv[0];
const arg1 = process.argv[1];
const arg2 = process.argv[2];
const arg3 = process.argv[3];

if (!arg2 || !arg3 || arg2 === "-h" || arg2 === "--help") {
  console.log(
    `USAGE: ${path.basename(arg0)} ${path.basename(
      arg1
    )} <DAY> <PART> [<OPTIONS...>]

Supported options:

  --example   Run with example input only.
  --input     Run with input only.`
  );

  process.exit(1);
}

const options = new Set();

let i = 4;
while (process.argv[i] != null) {
  options.add(process.argv[i]);
  i++;
}

const day = parseInt(arg2, 10);
const part = parseInt(arg3, 10);

const dir = `${__dirname}/day${arg2.padStart(2, "0")}`;

async function run(
  inputFile,
  wasmModule,
  json,
  isExample,
  wasmSize,
  iterations = 100
) {
  const memory = new WebAssembly.Memory(json.memory);
  const importObject = isExample
    ? json.example.importObject
    : json.input.importObject;

  importObject.env.memory = memory;

  const wasm = await WebAssembly.instantiate(wasmModule, importObject);

  new Uint8Array(memory.buffer).set(inputFile, json.dataOffset || 0);

  const { solution } = wasm.exports;

  const expected = isExample ? json.example.expected : json.input.expected;
  const actual = solution();

  let emoji = "❓";
  let message = "";

  if (expected != null) {
    if (expected === actual) {
      emoji = "✅";
    } else {
      emoji = "❌";
      message = `(expected ${expected})`;
    }
  }

  console.log(
    `${emoji} ${isExample ? "EXAMPLE" : "INPUT  "} ${actual} ${message}`
  );

  if (!isExample && expected == actual) {
    // Start performance benchmarks

    // Warm up the function
    for (let i = 0; i < 10; i++) {
      solution();
    }

    const results = [];

    for (let i = 0; i < iterations; i++) {
      const start = process.hrtime.bigint();
      solution();
      const end = process.hrtime.bigint();

      results.push(Number(end - start));
    }

    const total = results.reduce((sum, timeNs) => sum + timeNs, 0);
    const avgNs = total / iterations;
    const bestNs = Math.min(...results);
    const memoryUsage = json.input.memoryUsage;

    console.log(`
    Avg. runtime     ${avgNs}ns (${avgNs / 1000}µs)
    Best runtime     ${bestNs}ns (${bestNs / 1000}µs)
    WASM mem usage   ${memoryUsage != null ? `${memoryUsage} bytes` : "Unknown"}
    WASM file size   ${wasmSize} bytes`);
  }
}

(async () => {
  try {
    const wasm = fs.readFileSync(`${dir}/part${part}.wasm`);
    const wasmModule = new WebAssembly.Module(new Uint8Array(wasm));

    const example = options.has("--input")
      ? null
      : fs.readFileSync(`${dir}/example.txt`);

    const input = options.has("--example")
      ? null
      : fs.readFileSync(`${dir}/input.txt`);

    const data = await require(`${dir}/index.json`);
    const partData = part == 1 ? data.part1 : data.part2;

    const title = `Day ${day} Part ${part == 1 ? "One" : "Two"}`;
    console.log(title);
    console.log("=".repeat(title.length));
    console.log();

    if (example && partData.example) {
      await run(example, wasmModule, partData, true);
    }

    if (input && partData.input) {
      await run(input, wasmModule, partData, false, wasm.byteLength);
    }
  } catch (err) {
    console.error(`Cannot find solution for day ${day} part ${part}.`);
    process.exit(2);
  }
})();
