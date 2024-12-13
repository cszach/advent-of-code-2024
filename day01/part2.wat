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
  )

  (func (export "solution") (result i32)
    (local $offset i32)            ;; the byte offset of the scanner
    (local $i_4 i32)               ;; $i * 4
    (local $right_list_start i32)  ;; the byte at which the right list starts
    
    (local $offset2 i32)           ;; the offset into the current element in the
                                   ;; the right list
    (local $count i32)
    (local $similarity_score i32)  ;; answer

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

    ;; Now we have both lists read at $data_bytes and $right_list_start.

    ;; Start a nested loop over the lists, count the elements, and calculate the
    ;; similarity score. $offset is the offset into the current element in the
    ;; left list; $offset2 has a similar role for the right list. $i_4 is the
    ;; address where the right list ends.

    local.get $i_4
    local.get $right_list_start
    i32.add
    local.set $i_4

    (loop $iter_left_list
      local.get $right_list_start
      local.set $offset2
      
      i32.const 0
      local.set $count

      (loop $iter_right_list
        local.get $offset
        i32.load

        local.get $offset2
        i32.load

        i32.eq
        local.get $count
        i32.add
        local.set $count

        local.get $offset2
        i32.const 4
        i32.add
        local.tee $offset2

        local.get $i_4
        i32.lt_u
        br_if $iter_right_list
      )

      local.get $offset
      i32.load

      local.get $count
      i32.mul
      local.get $similarity_score
      i32.add
      local.set $similarity_score

      local.get $offset
      i32.const 4
      i32.add
      local.tee $offset

      local.get $right_list_start
      i32.lt_u
      br_if $iter_left_list
    )

    local.get $similarity_score
    return
  )
)
