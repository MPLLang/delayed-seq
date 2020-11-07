structure Add =
struct
  structure Seq = ArraySequence

  type bignum = Bit.t Seq.t

  fun init (b1, b2) =
    case (b1, b2) of
      (Bit.ZERO, Bit.ZERO) =>
        SOME Bit.ZERO
    | (Bit.ONE, Bit.ONE) =>
        SOME Bit.ONE
    | _ =>
        NONE

  fun copy (a, b) =
    case b of SOME _ => b | NONE => a


  fun zz (SOME x) = x
    | zz NONE = Bit.ZERO


  fun addMod2 (b1, b2) =
    case (b1, b2) of
      (Bit.ZERO, _) => b2
    | (_, Bit.ZERO) => b1
    | _ => Bit.ZERO


  fun add3Mod2 (b1, b2, b3) =
    addMod2 (b1, addMod2 (b2, b3))


  fun add (x, y) =
    let
      val nx = Seq.length x
      val ny = Seq.length y
      val n = Int.max (nx, ny)

      fun nthx i = if i < nx then Seq.nth x i else Bit.ZERO
      fun nthy i = if i < ny then Seq.nth y i else Bit.ZERO

      val blockSize = 10000
      val numBlocks = 1 + ((n-1) div blockSize)

      val t = Util.startTiming ()

      val blockCarries =
        SeqBasis.tabulate 1 (0, numBlocks) (fn blockIdx =>
          let
            val lo = blockIdx * blockSize
            val hi = Int.min (lo + blockSize, n)
            fun loop acc i =
              if i >= hi then
                acc
              else
                loop (copy (acc, init (nthx i, nthy i))) (i+1)
          in
            loop NONE lo
          end)

      val t = Util.tick t "sum blocks"

      val blockPartials =
        SeqBasis.scan 5000 copy NONE (0, numBlocks)
        (fn i => Array.sub (blockCarries, i))

      val t = Util.tick t "scan block sums"

      val lastCarry = Array.sub (blockPartials, numBlocks)

      val result = ForkJoin.alloc (n+1)

      val _ =
        ForkJoin.parfor 1 (0, numBlocks) (fn blockIdx =>
          let
            val lo = blockIdx * blockSize
            val hi = Int.min (lo + blockSize, n)

            fun loop acc i =
              if i >= hi then
                ()
              else
                let
                  val acc' = copy (acc, init (nthx i, nthy i))
                  val thisBit = add3Mod2 (zz acc, nthx i, nthy i)
                in
                  Array.update (result, i, thisBit);
                  loop acc' (i+1)
                end
          in
            loop (Array.sub (blockPartials, blockIdx)) lo
          end)

      val t = Util.tick t "write blocks"

    in
      case lastCarry of
        SOME (Bit.ONE) =>
          (Array.update (result, n, Bit.ONE); ArraySlice.full result)
      | _ =>
          (ArraySlice.slice (result, 0, SOME n))
    end
end
