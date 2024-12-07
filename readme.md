# 🎄 Advent of WASM 2024

![WebAssembly logo](wa.png)

My Advent of Code 2024 solutions in raw WebAssembly.

## 🎯 Goals

- Have fun.
- Learn about SIMD and low-level stuff.
- Small WAT file.
- Low memory usage.
- Fast execution time.

## 🧩 How to use

Go to any day. Then…

```
node <JS_FILE>
```

## ⚙️ Compile

```
npm install -g wat-wasm
wat2wasm <WAT_FILE> <FEATURES…>
```

For the list of required features, see below.

| Day | Part | `--simd` |
| :-: | :--: | :------: |
|  1  |  1   |    ✅    |
|  1  |  2   |    ❌    |

## 📔 Diary

### Day 1

- WebAssembly uses little-endianess. If the input is processed at a less nuanced
  level than byte-by-byte, then we will have to be careful how the input is
  written to WebAssembly memory.
- Switching to SIMD didn't improve performance by much. I'm surprised to have
  got it working on first try though.
- Took me a while to learn `i8x16.shuffle` syntax. Thanks ChatGPT!
