(module
  (import "env" "memory" (memory 1))
  (import "env" "data_bytes" (global $data_bytes i32))
  (import "env" "grid_size" (global $grid_size i32))
  (import "env" "print_i32" (func $print_i32 (param i32) (result i32)))

  ;; Converts 0-based row and column coordinates to offset to the input.
  (func $rowcol2index (param $row i32) (param $col i32) (result i32)
    ;; $row * ($grid_size + 1) + $col

    local.get $row
    global.get $grid_size
    i32.const 1
    i32.add
    i32.mul
    local.get $col
    i32.add
  )

  ;; Solve by iterating the grid. If the character is 'A', then check the 4
  ;; corners. Sum each diagonal of the X to make sure it is 160 ('M' + 'S').
  (func (export "solution") (result i32)
    (local $row         i32)       ;; 0-based row number
    (local $col         i32)       ;; 0-based column number
    (local $end         i32)       ;; upper limit of the row and column number
    (local $row_minus_1 i32)       ;; for extracting the X
    (local $row_plus_1  i32)       ;;
    (local $col_minus_1 i32)       ;;
    (local $col_plus_1  i32)       ;;
    (local $count       i32)       ;; the count of X-MASes

    global.get $grid_size
    i32.const 1
    i32.sub
    local.set $end

    i32.const 1
    local.tee $row
    local.set $col

    (loop $rows
      (loop $cols
        local.get $row
        local.get $col
        call $rowcol2index

        i32.load8_u
        i32.const 65               ;; ascii for 'A'
        i32.eq

        (if
          (then
            local.get $row         ;; Get the char at the top-left corner.
            i32.const 1            ;;
            i32.sub                ;;
            local.tee $row_minus_1 ;;
                                   ;;
            local.get $col         ;;
            i32.const 1            ;;
            i32.sub                ;;
            local.tee $col_minus_1 ;;
                                   ;;
            call $rowcol2index     ;;
            i32.load8_u            ;;

            local.get $row         ;; Get the char at the bottom-right corner.
            i32.const 1            ;;
            i32.add                ;;
            local.tee $row_plus_1  ;;
                                   ;;
            local.get $col         ;;
            i32.const 1            ;;
            i32.add                ;;
            local.tee $col_plus_1  ;;
                                   ;;
            call $rowcol2index     ;;
            i32.load8_u            ;;

            i32.add                ;; Add the two characters. The sum should be
            i32.const 160          ;; 160 (ASCII 'M' + 'S').
            i32.eq

            ;; Do the same for the other diagonal.

            local.get $row_minus_1
            local.get $col_plus_1
            call $rowcol2index
            i32.load8_u

            local.get $row_plus_1
            local.get $col_minus_1
            call $rowcol2index
            i32.load8_u

            i32.add
            i32.const 160
            i32.eq

            i32.and
            local.get $count
            i32.add
            local.set $count
          )
        )

        local.get $col
        i32.const 1
        i32.add
        local.tee $col

        local.get $end
        i32.lt_u
        br_if $cols
      )

      i32.const 1
      local.set $col

      local.get $row
      i32.const 1
      i32.add
      local.tee $row

      local.get $end
      i32.lt_u
      br_if $rows
    )

    local.get $count
  )
)
