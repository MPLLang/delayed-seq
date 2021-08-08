functor MkBestCut(Seq: SEQUENCE):
sig
  type cutinfo = real * real * int * int
  type range = int * int

  val bestCut: Event.t ArraySequence.t -> range -> range -> range -> cutinfo
end =
struct
  type cutinfo = real * real * int * int
  type range = int * int

  fun min (r: range) = #1 r
  fun max (r: range) = #2 r

  fun isEnd e = if Event.isEnd e then 1 else 0

  fun iota n = Seq.tabulate (fn i => i) n

  fun bestCut E r r1 r2 =
    let
      val E = Seq.fromArraySeq E
      val n = Seq.length E

      (** area of two orthogonal faces *)
      val orthogArea = Real.fromInt (2 * ((max r1 - min r1) * (max r2 - min r2)))
      (** length of perimeter of orthogonal faces *)
      val orthoPerimeter = Real.fromInt (2 * ((max r1 - min r1) + (max r2 - min r2)))

      (** count number that end before i *)
      val is_end = Seq.map isEnd E
      val end_counts = Seq.scanIncl op+ 0 is_end

      fun getCost (num_ends, i) =
        let
          val num_ends_before = num_ends - isEnd (Seq.nth E i)
          val inLeft = Real.fromInt (i - num_ends_before)
          val inRight = Real.fromInt (n div 2 - num_ends)
          val leftLength = Event.value (Seq.nth E i) - Real.fromInt (min r)
          val leftSurfaceArea = orthogArea + orthoPerimeter * leftLength
          val rightLength = Real.fromInt (max r) - Event.value (Seq.nth E i)
          val rightSurfaceArea = orthogArea + orthoPerimeter * rightLength
          val cost = leftSurfaceArea * inLeft + rightSurfaceArea * inRight
        in
          (cost, num_ends_before, i)
        end

      val costs = Seq.zipWith getCost (end_counts, iota n)

      fun min_f (a, b) =
        if #1 a < #1 b then a else b

      val (cost, num_ends_before, i) =
        Seq.reduce min_f (Real.posInf, 0, 0) costs

      val ln = i - num_ends_before
      val rn = n div 2 - (num_ends_before + isEnd (Seq.nth E i))
    in
      (cost, Event.value (Seq.nth E i), ln, rn)
    end

end
