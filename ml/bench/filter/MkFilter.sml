functor MkFilter (Seq: SEQUENCE) =
struct

  fun filter p s =
    let
      val s = Seq.fromArraySeq s
      val (offsets, count) =
        Seq.scan op+ 0 (Seq.map (fn x => if p x then 1 else 0) s)
      val result = ForkJoin.alloc count
    in
      Seq.applyIdx offsets (fn (i, offset) =>
        if p (Seq.nth s i) then
          Array.update (result, offset, Seq.nth s i)
        else
          ()
      );

      ArraySlice.full result
    end

end
