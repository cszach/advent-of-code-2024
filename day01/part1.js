const fs = require("fs");

const wasm = fs.readFileSync(__dirname + "/part1.wasm");
const input = fs.readFileSync(__dirname + "/input.txt");

const memory = new WebAssembly.Memory({ initial: 1 });

function getImportObject(example) {
  if (example) {
    return {
      env: {
        memory,
        data_start: 40,
        data_bytes: 36,
        list_length: 6,
        print_i32: (num) => {
          console.log(num);
        },
      },
    };
  } else {
    return {
      env: {
        memory,
        data_start: 40,
        data_bytes: 14000,
        list_length: 1000,
        print_i32: (num) => {
          console.log(num);
        },
      },
    };
  }
}

const importObject = getImportObject(false);

(async () => {
  const obj = await WebAssembly.instantiate(new Uint8Array(wasm), importObject);
  const { data_start } = importObject.env;

  new Uint8Array(memory.buffer).set(input, data_start);

  const view = new DataView(memory.buffer);

  const { solution } = obj.instance.exports;

  const start = process.hrtime.bigint();
  const success = solution();
  const end = process.hrtime.bigint();

  if (success) {
    console.log("Answer:", view.getUint32(0, true));
    console.log(`Took ${end - start} nanoseconds`);
  } else {
    console.error("Input or WebAssembly error");
  }
})();
