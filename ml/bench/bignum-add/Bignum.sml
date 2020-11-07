structure Bignum =
struct

  structure Seq = ArraySequence
  type t = Bit.t Seq.t
  type bignum = t

  fun properlyFormatted x =
    Seq.length x = 0 orelse Seq.nth x (Seq.length x - 1) = Bit.ONE

  fun fromIntInf (x: IntInf.int): bignum =
    if x < 0 then
      raise Fail "bignums can't be negative"
    else
      let
        fun toList (x: IntInf.int) =
          if x = 0 then []
          else Bit.fromInt (IntInf.toInt (x mod 2)) :: toList (x div 2)
      in
        Seq.fromList (toList x)
      end

  fun toIntInf (n: bignum): IntInf.int =
    if not (properlyFormatted n) then
      raise Fail "invalid bignum"
    else
      let
        val n' = Seq.map (IntInf.fromInt o Bit.toInt) n
      in
        Seq.iterate (fn (x, d) => 2 * x + d) (0: IntInf.int) (Seq.rev n')
      end

  fun generate n seed =
    let
      fun genbit seed =
        if 0w0 = Util.hash32_2 (Word32.fromInt seed) then
          Bit.ZERO
        else
          Bit.ONE
    in
      Seq.tabulate (fn i => if i < n then genbit i else Bit.ONE) n
    end

end
