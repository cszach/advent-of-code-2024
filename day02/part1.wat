(module
  (import "env" "memory" (memory 1))
  (global $data_bytes (import "env" "data_bytes") i32)
  (import "env" "print_i32" (func $print_i32 (param i32)))

  ;; Returns the number of safe reports.
  (func (export "solution") (result i32)
    (local $offset i32)           ;; Offset to read char.
    (local $char i32)             ;; The char at offset.
    (local $num_safe_reports i32) ;; Answer to return.
    (local $prev_num i32)         ;; The previous level in the report.
    (local $prev_sign i32)        ;; The previous increase or decrease (sign).
    (local $unsafe i32)           ;; Set to 1 once a report is found unsafe.
    (local $diff i32)             ;; Previous level minus current level.
    (local $i i32)                ;; Level number in the report (1, 2, 3,…)
    (local $digit1 i32)           ;; The first digit of the level
    (local $digit2 i32)           ;; The second digit of the level

    (loop $process_level
      local.get $offset
      i32.load8_u
      local.tee $char

      i32.const 32 ;; ascii for space
      i32.eq

      local.get $char
      i32.const 10 ;; ascii for linefeed
      i32.eq

      i32.or

      (if ;; whitespace
        (then
          local.get $i         ;; Increment the level number
          i32.const 1
          i32.add
          local.set $i

          local.get $prev_sign ;; Load these variables on the stack to avoid
          local.get $prev_num  ;; declaring more local variables.

          local.get $digit1    ;; Compute the current number from the 2 digits.
          i32.const 10
          i32.mul
          local.get $digit2
          i32.add
          local.tee $prev_num  ;; stack: [cur_num, prev_num, prev_sign]

          ;; Conditions for a safe report (all must be true):
          ;; 1. $i < 2 || -3 <= $diff <= 3
          ;; 2. $i < 2 || $diff != 0
          ;; 3. $i < 3 || $sign == $prev_sign

          i32.sub              ;; Calculate the difference (prev_num - cur_num).
          local.tee $diff

          i32.const 0          ;; Extract sign and make sure it is the same
          i32.le_s             ;; as previous.
          local.tee $prev_sign
          i32.eq

          local.get $i         ;; Comparing with the previous sign would only be
          i32.const 3          ;; valid for all levels beginning with the third.
          i32.lt_u

          i32.or               ;; Condition 3.

          local.get $diff      ;; Condition 2.
          i32.const 0
          i32.ne

          i32.const -3         ;; Condition 1
          local.get $diff      ;;
          i32.le_s             ;;
                               ;;
          local.get $diff      ;;
          i32.const 3          ;;
          i32.le_s             ;;
                               ;;
          i32.and              ;;

          i32.and              ;; Combine conditions 1 and 2.

          local.get $i         ;; Conditions 1 and 2 would only be valid to
          i32.const 2          ;; check starting with the second level.
          i32.lt_u
          i32.or

          i32.and              ;; Combine conditions 1, 2, and 3.

          (if
            (then              ;; All conditions for a safe report passed.
              nop
            )
            (else
              i32.const 1
              local.set $unsafe
            )
          )

          i32.const 0          ;; Reset the digits to parse the next number.
          local.set $digit1    ;;
                               ;;
          i32.const 0          ;;
          local.set $digit2    ;;

          local.get $char      ;; Check if char is newline.
          i32.const 10
          i32.eq

          (if                  ;; If newline, reset vars for next report.
            (then
              local.get $unsafe
              i32.eqz

              (if
                (then
                  local.get $num_safe_reports
                  i32.const 1
                  i32.add
                  local.set $num_safe_reports
                )
              )

              i32.const 0
              local.set $i

              i32.const 0
              local.set $unsafe
            )
          )
        )
        (else ;; number
          ;; Based on the input, all levels are either one or two digits.
          ;; Strategy: set the first digit we see to $digit2. Then if we see
          ;; another digit and $digit2 has been set, move it to $digit1 and set
          ;; $digit2 to the recent digit. Works every time.

          local.get $digit2
          i32.eqz

          (if
            (then
              local.get $char
              i32.const 48 ;; ascii for '0'
              i32.sub
              local.set $digit2
            )
            (else
              local.get $digit2
              local.set $digit1
              local.get $char
              i32.const 48
              i32.sub
              local.set $digit2
            )
          )
        )
      )

      local.get $offset
      i32.const 1
      i32.add
      local.tee $offset

      global.get $data_bytes
      i32.lt_u
      br_if $process_level
    )

    (return (local.get $num_safe_reports))
  )
)
