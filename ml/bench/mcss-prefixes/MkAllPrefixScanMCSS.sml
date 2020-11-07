functor MkAllPrefixScanMCSS (Seq: SEQUENCE):
sig
  val mcss: real ArraySequence.t -> real ArraySequence.t
end =
struct

  structure ASeq = ArraySequence

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

  fun mcss s =
    let
      val s = Seq.fromArraySeq s
      val p = Seq.scanIncl combine id (Seq.map singleton s)
    in
      Seq.toArraySeq (Seq.map #3 p)
    end

end
