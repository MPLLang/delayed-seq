structure DCMCSS =
struct

  val max = Real.max

  fun combine((l1,r1,b1,t1),(l2,r2,b2,t2)) =
    (max(l1, t1+l2),
     max(r2, r1+t2),
     max(r1+l2, max(b1,b2)),
     t1+t2)

  val id = (0.0, 0.0, 0.0, 0.0)

  fun singleton v =
    let
      val vp = max (v, 0.0)
    in
      (vp, vp, vp, v)
    end

  structure Seq = ArraySequence

  fun mcss xs =
    let
      fun m i j =
        if j-i <= 10000 then
          Util.loop (i, j) id (fn (b, k) =>
            combine (b, singleton (Seq.nth xs k)))
        else
          let
            val mid = i + (j-i) div 2
            val (left, right) =
              ForkJoin.par (fn _ => m i mid, fn _ => m mid j)
          in
            combine (left, right)
          end

      val (_, _, b, _) = m 0 (Seq.length xs)
    in
      b
    end

end
