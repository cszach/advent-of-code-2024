(module
  (import "env" "memory" (memory 1))
  (global $data_bytes (import "env" "data_bytes") i32)
  (global $list_length (import "env" "list_length") i32)

  ;; MEMORY LAYOUT
  ;;
  ;; BYTE                               DESCRIPTION
  ;; 0                                  Raw ASCII data
  ;; 󰇙
  ;; $data_bytes                        Left list's first number
  ;; $data_bytes + 4                    Left list's second number
  ;; 󰇙
  ;; $data_bytes + $list_length * 4     Right list's first number
  ;; $data_bytes + $list_length * 4 + 4 Right list's second number
  ;; 󰇙

  ;; Parse the number at the given byte offset. We know that every number is 5
  ;; digit, so we are going to hardcode some behavior.
  (func $parse
    (param $offset i32)
    (param $list_start i32)
    (param $i_4 i32)

    ;; These are used for insertion sort.
    (local $offset_prev i32)       ;; byte offset to the previous element
    (local $offset_curr i32)       ;; byte offset to the current element

    local.get $list_start
    local.get $i_4
    i32.add
    local.tee $offset_curr         ;; Used to store the new number later.

    local.get $offset              ;; Calculate the ten-thousands place value.
    i32.load8_u
    i32.const 48                   ;; ascii of '0'
    i32.sub                        ;; Convert char to int.
    i32.const 10000
    i32.mul

    local.get $offset              ;; Calculate the thousands place value.
    i32.const 1
    i32.add
    i32.load8_u
    i32.const 48
    i32.sub
    i32.const 1000
    i32.mul

    local.get $offset              ;; Calculate the hundreds place value.
    i32.const 2
    i32.add
    i32.load8_u
    i32.const 48
    i32.sub
    i32.const 100
    i32.mul

    local.get $offset              ;; Calculate the tens place value.
    i32.const 3
    i32.add
    i32.load8_u
    i32.const 48
    i32.sub
    i32.const 10
    i32.mul

    local.get $offset              ;; Calculate the ones place value.
    i32.const 4
    i32.add
    i32.load8_u
    i32.const 48
    i32.sub

    i32.add                        ;; Form the number from the digits.
    i32.add
    i32.add
    i32.add

    i32.store

    local.get $offset_curr
    i32.const 4
    i32.sub
    local.set $offset_prev

    (block $stop_sort
      (loop $insertion_sort
        local.get $offset_prev
        local.get $list_start
        i32.lt_s
        br_if $stop_sort

        local.get $offset_prev     ;; Compare previous and current numbers.
        i32.load
        local.get $offset_curr
        i32.load
        i32.gt_u

        (if
          (then                    ;; Previous number > current number => swap.
            local.get $offset_curr

            local.get $offset_prev
            i32.load

            local.get $offset_prev

            local.get $offset_curr
            i32.load               ;; s: [curr, offset_prev, prev, offset_curr]

            i32.store              ;; memory[$offset_prev] = curr
            i32.store              ;; memory[$offset_curr] = prev
          )
          (else
            br $stop_sort
          )
        )

        local.get $offset_prev
        local.tee $offset_curr
        i32.const 4
        i32.sub
        local.set $offset_prev

        br $insertion_sort
      )
    )
  )

  (func (export "solution") (result i32)
    (local $offset i32)            ;; the byte offset of the scanner
    (local $i_4 i32)               ;; $i * 4
    (local $right_list_start i32)  ;; the byte at which the right list starts
    
    (local $y v128)                ;; used for calculating abs
    (local $abs v128)
    (local $total_distance i32)    ;; answer

    global.get $data_bytes
    global.get $list_length        ;; Calculate $right_list_start
    i32.const 4                    ;; = $data_bytes + $list_length * 4
    i32.mul
    i32.add
    local.set $right_list_start

    (loop $parsing
      local.get $offset
      global.get $data_bytes       ;; $data_bytes is where the left list starts
      local.get $i_4
      call $parse

      local.get $offset
      i32.const 8
      i32.add
      local.tee $offset

      local.get $right_list_start
      local.get $i_4
      call $parse

      local.get $i_4
      i32.const 4
      i32.add
      local.set $i_4

      local.get $offset
      i32.const 6
      i32.add
      local.tee $offset

      global.get $data_bytes
      i32.lt_u
      br_if $parsing
    )

    ;; Now we have both lists read and sorted at $left_list_start and
    ;; $right_list_start, respectively.

    i32.const 0
    local.set $offset

    global.get $list_length
    i32.const 4
    i32.mul
    local.set $i_4

    (loop $calculate_distance
      global.get $data_bytes
      local.get $offset
      i32.add
      v128.load

      local.get $right_list_start
      local.get $offset
      i32.add
      v128.load

      i32x4.sub                    ;; Compute absolute value of the difference
      local.tee $abs               ;; using the formula abs(x) = (x ^ y) - y
      i32.const 31                 ;; where y = x >> 31
      i32x4.shr_s
      local.tee $y
      local.get $abs
      v128.xor
      local.get $y
      i32x4.sub

      local.tee $abs
      local.get $abs

      ;; We need to add all lanes together.
      ;; $abs = [a, b, c, d]
      ;;   SHUF [c, d, c, d]
      ;;   add  [a + c, b + d, c + c, d + d]
      ;;   SHUF [b + d, ...]
      ;;   add  [a + c + b + d, ...]

      ;;           |c        |d          |these don't matter...
      i8x16.shuffle 8 9 10 11 12 13 14 15 8 9 10 11 12 13 14 15
      local.get $abs
      i32x4.add
      local.tee $abs
      local.get $abs

      ;;           |b + d  |these don't matter...
      i8x16.shuffle 4 5 6 7 4 5 6 7 4 5 6 7 4 5 6 7
      local.get $abs
      i32x4.add
      local.tee $abs

      i32x4.extract_lane 0
      local.get $total_distance
      i32.add
      local.set $total_distance

      local.get $offset
      i32.const 16
      i32.add
      local.tee $offset

      local.get $i_4
      i32.lt_u
      br_if $calculate_distance
    )

    (return (local.get $total_distance))
  )
)
