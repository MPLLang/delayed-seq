structure RadSeq =
struct

  open DelayedSeq

  fun flatten (ss: 'a seq seq): 'a seq =
    let
      val numChildren = length ss
      val children: 'a flat array = unravelAndCopy (map forceFlat ss)
      val offsets =
        SeqBasis.scan gran op+ 0 (0, numChildren) (flatLength o A.nth children)
      val total = A.nth offsets numChildren
      fun offset i = A.nth offsets i

      val result = alloc total
      val blockSize = 10000
      val numBlocks = Util.ceilDiv total blockSize
    in
      parfor 1 (0, numBlocks) (fn blockIdx =>
        let
          val lo = blockIdx * blockSize
          val hi = Int.min (lo + blockSize, total)

          val firstOuterIdx = indexSearch (0, numChildren, offset) lo
          val firstInnerIdx = lo - offset firstOuterIdx

          (** i = outer index
            * j = inner index
            * k = output index, ranges from [lo] to [hi]
            *)
          fun loop i j k =
            if k >= hi then () else
            let
              val inner = A.nth children i
              val numAvailableHere = flatLength inner - j
              val numRemainingInBlock = hi - k
              val numHere = Int.min (numAvailableHere, numRemainingInBlock)
            in
              for (0, numHere) (fn z => A.update (result, k+z, flatNth inner (j+z)));
              loop (i+1) 0 (k+numHere)
            end
        in
          loop firstOuterIdx firstInnerIdx lo
        end);

      Flat (Full (AS.full result))
    end

end
