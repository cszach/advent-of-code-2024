# 🎄 Advent of WASM 2024

![WebAssembly logo](wa.png)

My Advent of Code 2024 solutions in hand-crafted WebAssembly. No processing in
JavaScript‒input is copied to WebAssembly and the answer is computed entirely in
there.

## 🎯 Goals

- Have fun.
- Learn about SIMD, multi-threading, and low-level stuff.
- Small WASM file.
- Low memory usage.
- Fast execution time.

## 🧩 How to use

```
node index.js <DAY> <PART>
```

For help info, try `node index.js`.

When running with the input, the data reported includes:

- Average runtime in nanoseconds (one billionth of a second) and microseconds
  (one millionth of a second)
- Best runtime (in 100 iterations)
- WASM memory usage (excluding the input) in bytes
- Compiled WASM file size in bytes

## ⚙️ Compile

```
npm install -g wat-wasm
wat2wasm <WAT_FILE> <FEATURES...>
```

For the list of required features, see below.

| Day | Part | `--simd` |
| :-: | :--: | :------: |
|  1  |  1   |    ✅    |
|  1  |  2   |    ❌    |
|  2  |  1   |    ❌    |

## Reports

| Day | Part | Best runtime (μs) | WASM mem usage (bytes) | WASM file size (bytes) |
| :-: | :--: | :---------------: | :--------------------: | :--------------------: |
|  1  |  1   |      311.006      |          8000          |          473           |
|  1  |  2   |      525.754      |          8000          |          321           |
|  2  |  1   |      41.836       |           0            |          247           |

## 📔 Diary

### Day 1

- WebAssembly uses little-endianess. If the input is processed at a less nuanced
  level than byte-by-byte, then we will have to be careful how the input is
  written to WebAssembly memory.
- Switching to SIMD didn't improve performance by much. I'm surprised to have
  got it working on first try though.
- Took me a while to learn `i8x16.shuffle` syntax. It takes 2 `v128`s (on the
  stack) and 16 0-based indices, which indexes into bytes stored in the two
  vectors. The returned vector is formed from the bytes pointed to by the
  indices.
