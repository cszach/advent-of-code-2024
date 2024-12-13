# 🎄 Advent of WASM 2024

![WebAssembly logo](wa.png)

My Advent of Code 2024 solutions in hand-crafted WebAssembly. No processing in
JavaScript‒input is copied to WebAssembly and the answer is computed entirely in
there.

## 🎯 Goals

- Have fun.
- Learn about WebAssembly features (SIMD, threads, etc.)
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
|  3  |  1   |    ❌    |
|  3  |  2   |    ❌    |

## 📝 Reports

| Day | Part | Best runtime (μs) | WASM mem usage (bytes) | WASM file size (bytes) |
| :-: | :--: | :---------------: | :--------------------: | :--------------------: |
|  1  |  1   |      311.006      |          8000          |          473           |
|  1  |  2   |      507.89       |          8000          |          317           |
|  2  |  1   |      41.836       |           0            |          247           |
|  3  |  1   |      28.495       |           0            |          645           |
|  3  |  2   |      43.931       |           0            |          915           |

## 🍫 Data structures and algorithms

The table below lists non-trivial data structures and algorithms used in each
solution.

| Day | Part | Data structures |       Algorithms       |
| :-: | :--: | :-------------: | :--------------------: |
|  1  |  1   |      Array      |     Insertion sort     |
|  1  |  2   |      Array      |                        |
|  2  |  1   |                 |                        |
|  3  |  1   |                 | Finite state automaton |
|  3  |  2   |                 | Finite state automaton |

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
