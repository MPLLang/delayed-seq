functor MkAdd (Seq: SEQUENCE) =
struct

  structure ASeq = ArraySequence

  type bignum = Bit.t ASeq.t

  fun add (x, y) =
    let
      val x = Seq.fromArraySeq x
      val y = Seq.fromArraySeq y

      val t = Util.startTiming ()

      (* Extend the smaller number to be same length as the larger. *)
      val maxlen = Int.max (Seq.length x, Seq.length y)
      fun nth' s i = if i < Seq.length s then Seq.nth s i else Bit.ZERO
      val x' = Seq.tabulate (nth' x) (maxlen+1)
      val y' = Seq.tabulate (nth' y) (maxlen+1)

      val t = Util.tick t "match lengths"

      fun init (b1, b2) =
        case (b1, b2) of
          (Bit.ZERO, Bit.ZERO) =>
            SOME Bit.ZERO
        | (Bit.ONE, Bit.ONE) =>
            SOME Bit.ONE
        | _ =>
            NONE

      val (maybeCarries, _) =
        Seq.scan (fn (a, b) => case b of SOME _ => b | NONE => a) NONE
          (Seq.zipWith init (x', y'))

      val carries = Seq.map (fn NONE => Bit.ZERO | SOME x => x) maybeCarries

      val t = Util.tick t "scan carries"

      fun addMod2 (b1, b2) =
        case (b1, b2) of
          (Bit.ZERO, _) => b2
        | (_, Bit.ZERO) => b1
        | _ => Bit.ZERO
      fun add3Mod2 (b1, b2, b3) =
        addMod2 (b1, addMod2 (b2, b3))

      val result =
        Seq.force (Seq.zipWith addMod2 (carries, Seq.zipWith addMod2 (x', y')))

      (* val result =
        Seq.force (Seq.zipWith3 add3Mod2 (carries, x', y')) *)

      val t = Util.tick t "add columns"

      val r = Seq.toArraySeq result
    in
      (* [r] might have a trailing 0. Cut it off. *)
      if ASeq.length r = 0 orelse (ASeq.nth r (ASeq.length r - 1) = Bit.ONE) then
        r
      else
        ASeq.take r (ASeq.length r - 1)
    end

end
