(module
  (import "env" "memory" (memory 1))
  (global $data_bytes (import "env" "data_bytes") i32)
  ;; (import "env" "print_i32" (func $print_i32 (param i32)))

  ;; Solve using a finite state automaton (FSA).
  ;;
  ;; STATES MEANING                                                  TRANSITIONS
  ;;
  ;;      0 Have not read anything meaningful.                       'm' -> 1
  ;;                                                                   _ -> 0
  ;;
  ;;      1 Have read an 'm'.                                        'u' -> 2
  ;;                                                                   _ -> 0
  ;;
  ;;      2 Have read "mu".                                          'l' -> 3
  ;;                                                                   _ -> 0
  ;;
  ;;      3 Have read "mul".                                         '(' -> 4
  ;;                                                                   _ -> 0
  ;;
  ;;      4 Have read "mul(".                                        0-9 -> 5
  ;;                                                                   _ -> 0
  ;;
  ;;      5 Have read "mul(" and one digit.                          0-9 -> 6
  ;;                                                                 ',' -> 8
  ;;                                                                   _ -> 0
  ;;
  ;;      6 Have read "mul(" and two digits.                         0-9 -> 7
  ;;                                                                 ',' -> 8
  ;;                                                                   _ -> 0
  ;;
  ;;      7 Have read "mul(" and three digits.                       ',' -> 8
  ;;                                                                   _ -> 0
  ;;
  ;;      8 Have read "mul(", 1-3 digits, and a comma.               0-9 -> 9
  ;;                                                                   _ -> 0
  ;;
  ;;      9 Have read "mul(", 1-3 digits, a comma, and one digit.    0-9 -> 10
  ;;                                                                 ')' -> 12
  ;;                                                                   _ -> 0
  ;;
  ;;     10 Have read "mul(", 1-3 digits, a comma, and two digits.   0-9 -> 11
  ;;                                                                 ')' -> 12
  ;;                                                                   _ -> 0
  ;;
  ;;     11 Have read "mul(", 1-3 digits, a comma, and three digits. ')' -> 12
  ;;                                                                   _ -> 0
  ;;
  ;;     12 Have read an uncorrupted mul instruction.                'm' -> 1
  ;;                                                                   _ -> 0
  (func (export "solution") (result i32)
    (local $offset i32)
    (local $char i32)
    (local $state i32)
    (local $sum i32)
    (local $digit1 i32)
    (local $digit2 i32)
    (local $digit3 i32)
    (local $op1 i32)

    (block $eof
      (loop $eval
        local.get $offset
        global.get $data_bytes
        i32.ge_u
        br_if $eof

        local.get $offset
        i32.load8_u
        local.set $char

        local.get $offset
        i32.const 1
        i32.add
        local.set $offset

        (block $state_0
        (block $state_1
        (block $state_2
        (block $state_3
        (block $state_4
        (block $state_5
        (block $state_6
        (block $state_7
        (block $state_8
        (block $state_9
        (block $state_10
        (block $state_11
        (block $state_12
        (br_table $state_0 $state_1 $state_2 $state_3 $state_4 $state_5 $state_6
                  $state_7 $state_8 $state_9 $state_10 $state_11 $state_12
          (local.get $state)
        )
        )
        ;; State 12
        i32.const 100     ;; Have read enough digits to compute the second
                          ;; operand.
        local.get $digit1 ;;
        i32.mul           ;;
                          ;;
        i32.const 10      ;;
        local.get $digit2 ;;
        i32.mul           ;;
                          ;;
        local.get $digit3 ;;
                          ;;
        i32.add           ;;
        i32.add           ;;

        local.get $op1    ;; Multiply the two numbers and add it to the sum.
        i32.mul
        local.get $sum
        i32.add
        local.set $sum

        (local.set $digit1 (i32.const 0)) ;; Reset digit 1.
        (local.set $digit2 (i32.const 0)) ;; Reset digit 2.

        (if (i32.eq (local.get $char) (i32.const 109)) ;; ascii for 'm'
          (then (local.set $state (i32.const 1)))
          (else (local.set $state (i32.const 0)))
        )

        br $eval
        )
        ;; State 11
        (if (i32.eq (local.get $char) (i32.const 41)) ;; ascii for ')'
          (then (local.set $state (i32.const 12)))
          (else
            (local.set $digit1 (i32.const 0)) ;; Reset digit 1.
            (local.set $digit2 (i32.const 0)) ;; Reset digit 2.
            (local.set $state (i32.const 0))
          )
        )
        br $eval
        )
        ;; State 10
        i32.const 48 ;; ascii for '0'
        local.get $char
        i32.le_u

        local.get $char
        i32.const 57 ;; ascii for '9'
        i32.le_u

        i32.and

        (if
          (then ;; $char is 0-9
            local.get $digit2
            local.set $digit1

            local.get $digit3
            local.set $digit2

            local.get $char
            i32.const 48
            i32.sub
            local.set $digit3

            (local.set $state (i32.const 11))
          )
          (else
            local.get $char
            i32.const 41 ;; ascii for ')'
            i32.eq

            (if
              (then (local.set $state (i32.const 12)))
              (else
                (local.set $digit2 (i32.const 0)) ;; Reset digit 2.
                (local.set $state (i32.const 0))
              )
            )
          )
        )
        br $eval
        )
        ;; State 9
        i32.const 48 ;; ascii for '0'
        local.get $char
        i32.le_u

        local.get $char
        i32.const 57 ;; ascii for '9'
        i32.le_u

        i32.and

        (if
          (then ;; $char is 0-9
            local.get $digit3
            local.set $digit2

            local.get $char
            i32.const 48
            i32.sub
            local.set $digit3

            (local.set $state (i32.const 10))
          )
          (else
            local.get $char
            i32.const 41 ;; ascii for ')'
            i32.eq

            (if
              (then (local.set $state (i32.const 12)))
              (else (local.set $state (i32.const 0)))
            )
          )
        )
        br $eval
        )
        ;; State 8
        i32.const 100     ;; Have read enough digits to compute the first
                          ;; operand.
        local.get $digit1 ;;
        i32.mul           ;;
                          ;;
        i32.const 10      ;;
        local.get $digit2 ;;
        i32.mul           ;;
                          ;;
        local.get $digit3 ;;
                          ;;
        i32.add           ;;
        i32.add           ;;
                          ;;
        local.set $op1    ;;

        (local.set $digit1 (i32.const 0)) ;; Reset digit 1.
        (local.set $digit2 (i32.const 0)) ;; Reset digit 2.

        i32.const 48 ;; ascii for '0'
        local.get $char
        i32.le_u

        local.get $char
        i32.const 57 ;; ascii for '9'
        i32.le_u

        i32.and

        (if
          (then ;; $char is 0-9
            local.get $char
            i32.const 48
            i32.sub
            local.set $digit3

            (local.set $state (i32.const 9))
          )
          (else
            (local.set $state (i32.const 0))
          )
        )
        br $eval
        )
        ;; State 7
        (if (i32.eq (local.get $char) (i32.const 44)) ;; ascii for ','
          (then (local.set $state (i32.const 8)))
          (else
            (local.set $digit1 (i32.const 0)) ;; Reset digit 1.
            (local.set $digit2 (i32.const 0)) ;; Reset digit 2.
            (local.set $state (i32.const 0))
          )
        )
        br $eval
        )
        ;; State 6
        i32.const 48 ;; ascii for '0'
        local.get $char
        i32.le_u

        local.get $char
        i32.const 57 ;; ascii for '9'
        i32.le_u

        i32.and

        (if
          (then ;; $char is 0-9
            local.get $digit2
            local.set $digit1

            local.get $digit3
            local.set $digit2

            local.get $char
            i32.const 48
            i32.sub
            local.set $digit3

            (local.set $state (i32.const 7))
          )
          (else
            local.get $char
            i32.const 44 ;; ascii for ','
            i32.eq

            (if
              (then (local.set $state (i32.const 8)))
              (else
                (local.set $digit2 (i32.const 0)) ;; Reset digit 2.
                (local.set $state (i32.const 0))
              )
            )
          )
        )
        br $eval
        )
        ;; State 5
        i32.const 48 ;; ascii for '0'
        local.get $char
        i32.le_u

        local.get $char
        i32.const 57 ;; ascii for '9'
        i32.le_u

        i32.and

        (if
          (then ;; $char is 0-9
            local.get $digit3
            local.set $digit2

            local.get $char
            i32.const 48
            i32.sub
            local.set $digit3

            (local.set $state (i32.const 6))
          )
          (else
            local.get $char
            i32.const 44 ;; ascii for ','
            i32.eq

            (if
              (then (local.set $state (i32.const 8)))
              (else (local.set $state (i32.const 0)))
            )
          )
        )
        br $eval
        )
        ;; State 4
        i32.const 48 ;; ascii for '0'
        local.get $char
        i32.le_u

        local.get $char
        i32.const 57 ;; ascii for '9'
        i32.le_u

        i32.and

        (if
          (then ;; $char is 0-9
            local.get $char
            i32.const 48
            i32.sub
            local.set $digit3

            (local.set $state (i32.const 5))
          )
          (else (local.set $state (i32.const 0)))
        )
        br $eval
        )
        ;; State 3
        (if (i32.eq (local.get $char) (i32.const 40)) ;; ascii for '('
          (then (local.set $state (i32.const 4)))
          (else (local.set $state (i32.const 0)))
        )
        br $eval
        )
        ;; State 2
        (if (i32.eq (local.get $char) (i32.const 108)) ;; ascii for 'l'
          (then (local.set $state (i32.const 3)))
          (else (local.set $state (i32.const 0)))
        )
        br $eval
        )
        ;; State 1
        (if (i32.eq (local.get $char) (i32.const 117)) ;; ascii for 'u'
          (then (local.set $state (i32.const 2)))
          (else (local.set $state (i32.const 0)))
        )
        br $eval
        )
        ;; State 0
        (if (i32.eq (local.get $char) (i32.const 109)) ;; ascii for 'm'
          (then (local.set $state (i32.const 1)))
        )
        br $eval
      )
    )

    local.get $sum
    return
  )
)
