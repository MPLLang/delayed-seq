functor MkTokens (Seq: SEQUENCE) =
struct

  fun tokens (isSpace: char -> bool) s =
    let
      val s = Seq.fromArraySeq s
      val n = Seq.length s
      fun get i = Seq.nth s i

      fun isStart i =
        (i = 0 orelse isSpace (get (i-1))) andalso i < n andalso not (isSpace (get i))
      fun isEnd i =
        (i = n orelse isSpace (get i)) andalso
        i <> 0 andalso not (isSpace (get (i-1)))

      val (offsets, numStarts) =
        Seq.scan op+ 0
        (Seq.tabulate (fn i => if isStart i then 1 else 0) (n+1))

      val (prevStarts, _) =
        Seq.scan (fn (a, b) => if b = 0 then a else b) 0
        (Seq.tabulate (fn i => if isStart i then i else 0) (n+1))

      val result = ForkJoin.alloc numStarts
    in
      Seq.applyIdx (Seq.zip (offsets, prevStarts)) (fn (j, (numStarts, i)) =>
        if isEnd j then
          (* ( print ("found token " ^ Int.toString (numStarts-1) ^ " starting at " ^ Int.toString i ^ ", ending at " ^ Int.toString j ^ "\n"); *)
          Array.update (result, numStarts-1, (i, j))
          (* ) *)
        else
          ());

      ArraySlice.full result
    end

end
