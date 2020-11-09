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

      fun copy ((numStarts1, lastStartIdx1), (numStarts2, lastStartIdx2)) =
        if numStarts2 = 0 then
          (numStarts1, lastStartIdx1)
        else
          (numStarts1 + numStarts2, lastStartIdx2)

      val (offsets, (numStarts, _)) =
        Seq.scan copy (0, 0)
        (Seq.tabulate (fn i => if isStart i then (1, i) else (0, 0)) (n+1))

      (* val _ =
        print ("offsets   " ^ Seq.toString (Int.toString o #1) offsets ^ "\n")
      val _ =
        print ("prevStart " ^ Seq.toString (Int.toString o #2) offsets ^ "\n")

      val _ = print ("numTokens " ^ Int.toString numStarts ^ "\n") *)

      val result = ForkJoin.alloc numStarts
    in
      Seq.applyIdx offsets (fn (j, (numStarts, i)) =>
        if isEnd j then
          (* ( print ("found token " ^ Int.toString (numStarts-1) ^ " starting at " ^ Int.toString i ^ ", ending at " ^ Int.toString j ^ "\n"); *)
          Array.update (result, numStarts-1, (i, j))
          (* ) *)
        else
          ());

      ArraySlice.full result
    end

end
