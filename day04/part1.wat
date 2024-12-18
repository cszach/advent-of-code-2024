(module
  (import "env" "memory" (memory 1))
  (import "env" "data_bytes" (global $data_bytes i32))
  (import "env" "grid_size" (global $grid_size i32))
  ;; (import "env" "print_i32" (func $print_i32 (param i32) (result i32)))
  ;; (import "env" "print" (func $print (param i32) (param i32)))

  ;; Solve by following these steps:
  ;;
  ;; 1. Count XMAS and SAMX in the horizontal direction.
  ;; 2. Extract the forward slash diagonals to location $data_bytes, then count.
  ;; 3. Do step 2 with backward slash diagonals.
  ;; 4. Transpose the input in place, then count.

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

  ;; Extract the diagonals by writing each diagonal on its own line, starting at
  ;; $data_bytes.
  ;;
  ;; * $direction:         -1 for forward slash diagonals, 1 for backward slash
  ;;                       diagonals.
  ;; * $top_row_diagonals: 1 if extrating rows that start at the top row of the
  ;;                       input grid, 0 otherwise.
  (func $extract_diagonals
    (param $offset i32)
    (param $direction i32)
    (param $top_row_diagonals i32)
    (result i32)
    ;; ORIGINAL        OFFSET        RESULT (/)  ORIGINAL        RESULT (\)
    ;;
    ;;   012345                      012345        012345
    ;; 0 ...aej        $start      0 jklmno      0 agl...        abcdef
    ;; 1 ..bfkp        $start + 5  1 efghi       1 pbhm..        ghijk
    ;; 2 .cglqu  --->  $start + 11 2 abcd        2 uqcin.  --->  lmno
    ;; 3 dhmrv.        $start + 18 3 pqrst       3 .vrdjo        pqrst
    ;; 4 insw..        $start + 24 4 uvwx        4 ..wsek        uvwx
    ;; 5 otx...                                  5 ...xtf
    ;;
    ;; In the example on the left, the diagonals that start at the top row of
    ;; the input grid are:
    ;; * abcd
    ;; * efghi
    ;; * jklmno
    ;;
    ;; If $top_row_diagonals is 1, we are extracting these rows.
    (local $row i32)      ;; current 0-based row
    (local $col i32)      ;; current 0-based column
    (local $diag_len i32) ;; length of the diagonal being extracted
    (local $i i32)        ;; index of the current char in the current diagonal

    (if (i32.eq (local.get $direction) (i32.const -1))
      (then
        global.get $grid_size
        i32.const 1
        i32.sub
        local.set $col
      )
    )

    (if (i32.eq (local.get $top_row_diagonals) (i32.const 1))
      (then
        global.get $grid_size
        local.set $diag_len
      )
      (else
        global.get $grid_size
        i32.const 1
        i32.sub
        local.set $diag_len

        i32.const 1
        local.set $row
      )
    )

    (loop $diagonals
      (block $end_of_diagonal
        (loop $diagonal
          local.get $offset

          local.get $row
          local.get $col
          call $rowcol2index
          i32.load8_u

          i32.store8

          local.get $offset
          i32.const 1
          i32.add
          local.set $offset

          local.get $i
          i32.const 1
          i32.add
          local.tee $i
          
          local.get $diag_len
          i32.ge_u
          br_if $end_of_diagonal

          local.get $col
          local.get $direction
          i32.add
          local.set $col

          local.get $row
          i32.const 1
          i32.add
          local.set $row

          br $diagonal
        )
      )

      local.get $offset ;; Write a linefeed at where was left off.
      i32.const 10
      i32.store8

      local.get $offset
      i32.const 1
      i32.add
      local.set $offset

      (if (i32.eq (local.get $top_row_diagonals) (i32.const 1))
        (then
          (if (i32.eq (local.get $direction) (i32.const -1))
            (then
              local.get $row
              i32.const -1
              i32.add
              local.set $col
            )
            (else
              global.get $grid_size
              local.get $row
              i32.sub
              local.set $col
            )
          )

          i32.const 0
          local.set $row
        )
        (else
          (if (i32.eq (local.get $direction) (i32.const -1))
            (then
              local.get $col
              i32.const 1
              i32.add
              local.set $row

              global.get $grid_size
              i32.const 1
              i32.sub
              local.set $col
            )
            (else
              global.get $grid_size
              local.get $col
              i32.sub
              local.set $row

              i32.const 0
              local.set $col
            )
          )
        )
      )

      i32.const 0
      local.set $i

      local.get $diag_len
      i32.const 1
      i32.sub
      local.tee $diag_len

      i32.const 4
      i32.ge_u
      br_if $diagonals
    )

    local.get $offset
  )

  ;; Given a text content, count the number of XMAS and SAMX that appear in the
  ;; horizontal direction. For this to work properly, each line must be at least
  ;; 4 characters long (excluding the newline character).
  (func $do_the_count (param $offset i32) (param $end i32) (result i32)
    (local $count i32)
    (local $word i32)

    ;; CHAR DEC BIN
    ;;
    ;; X    88  01011000
    ;; M    77  01001101
    ;; A    65  01000001
    ;; S    83  01010011
    ;;
    ;; The constants for XMAS and SAMX are calculated by concatenating the bits
    ;; and converting to base 10. For XMAS, the bits for S go first, since we
    ;; are loading an i32 at a time and WebAssembly uses little-endianess.

    (loop $lines
      (block $eol
        (loop $cols
          local.get $offset    ;; XMAS and SAMX are both 4 bytes, so load 4B at
          i32.load             ;; a time and compare. Since WebAssembly uses
                               ;; little-endianess, the first byte is the last
                               ;; character in the string.

          local.tee $word
          i32.const 1396788568 ;; XMAS
          i32.eq

          local.get $word
          i32.const 1481458003 ;; SAMX
          i32.eq

          i32.add
          local.get $count
          i32.add
          local.set $count

          local.get $word      ;; Check if we should go to next line.
          i32.const 0xff000000 ;; Get the last character (first 8 bytes).
          i32.and
          i32.const 0x0a000000 ;; ascii for linefeed (LF) in little-endian.
          i32.eq
          br_if $eol

          local.get $offset
          i32.const 1
          i32.add
          local.set $offset

          br $cols
        )
      )

      local.get $offset
      i32.const 4
      i32.add
      local.tee $offset

      local.get $end
      i32.lt_u
      br_if $lines
    )

    local.get $count
  )

  (func (export "solution") (result i32)
    (local $row i32)
    (local $col i32)
    (local $offset_a i32)
    (local $offset_b i32)

    i32.const 0             ;; First, count in the horizontal direction.
    global.get $data_bytes
    call $do_the_count

    global.get $data_bytes  ;; For use as the $offset arg of $do_the_count.

    global.get $data_bytes  ;; Extract forward slash diagonals
    i32.const -1            ;;
    i32.const 1             ;;
    call $extract_diagonals ;;
                            ;;
    i32.const -1            ;;
    i32.const 0             ;;
    call $extract_diagonals ;;

    call $do_the_count

    global.get $data_bytes  ;; For use as the $offset arg of $do_the_count.

    global.get $data_bytes  ;; Extract backward slash diagonals
    i32.const 1             ;;
    i32.const 1             ;;
    call $extract_diagonals ;;
                            ;;
    i32.const 1             ;;
    i32.const 0             ;;
    call $extract_diagonals ;;

    call $do_the_count

    ;; Next, transpose the grid so we can count XMAS and SAMX in vertical
    ;; direction.

    (loop $rows
      (block $end_of_col
        (loop $cols
          local.get $row
          local.get $col
          call $rowcol2index
          local.tee $offset_a ;; [$offset_a]

          local.get $col
          local.get $row
          call $rowcol2index
          local.tee $offset_b ;; [$offset_b, $offset_a]

          i32.load8_u

          local.get $offset_b
          local.get $offset_a ;; [$a, $offset_b, $b, $offset_a]
          i32.load8_u

          i32.store8          ;; Transpose the two elements.
          i32.store8

          local.get $col
          i32.const 1
          i32.add
          local.tee $col

          local.get $row
          i32.ge_u
          br_if $end_of_col

          br $cols
        )
      )

      i32.const 0
      local.set $col

      local.get $row
      i32.const 1
      i32.add
      local.tee $row

      global.get $grid_size
      i32.lt_u
      br_if $rows
    )

    i32.const 0
    global.get $data_bytes
    call $do_the_count

    i32.add
    i32.add
    i32.add
  )
)
