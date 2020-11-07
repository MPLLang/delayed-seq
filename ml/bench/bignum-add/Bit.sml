structure Bit =
struct

  datatype t = ONE | ZERO

  fun toString ONE = "1"
    | toString ZERO = "0"

  fun fromInt 0 = ZERO
    | fromInt _ = ONE

  fun toInt ONE = 1
    | toInt ZERO = 0

  fun equal (ONE, ONE) = true
    | equal (ZERO, ZERO) = true
    | equal _ = false

end
