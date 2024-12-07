# 🎄 Advent of Code 2024

My Advent of Code 2024 solutions in raw WebAssembly.

## 🧩 How to use

Go to any day. Then…

```shell
wat2wasm <WASM_FILE>
node <JS_FILE>
```

## 📔 Diary

### Day 1

- WebAssembly uses little-endianess. This caused a lot of headache initially.
  My approach is to write the input to WebAssembly memory, then read 4 chars at
  a time as an `i32` and use bitwise operations to extract the chars. But
  because of little-endianess, the bytes have to be written in reversed.
- Switching to SIMD didn't improve performance by much. I'm surprised to have
  got it working on first try though.
- Took me a while to learn `i8x16.shuffle` syntax. Thanks ChatGPT!
