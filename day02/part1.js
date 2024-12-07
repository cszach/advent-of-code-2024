const fs = require("fs");

const wasm = fs.readFileSync(__dirname + "/part1.wasm");
const input = fs.readFileSync(__dirname + "/input.txt");

const memory = new WebAssembly.Memory({ initial: 1 });

function print_i32(num) {
  console.log(num);
}

function getImportObject(example) {
  if (example) {
    return {
      env: {
        memory,
        data_bytes: 60,
        print_i32,
      },
    };
  } else {
    return {
      env: {
        memory,
        data_bytes: 19161,
        print_i32,
      },
    };
  }
}

const importObject = getImportObject(false);

(async () => {
  const obj = await WebAssembly.instantiate(new Uint8Array(wasm), importObject);
  new Uint8Array(memory.buffer).set(input, 0);

  const { solution } = obj.instance.exports;

  const start = process.hrtime.bigint();
  const answer = solution();
  const end = process.hrtime.bigint();

  console.log("Answer:", answer);
  console.log(`Took ${end - start} nanoseconds`);
})();
