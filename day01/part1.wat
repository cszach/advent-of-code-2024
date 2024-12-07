(module
  (import "env" "memory" (memory 1))
  (global $data_start (import "env" "data_start") i32)
  (global $data_bytes (import "env" "data_bytes") i32)
  (global $list_length (import "env" "list_length") i32)
  ;; (import "env" "print_i32" (func $print_i32 (param i32)))

  ;; Precomputed powers of 10 for use when converting string to number.
  ;; WASM uses little endian so the least significant bytes go first.

  (data (i32.const 0)  "\01\00\00\00") ;; 1
  (data (i32.const 4)  "\0a\00\00\00") ;; 10
  (data (i32.const 8)  "\64\00\00\00") ;; 100
  (data (i32.const 12) "\e8\03\00\00") ;; 1_000
  (data (i32.const 16) "\10\27\00\00") ;; 10_000
  (data (i32.const 20) "\a0\86\01\00") ;; 100_000
  (data (i32.const 24) "\40\42\0f\00") ;; 1_000_000
  (data (i32.const 28) "\80\96\98\00") ;; 10_000_000
  (data (i32.const 32) "\00\e1\f5\05") ;; 100_000_000
  (data (i32.const 36) "\00\ca\9a\3b") ;; 1_000_000_000

  ;; MEMORY LAYOUT
  ;;
  ;; BYTE                                             DESCRIPTION
  ;; 0                                                Precomputed powers of 10
  ;; 󰇙
  ;; $data_start                                      Raw ASCII data
  ;; 󰇙
  ;; $data_start + $data_bytes                        Left list's first number
  ;; $data_start + $data_bytes + 4                    Left list's second number
  ;; 󰇙
  ;; $data_start + $data_bytes + $list_length * 4     Right list's first number
  ;; $data_start + $data_bytes + $list_length * 4 + 4 Right list's second number
  ;; 󰇙
  ;; $data_start + $data_bytes + $list_length * 8     Temporary buffer: ASCII of
  ;;                                                  the number being parsed.

  ;; Returns:
  ;; * 0 if the input byte was a whitespace
  ;; * 1 if the input byte was a whitespace and a number was inserted
  ;; * 2 if the input byte was a number
  ;; * 3 if the input byte was invalid
  (func $process_char
    (param $char i32)
    (param $temp_start i32)
    (param $list_id i32)
    (param $left_list_start i32)
    (param $right_list_start i32)
    (param $num_digits i32)
    (param $i i32)
    (param $last_result i32)

    (result i32)

    (local $number i32)      ;; the parsed number
    (local $temp_offset i32) ;; offset into the temporary buffer
    (local $list_start i32)  ;; $left_list_start or $right_list_start depending
                             ;; on $list_id
    (local $a i32)           ;; index to the previous number (insertion sort)
    (local $b i32)           ;; index to the current number (insertion sort)

    local.get $char ;; Test if the character is a whitespace (space or newline)
    i32.const 32    ;; space
    i32.eq          ;;
                    ;;
    local.get $char ;;
    i32.const 10    ;; newline (linefeed)
    i32.eq          ;;
                    ;;
    i32.or          ;;

    (if
      (then ;; whitespace
        (block $last_char_is_ws
          local.get $last_result  ;; Proceed only if the last char was a number
          i32.const 2
          i32.ne
          br_if $last_char_is_ws

          (local.set $number (i32.const 0))
          (local.set $temp_offset (i32.const 0))

          (loop $num_digits_is_not_zero
            local.get $num_digits  ;; Calculate the offset into the powers table
            i32.const 1
            i32.sub
            i32.const 4
            i32.mul

            i32.load ;; Load the power of 10

            local.get $temp_start  ;; Find the digit (still in ASCII)
            local.get $temp_offset
            i32.add
            i32.load8_u

            i32.const 48           ;; ascii for '0'
            i32.sub

            i32.mul                ;; Add the digit with power to $number
            local.get $number
            i32.add
            local.set $number

            local.get $temp_offset ;; Increment $temp_offset
            i32.const 1
            i32.add
            local.set $temp_offset

            local.get $num_digits  ;; Decrement $num_digits
            i32.const 1
            i32.sub
            local.tee $num_digits

            i32.const 0            ;; Continue loop if there's still digits
            i32.ne
            br_if $num_digits_is_not_zero
          )

          ;; Now we have the $number, insert it into the correct list and do
          ;; insertion sort.

          (if (i32.eqz (local.get $list_id))
            (then
              local.get $left_list_start
              local.set $list_start
            )
            (else
              local.get $right_list_start
              local.set $list_start
            )
          )


          local.get $i              ;; Set $b and $a
          local.tee $b              ;;
                                    ;;
          i32.const 1               ;;
          i32.sub                   ;;
          local.set $a              ;;

          local.get $list_start     ;; Insert number into list
          local.get $b
          i32.const 4
          i32.mul
          i32.add
          local.get $number
          i32.store

          (block $end_of_list
            (loop $insertion_sort
              local.get $a          ;; Stop if $a == -1
              i32.const -1
              i32.le_s
              br_if $end_of_list

              local.get $list_start ;; Load previous number
              local.get $a
              i32.const 4
              i32.mul
              i32.add
              i32.load

              local.get $list_start ;; Load current number
              local.get $b
              i32.const 4
              i32.mul
              i32.add
              i32.load

              (if (i32.gt_u)             ;; Previous > current number => swap
                (then
                  local.get $list_start  ;; Push the address of $b to stack
                  local.get $b
                  i32.const 4
                  i32.mul
                  i32.add

                  local.get $list_start  ;; Push the value at $a to stack
                  local.get $a
                  i32.const 4
                  i32.mul
                  i32.add
                  i32.load

                  local.get $list_start  ;; Push the address of $a to stack
                  local.get $a
                  i32.const 4
                  i32.mul
                  i32.add

                  local.get $list_start  ;; Push the value at $b to stack
                  local.get $b
                  i32.const 4
                  i32.mul
                  i32.add
                  i32.load

                  i32.store              ;; list[$a] = $b
                  i32.store              ;; list[$b] = $a
                )
                (else
                  br $end_of_list
                )
              )

              local.get $a ;; Decrement $a and $b
              local.tee $b
              i32.const 1
              i32.sub
              local.set $a

              br $insertion_sort
            )
          )

          (return (i32.const 1))
        )

        (return (i32.const 0))
      )
      (else
                         ;; Check if '0' <= $char <= '9'
        i32.const 48     ;; ascii for '0'
        local.get $char  ;;
        i32.le_u         ;;
                         ;;
        local.get $char  ;;
        i32.const 57     ;; ascii for '9'
        i32.le_u         ;;
                         ;;
        i32.or           ;;

        (if
          (then ;; number
            local.get $temp_start ;; Copy the byte over to temporary buffer
            local.get $num_digits ;;
            i32.add               ;;
                                  ;;
            local.get $char       ;;
                                  ;;
            i32.store8            ;; TODO: is using store8 the right thing?

            (return (i32.const 2))
          )
          (else ;; invalid
            (return (i32.const 3))
          )
        )
      )
    )

    i32.const 0
  )

  ;; Returns 1 if success, 0 if fail.
  (func (export "solution") (result i32)
    ;; For scanning.

    (local $offset i32)      ;; the byte offset of the scanner
    (local $word i32)        ;; the word (4 bytes) that is read at $offset
    (local $char1 i32)       ;; the leftmost 8 bits of $word
    (local $char2 i32)
    (local $char3 i32)
    (local $char4 i32)
    (local $last_result i32) ;; the last result of $process_char

    ;; For list management.

    (local $list_id i32)          ;; 0 = left list, 1 = right list
    (local $i i32)                ;; the index in the list
    (local $left_list_start i32)  ;; the byte at which the left list starts
    (local $right_list_start i32) ;; the byte at which the right list starts

    ;; For number parsing.

    (local $num_digits i32) ;; the number of digits that have been read so far
                            ;; for the number being parsed
    (local $temp_start i32) ;; the byte where the temporary memory starts where
                            ;; the ASCII of the number being parsed is written
    
    ;; Result

    (local $diff i32)
    (local $y i32)
    (local $total_distance i32)

    ;; Initializing to 0 might not be necessary?

    (local.set $offset (i32.const 0))
    (local.set $list_id (i32.const 0)) ;; Begin with reading for the left list.
    (local.set $num_digits (i32.const 0))
    (local.set $i (i32.const 0))
    (local.set $total_distance (i32.const 0))

    ;; Calculate $left_list_start = $data_start + $data_bytes

    global.get $data_start
    global.get $data_bytes
    i32.add
    local.tee $left_list_start

    ;; Calculate $right_list_start = $left_list_start + $list_length * 4

    global.get $list_length
    i32.const 4
    i32.mul
    i32.add
    local.tee $right_list_start

    ;; Calculate $temp_start = $right_list_start + $list_length * 4.

    global.get $list_length
    i32.const 4
    i32.mul
    i32.add
    local.set $temp_start

    ;; Begin data parsing. Rough steps:
    ;;
    ;; 1. Read 1 word (4 chars) at a time.
    ;; 2. Extract individual bytes and examine each character.
    ;; 3. If it is a space and the last char was a number:
    ;;    3.1. Parse the data at $temp_start from ASCII to integer.
    ;;    3.2. Insert it into $list_id using insertion sort.
    ;;    3.3. If $list_id == 1, increment $i.
    ;;    3.4. Flip $list_id.
    ;;    3.5. Reset $num_digits.
    ;; 4. If it is a number:
    ;;    4.1. Copy the byte over to the left list ($left_list_start) or the
    ;;         right list ($right_list_start) at offset $num_digits.
    ;;    4.2. Increment $num_digits.
    ;; 5. Otherwise:
    ;;    5.1. Set flag.
    ;;    5.2. Break.

    (loop $parsing
      (i32.add (global.get $data_start) (local.get $offset))
      i32.load
      local.tee $word

      i32.const 24     ;; first byte = word >> 24
      i32.shr_u        ;;
      local.tee $char1 ;;

      local.get $temp_start
      local.get $list_id
      local.get $left_list_start
      local.get $right_list_start
      local.get $num_digits
      local.get $i
      local.get $last_result

      call $process_char

      local.tee $last_result
      i32.const 1

      (if (i32.eq)              ;; A number was added to a list
        (then
          local.get $list_id    ;; If added to right list, move to next list pos
          i32.const 1

          (if (i32.eq)
            (then
              local.get $i
              i32.const 1
              i32.add
              local.set $i
            )
          )

          local.get $list_id    ;; Flip $list_id (left list <-> right list)
          i32.const 1
          i32.xor
          local.set $list_id

          i32.const 0           ;; Reset digit count
          local.set $num_digits
        )
        (else
          local.get $last_result
          i32.const 2

          (if (i32.eq)          ;; Char is a number
            (then
              local.get $num_digits
              i32.const 1
              i32.add
              local.set $num_digits
            )
            (else               ;; Char is neither whitespace nor number
              local.get $last_result
              i32.const 3

              (if (i32.eq)
                (then
                  (return (i32.const 0))
                )
              )
            )
          )
        )
      )

      local.get $word      ;; second byte = (word & 0x00ff0000) >> 16
      i32.const 0x00ff0000
      i32.and
      i32.const 16
      i32.shr_u
      local.tee $char2

      local.get $temp_start
      local.get $list_id
      local.get $left_list_start
      local.get $right_list_start
      local.get $num_digits
      local.get $i
      local.get $last_result

      call $process_char

      local.tee $last_result
      i32.const 1

      (if (i32.eq)              ;; A number was added to a list
        (then
          local.get $list_id    ;; If added to right list, move to next list pos
          i32.const 1

          (if (i32.eq)
            (then
              local.get $i
              i32.const 1
              i32.add
              local.set $i
            )
          )

          local.get $list_id    ;; Flip $list_id (left list <-> right list)
          i32.const 1
          i32.xor
          local.set $list_id

          i32.const 0           ;; Reset digit count
          local.set $num_digits
        )
        (else
          local.get $last_result
          i32.const 2

          (if (i32.eq)          ;; Char is a number
            (then
              local.get $num_digits
              i32.const 1
              i32.add
              local.set $num_digits
            )
            (else               ;; Char is neither whitespace nor number
              local.get $last_result
              i32.const 3

              (if (i32.eq)
                (then
                  (return (i32.const 0))
                )
              )
            )
          )
        )
      )

      local.get $word      ;; third byte = (word & 0x0000ff00) >> 8
      i32.const 0x0000ff00
      i32.and
      i32.const 8
      i32.shr_u
      local.tee $char3

      local.get $temp_start
      local.get $list_id
      local.get $left_list_start
      local.get $right_list_start
      local.get $num_digits
      local.get $i
      local.get $last_result

      call $process_char

      local.tee $last_result
      i32.const 1

      (if (i32.eq)              ;; A number was added to a list
        (then
          local.get $list_id    ;; If added to right list, move to next list pos
          i32.const 1

          (if (i32.eq)
            (then
              local.get $i
              i32.const 1
              i32.add
              local.set $i
            )
          )

          local.get $list_id    ;; Flip $list_id (left list <-> right list)
          i32.const 1
          i32.xor
          local.set $list_id

          i32.const 0           ;; Reset digit count
          local.set $num_digits
        )
        (else
          local.get $last_result
          i32.const 2

          (if (i32.eq)          ;; Char is a number
            (then
              local.get $num_digits
              i32.const 1
              i32.add
              local.set $num_digits
            )
            (else               ;; Char is neither whitespace nor number
              local.get $last_result
              i32.const 3

              (if (i32.eq)
                (then
                  (return (i32.const 0))
                )
              )
            )
          )
        )
      )

      local.get $word      ;; fourth byte = word & 0x000000ff
      i32.const 0x000000ff
      i32.and
      local.tee $char4

      local.get $temp_start
      local.get $list_id
      local.get $left_list_start
      local.get $right_list_start
      local.get $num_digits
      local.get $i
      local.get $last_result

      call $process_char

      local.tee $last_result
      i32.const 1

      (if (i32.eq)              ;; A number was added to a list
        (then
          local.get $list_id    ;; If added to right list, move to next list pos
          i32.const 1

          (if (i32.eq)
            (then
              local.get $i
              i32.const 1
              i32.add
              local.set $i
            )
          )

          local.get $list_id    ;; Flip $list_id (left list <-> right list)
          i32.const 1
          i32.xor
          local.set $list_id

          i32.const 0           ;; Reset digit count
          local.set $num_digits
        )
        (else
          local.get $last_result
          i32.const 2

          (if (i32.eq)          ;; Char is a number
            (then
              local.get $num_digits
              i32.const 1
              i32.add
              local.set $num_digits
            )
            (else               ;; Char is neither whitespace nor number
              local.get $last_result
              i32.const 3

              (if (i32.eq)
                (then
                  (return (i32.const 0))
                )
              )
            )
          )
        )
      )

      local.get $offset           ;; Check if finished reading the ASCII data
      i32.const 4                 ;;
      i32.add                     ;;
      local.tee $offset           ;;
                                  ;;
      global.get $data_bytes      ;;
      (br_if $parsing (i32.lt_u)) ;;
    )

    ;; Now we have both lists read and sorted at $left_list_start and
    ;; $right_list_start, respectively.

    (block $i_lt_0
      (loop $calculate_distance
        local.get $i
        i32.const 1
        i32.sub
        local.tee $i

        i32.const 0
        i32.lt_s
        br_if $i_lt_0

        local.get $left_list_start  ;; Push the value at left_list[i]
        local.get $i
        i32.const 4
        i32.mul
        i32.add
        i32.load

        local.get $right_list_start ;; Push the value at right_list[i]
        local.get $i
        i32.const 4
        i32.mul
        i32.add
        i32.load

        i32.sub                     ;; Compute absolute value of the difference
        local.tee $diff             ;; using the formula abs(x) = (x ^ y) - y
        i32.const 31
        i32.shr_s
        local.tee $y
        local.get $diff
        i32.xor
        local.get $y
        i32.sub

        local.get $total_distance
        i32.add
        local.set $total_distance

        br $calculate_distance
      )
    )

    i32.const 0
    local.get $total_distance
    i32.store

    (return (i32.const 1))
  )
)
